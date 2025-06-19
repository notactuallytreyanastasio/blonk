import { Routes, Route, Link } from 'react-router-dom'
import { Home } from './pages/Home'
import { Submit } from './pages/Submit'
import { Tag } from './pages/Tag'
import { Vibes } from './pages/Vibes'
import { Vibe } from './pages/Vibe'
import { Emerging } from './pages/Emerging'

function App() {
  return (
    <div className="app">
      <header>
        <div className="container">
          <h1>
            <Link to="/">
              <span className="radar-icon">📡</span>blonk
            </Link>
          </h1>
          <nav>
            <Link to="/">radar</Link>
            <Link to="/vibes">vibes</Link>
            <Link to="/emerging">emerging</Link>
            <Link to="/submit">transmit</Link>
          </nav>
        </div>
      </header>

      <div className="container">
        <Routes>
          <Route path="/" element={<Home />} />
          <Route path="/submit" element={<Submit />} />
          <Route path="/tag/:tag" element={<Tag />} />
          <Route path="/vibes" element={<Vibes />} />
          <Route path="/vibe/:vibeUri" element={<Vibe />} />
          <Route path="/emerging" element={<Emerging />} />
        </Routes>
      </div>
    </div>
  )
}

export default App
