"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.Vibe = Vibe;
const react_router_dom_1 = require("react-router-dom");
const useVibes_1 = require("../hooks/useVibes");
const BlipList_1 = require("../components/BlipList");
function Vibe() {
    var _a;
    const { vibeUri } = (0, react_router_dom_1.useParams)();
    const decodedUri = decodeURIComponent(vibeUri || '');
    const { data: blips, isLoading, error } = (0, useVibes_1.useVibeBlips)(decodedUri);
    if (isLoading) {
        return <div className="loading">Tuning into vibe frequency...</div>;
    }
    if (error) {
        return <div className="error">Failed to connect to vibe</div>;
    }
    // Get vibe name from the first blip (hacky but works for now)
    const vibeName = ((_a = blips === null || blips === void 0 ? void 0 : blips[0]) === null || _a === void 0 ? void 0 : _a.vibeName) || 'unknown vibe';
    return (<>
      <h2 className="page-title">
        vibe: {vibeName}
        <react_router_dom_1.Link to="/vibes" className="back-link">← all vibes</react_router_dom_1.Link>
      </h2>
      <BlipList_1.BlipList blips={blips || []}/>
    </>);
}
