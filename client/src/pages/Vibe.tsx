import { useParams, Link } from 'react-router-dom'
import { useVibeBlips } from '../hooks/useVibes'
import { BlipList } from '../components/BlipList'

export function Vibe() {
  const { vibeUri } = useParams<{ vibeUri: string }>()
  const decodedUri = decodeURIComponent(vibeUri || '')
  const { data: blips, isLoading, error } = useVibeBlips(decodedUri)

  if (isLoading) {
    return <div className="loading">Tuning into vibe frequency...</div>
  }

  if (error) {
    return <div className="error">Failed to connect to vibe</div>
  }

  // Get vibe name from the first blip (hacky but works for now)
  const vibeName = blips?.[0]?.vibeName || 'unknown vibe'

  return (
    <>
      <h2 className="page-title">
        vibe: {vibeName}
        <Link to="/vibes" className="back-link">← all vibes</Link>
      </h2>
      <BlipList blips={blips || []} />
    </>
  )
}