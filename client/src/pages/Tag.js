"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.Tag = Tag;
const react_router_dom_1 = require("react-router-dom");
const useBlips_1 = require("../hooks/useBlips");
const BlipList_1 = require("../components/BlipList");
function Tag() {
    const { tag } = (0, react_router_dom_1.useParams)();
    const { data: blips, isLoading, error } = (0, useBlips_1.useBlipsByTag)(tag || '');
    if (isLoading) {
        return <div className="loading">Scanning radar for tag...</div>;
    }
    if (error) {
        return <div className="error">Failed to connect to radar</div>;
    }
    return (<>
      <h2 className="page-title">
        blips tagged: {tag}
        <react_router_dom_1.Link to="/" className="back-link">← all blips</react_router_dom_1.Link>
      </h2>
      <BlipList_1.BlipList blips={blips || []}/>
    </>);
}
