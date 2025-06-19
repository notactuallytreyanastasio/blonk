"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.Home = Home;
const useBlips_1 = require("../hooks/useBlips");
const BlipList_1 = require("../components/BlipList");
function Home() {
    const { data: blips, isLoading, error } = (0, useBlips_1.useBlips)();
    if (isLoading) {
        return <div className="loading">Scanning radar...</div>;
    }
    if (error) {
        return <div className="error">Failed to connect to radar</div>;
    }
    return (<>
      <h2 className="page-title">recent blips on the radar</h2>
      <BlipList_1.BlipList blips={blips || []}/>
    </>);
}
