"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.Vibes = Vibes;
const react_router_dom_1 = require("react-router-dom");
const useVibes_1 = require("../hooks/useVibes");
function Vibes() {
    const { data: vibes, isLoading, error } = (0, useVibes_1.useVibes)();
    if (isLoading) {
        return <div className="loading">Tuning into vibes...</div>;
    }
    if (error) {
        return <div className="error">Failed to connect to vibe frequencies</div>;
    }
    return (<>
      <h2 className="page-title">
        vibe frequencies
        <react_router_dom_1.Link to="/emerging" className="back-link">→ emerging vibes</react_router_dom_1.Link>
      </h2>
      
      <div className="vibes-grid">
        {vibes === null || vibes === void 0 ? void 0 : vibes.map(vibe => (<react_router_dom_1.Link key={vibe.uri} to={`/vibe/${encodeURIComponent(vibe.uri)}`} className="vibe-card" style={{ borderColor: vibe.color || 'var(--blonk-light-gray)' }}>
            <div className="vibe-emoji">{vibe.emoji || '📡'}</div>
            <div className="vibe-name">{vibe.name}</div>
            <div className="vibe-mood">{vibe.mood}</div>
            <div className="vibe-stats">{vibe.memberCount} members</div>
          </react_router_dom_1.Link>))}
      </div>
      
      {(!vibes || vibes.length === 0) && (<div className="empty-state">
          <p>No vibes discovered yet.</p>
          <p>To create a vibe, use <code>#vibe-YOUR_VIBE</code> in your blips!</p>
          <p className="form-note">When 5 different people use the same vibe hashtag, it becomes real.</p>
        </div>)}
      
      <div className="vibe-info">
        <h3>How vibes are born:</h3>
        <p>Include <code>#vibe-something_cool</code> in your blips. When 5 unique users mention the same vibe, it materializes!</p>
        <p className="form-note">Vibe names must use underscores instead of spaces (e.g., <code>#vibe-late_night_coding</code>)</p>
      </div>
    </>);
}
