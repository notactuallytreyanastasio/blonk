import { useState } from 'react'
import { useNavigate } from 'react-router-dom'
import { useCreateBlip } from '../hooks/useBlips'
import { useVibes } from '../hooks/useVibes'

export function Submit() {
  const navigate = useNavigate()
  const createBlip = useCreateBlip()
  const { data: vibes } = useVibes()
  const [formData, setFormData] = useState({
    title: '',
    url: '',
    body: '',
    tags: '',
    vibeUri: '',
  })

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault()
    
    const tagArray = formData.tags
      .split(' ')
      .filter(tag => tag.length > 0)
      .map(tag => tag.toLowerCase())

    const selectedVibe = vibes?.find(v => v.uri === formData.vibeUri)

    try {
      await createBlip.mutateAsync({
        title: formData.title,
        url: formData.url || undefined,
        body: formData.body || undefined,
        tags: tagArray,
        vibe: selectedVibe ? {
          uri: selectedVibe.uri,
          cid: selectedVibe.cid,
          name: selectedVibe.name,
        } : undefined,
      })
      navigate('/')
    } catch (error) {
      console.error('Failed to create blip:', error)
    }
  }

  return (
    <>
      <h2 className="page-title">transmit a new blip</h2>
      
      <form onSubmit={handleSubmit} className="submit-form">
        <div className="form-group">
          <label htmlFor="title">signal</label>
          <input
            type="text"
            id="title"
            name="title"
            required
            placeholder="What's on the radar?"
            value={formData.title}
            onChange={(e) => setFormData({ ...formData, title: e.target.value })}
          />
        </div>

        <div className="form-group">
          <label htmlFor="url">frequency (optional)</label>
          <input
            type="url"
            id="url"
            name="url"
            placeholder="https://..."
            value={formData.url}
            onChange={(e) => setFormData({ ...formData, url: e.target.value })}
          />
          <div className="form-note">link to external content</div>
        </div>

        <div className="form-group">
          <label htmlFor="body">transmission details (optional)</label>
          <textarea
            id="body"
            name="body"
            placeholder="Additional context or thoughts..."
            value={formData.body}
            onChange={(e) => setFormData({ ...formData, body: e.target.value })}
          />
        </div>

        <div className="form-group">
          <label htmlFor="vibe">vibe</label>
          <select
            id="vibe"
            name="vibe"
            value={formData.vibeUri}
            onChange={(e) => setFormData({ ...formData, vibeUri: e.target.value })}
            className="vibe-select"
          >
            <option value="">-- choose a vibe --</option>
            {vibes?.map(vibe => (
              <option key={vibe.uri} value={vibe.uri}>
                {vibe.emoji} {vibe.name} - {vibe.mood}
              </option>
            ))}
          </select>
          <div className="form-note">select the mood for your blip</div>
        </div>

        <div className="form-group">
          <label htmlFor="tags">tags</label>
          <input
            type="text"
            id="tags"
            name="tags"
            placeholder="space separated tags"
            value={formData.tags}
            onChange={(e) => setFormData({ ...formData, tags: e.target.value })}
          />
          <div className="form-note">e.g., programming atproto bluesky</div>
        </div>

        {createBlip.isError && (
          <div className="error-message">Failed to transmit blip</div>
        )}

        <button 
          type="submit" 
          className="submit-button"
          disabled={createBlip.isPending}
        >
          {createBlip.isPending ? 'transmitting...' : 'transmit blip'}
        </button>
      </form>
    </>
  )
}