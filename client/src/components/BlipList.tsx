import { Link } from 'react-router-dom'
import type { Blip } from '../api/blips'
import { formatDistance } from '../utils/date'

interface BlipListProps {
  blips: Blip[]
}

export function BlipList({ blips }: BlipListProps) {
  if (blips.length === 0) {
    return (
      <div className="empty-state">
        <p>No blips detected on the radar yet.</p>
        <p>
          <Link to="/submit">Transmit the first blip</Link>
        </p>
      </div>
    )
  }

  return (
    <div className="blip-list">
      {blips.map((blip) => (
        <div key={blip.uri} className="blip-item">
          <div className="blip-grooves">{blip.grooves}</div>
          <div className="blip-content">
            {blip.url ? (
              <a
                href={blip.url}
                className="blip-title"
                target="_blank"
                rel="noopener noreferrer"
              >
                {blip.title}
              </a>
            ) : (
              <span className="blip-title">{blip.title}</span>
            )}

            {blip.body && (
              <div className="blip-body">
                {blip.body.length > 200
                  ? `${blip.body.substring(0, 200)}...`
                  : blip.body}
              </div>
            )}

            <div className="blip-meta">
              <span>
                {blip.authorHandle ? `@${blip.authorHandle}` : 'anonymous'} · {formatDistance(blip.createdAt)}
              </span>
              {blip.vibeName && (
                <span className="blip-vibe">
                  · <Link to={`/vibe/${encodeURIComponent(blip.vibeUri!)}`} className="vibe-link">
                    {blip.vibeName}
                  </Link>
                </span>
              )}
              {blip.tags && blip.tags.length > 0 && (
                <span className="blip-tags">
                  {blip.tags.map((tag) => (
                    <Link key={tag} to={`/tag/${tag}`} className="tag">
                      {tag}
                    </Link>
                  ))}
                </span>
              )}
            </div>
          </div>
        </div>
      ))}
    </div>
  )
}