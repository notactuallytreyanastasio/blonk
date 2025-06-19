"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.BlipList = BlipList;
const react_router_dom_1 = require("react-router-dom");
const date_1 = require("../utils/date");
function BlipList({ blips }) {
    if (blips.length === 0) {
        return (<div className="empty-state">
        <p>No blips detected on the radar yet.</p>
        <p>
          <react_router_dom_1.Link to="/submit">Transmit the first blip</react_router_dom_1.Link>
        </p>
      </div>);
    }
    return (<div className="blip-list">
      {blips.map((blip) => (<div key={blip.uri} className="blip-item">
          <div className="blip-fluffs">{blip.fluffs}</div>
          <div className="blip-content">
            {blip.url ? (<a href={blip.url} className="blip-title" target="_blank" rel="noopener noreferrer">
                {blip.title}
              </a>) : (<span className="blip-title">{blip.title}</span>)}

            {blip.body && (<div className="blip-body">
                {blip.body.length > 200
                    ? `${blip.body.substring(0, 200)}...`
                    : blip.body}
              </div>)}

            <div className="blip-meta">
              <span>
                {blip.authorHandle ? `@${blip.authorHandle}` : 'anonymous'} · {(0, date_1.formatDistance)(blip.createdAt)}
              </span>
              {blip.vibeName && (<span className="blip-vibe">
                  · <react_router_dom_1.Link to={`/vibe/${encodeURIComponent(blip.vibeUri)}`} className="vibe-link">
                    {blip.vibeName}
                  </react_router_dom_1.Link>
                </span>)}
              {blip.tags && blip.tags.length > 0 && (<span className="blip-tags">
                  {blip.tags.map((tag) => (<react_router_dom_1.Link key={tag} to={`/tag/${tag}`} className="tag">
                      {tag}
                    </react_router_dom_1.Link>))}
                </span>)}
            </div>
          </div>
        </div>))}
    </div>);
}
