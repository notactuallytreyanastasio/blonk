"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
const react_router_dom_1 = require("react-router-dom");
const Home_1 = require("./pages/Home");
const Submit_1 = require("./pages/Submit");
const Tag_1 = require("./pages/Tag");
const Vibes_1 = require("./pages/Vibes");
const Vibe_1 = require("./pages/Vibe");
const Emerging_1 = require("./pages/Emerging");
function App() {
    return (<div className="app">
      <header>
        <div className="container">
          <h1>
            <react_router_dom_1.Link to="/">
              <span className="radar-icon">📡</span>blonk
            </react_router_dom_1.Link>
          </h1>
          <nav>
            <react_router_dom_1.Link to="/">radar</react_router_dom_1.Link>
            <react_router_dom_1.Link to="/vibes">vibes</react_router_dom_1.Link>
            <react_router_dom_1.Link to="/emerging">emerging</react_router_dom_1.Link>
            <react_router_dom_1.Link to="/submit">transmit</react_router_dom_1.Link>
          </nav>
        </div>
      </header>

      <div className="container">
        <react_router_dom_1.Routes>
          <react_router_dom_1.Route path="/" element={<Home_1.Home />}/>
          <react_router_dom_1.Route path="/submit" element={<Submit_1.Submit />}/>
          <react_router_dom_1.Route path="/tag/:tag" element={<Tag_1.Tag />}/>
          <react_router_dom_1.Route path="/vibes" element={<Vibes_1.Vibes />}/>
          <react_router_dom_1.Route path="/vibe/:vibeUri" element={<Vibe_1.Vibe />}/>
          <react_router_dom_1.Route path="/emerging" element={<Emerging_1.Emerging />}/>
        </react_router_dom_1.Routes>
      </div>
    </div>);
}
exports.default = App;
