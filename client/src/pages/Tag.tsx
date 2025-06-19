import { useParams, Link } from 'react-router-dom'
import { useBlipsByTag } from '../hooks/useBlips'
import { BlipList } from '../components/BlipList'

export function Tag() {
  const { tag } = useParams<{ tag: string }>()
  const { data: blips, isLoading, error } = useBlipsByTag(tag || '')

  if (isLoading) {
    return <div className="loading">Scanning radar for tag...</div>
  }

  if (error) {
    return <div className="error">Failed to connect to radar</div>
  }

  return (
    <>
      <h2 className="page-title">
        blips tagged: {tag}
        <Link to="/" className="back-link">← all blips</Link>
      </h2>
      <BlipList blips={blips || []} />
    </>
  )
}