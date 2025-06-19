import { useBlips } from '../hooks/useBlips'
import { BlipList } from '../components/BlipList'

export function Home() {
  const { data: blips, isLoading, error } = useBlips()

  if (isLoading) {
    return <div className="loading">Scanning radar...</div>
  }

  if (error) {
    return <div className="error">Failed to connect to radar</div>
  }

  return (
    <>
      <h2 className="page-title">recent blips on the radar</h2>
      <BlipList blips={blips || []} />
    </>
  )
}