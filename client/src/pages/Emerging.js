"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.Emerging = Emerging;
const react_router_dom_1 = require("react-router-dom");
const useVibes_1 = require("../hooks/useVibes");
const date_1 = require("../utils/date");
function Emerging() {
    const { data: emergingVibes, isLoading, error } = (0, useVibes_1.useEmergingVibes)();
    if (isLoading) {
        return <div className="loading">Scanning for emerging vibes...</div>;
    }
    if (error) {
        return <div className="error">Failed to detect emerging vibes</div>;
    }
    return (<>
      <h2 className="page-title">
        emerging vibes
        <react_router_dom_1.Link to="/vibes" className="back-link">← established vibes</react_router_dom_1.Link>
      </h2>
      
      <div className="emerging-info">
        <p>These vibes are gaining momentum. When 5 unique users mention a vibe, it materializes!</p>
      </div>

      {emergingVibes && emergingVibes.length > 0 ? (<div className="emerging-list">
          {emergingVibes.map(vibe => (<div key={vibe.vibeName} className="emerging-item">
              <div className="emerging-header">
                <h3 className="emerging-name">
                  #vibe-{vibe.vibeName}
                </h3>
                <div className="emerging-meta">
                  {vibe.mentionCount}/5 mentions
                </div>
              </div>
              
              <div className="progress-bar">
                <div className="progress-fill" style={{ width: `${vibe.progress}%` }}/>
              </div>
              
              <div className="emerging-details">
                <span>First detected {(0, date_1.formatDistance)(vibe.firstMentioned)} ago</span>
                {vibe.lastMentioned !== vibe.firstMentioned && (<span> · Last seen {(0, date_1.formatDistance)(vibe.lastMentioned)} ago</span>)}
              </div>
            </div>))}
        </div>) : (<div className="empty-state">
          <p>No emerging vibes detected yet.</p>
          <p>Start using <code>#vibe-something_new</code> in your blips!</p>
        </div>)}
    </>);
}
