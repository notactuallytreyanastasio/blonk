# Claude Development Notes - Blonk

## Session 1: Initial Setup & Renaming Posts to Blips

## Session 2: Web Interface with del.icio.us Aesthetic

## Session 3: Migration to React + Vite

## Session 4: Multi-User Aggregation

### Why This Step
- User wanted to see everyone's blips, not just their own
- AT Protocol is decentralized - data lives in individual repos
- Need an aggregator to collect blips from multiple users

### Implementation Details
- **SQLite Database**: Local storage for aggregated blips
- **Polling System**: Periodically fetches blips from known users
- **User Tracking**: Start with self, can add more users via API
- **Firehose Ready**: Structure supports real firehose integration later

### How It Works
1. BlipAggregator polls known users every 30 seconds
2. Fetches their blips via AT Protocol API
3. Stores in SQLite with author info
4. API serves aggregated data instead of single-user data

### Thoughts So Far
**The Challenge:**
- AT Protocol has no built-in global feed
- The Firehose (com.atproto.sync.subscribeRepos) sends CAR files
- Parsing CAR files is complex for a demo

**Current Solution:**
- Simple polling of known users
- Manual user addition via API
- Works well for small scale

**Future Improvements:**
1. **Proper Firehose**: Parse CAR files to auto-discover all blips
2. **User Discovery**: Find users who have blips automatically
3. **Performance**: Index optimization, caching
4. **Federation**: Allow other Blonk instances to share data

### Why This Step
- User requested React ("let's be adults about it")
- Dan Abramov's approach: modern tooling with Vite, React Query for server state
- Better scalability and developer experience than server-side templates

### Implementation Details
- **Vite**: Lightning-fast dev server, modern build tool
- **React Query**: Handles caching, loading states, background refetching
- **React Router**: Client-side routing for SPA experience
- **TypeScript**: Full type safety across the stack
- Split architecture:
  - API server on port 3001 (Express + AT Protocol)
  - React dev server on port 5173 (Vite)
  - Proxy configuration for seamless API calls

### Thoughts So Far
**Going Well:**
- Clean separation of concerns (API vs UI)
- React Query eliminates boilerplate for data fetching
- del.icio.us aesthetic translates perfectly to React components
- TypeScript catches errors early

**Current Architecture:**
```
AT Protocol → Express API → React Query → React Components
```

**Potential Pitfalls:**
1. **Bundle size**: Need to monitor as we add features
2. **SEO**: SPA won't be crawlable without SSR
3. **Complexity**: More moving parts than simple templates
4. **State management**: May need Redux/Zustand for complex UI state later

**Next Ideas:**
- Add optimistic updates for fluffs
- Implement infinite scroll for blip lists
- Real-time updates with WebSockets
- PWA capabilities for mobile
- Server-side rendering with Next.js if SEO becomes important

### Why This Step
- User wanted a web interface inspired by del.icio.us
- del.icio.us was perfect inspiration: minimalist, content-focused, tag-based
- Fits the "vibe radar" concept with simple signal transmission

### Implementation Details
- Express server with EJS templating
- Minimalist CSS mimicking del.icio.us style:
  - Signature blue (#3366cc) accent color
  - Verdana 11px font for that classic 2000s web feel
  - Clean list-based layout
  - Tag system for categorization
- Routes:
  - `/` - Recent blips list
  - `/submit` - Transmit new blips 
  - `/tag/:tag` - Filter by tag
- Added tags to BlonkBlip schema
- "Transmit" instead of "Submit" for radar theme

### Thoughts So Far
**Going Well:**
- The del.icio.us aesthetic works perfectly with the radar concept
- Tag system adds discoverability without complexity
- Clean separation between AT Protocol layer and web layer

**Potential Pitfalls:**
1. **Multi-user**: Currently only shows blips from the configured account. Need to aggregate from multiple users.
2. **Real-time updates**: No websockets yet, requires page refresh
3. **Fluff interactions**: Can display fluff count but can't vote yet
4. **Performance**: Loading all blips then filtering in memory won't scale

**Ideas for Next Steps:**
- Add fluff (upvote) functionality with AJAX
- User profiles showing their blip history
- Popular/trending radar view based on fluff velocity
- Tag clouds showing popular topics
- RSS feeds for tags
- Bookmarklet for quick blip submission (very del.icio.us!)

### Renaming Complete ✅
Successfully renamed all terminology:
- Posts → Blips
- Votes → Fluffs (updated from Vibes)
- Comments → Comments (reverted from Echoes)
- PostManager → BlipManager
- "Reddit clone" → "Vibe Radar"

The app now has its own unique personality!

### Terminology Refinement
**Why the changes:**
- "Fluffs" better captures the lightweight, fun nature of upvotes
- Keeping "comments" maintains clarity for users
- The terminology is now: Blips get Fluffs and Comments

### Why This Step
- User wants unique terminology: "blips on the blonk vibe radar" 
- This creates a distinct brand identity separate from Reddit/Twitter/Bluesky
- Makes the app feel more original and fun

### Implementation Details
- Renaming all instances of "post" to "blip" across:
  - Schema definitions (POST_NSID → BLIP_NSID)
  - Type interfaces (BlonkPost → BlonkBlip)
  - Class names (PostManager → BlipManager)
  - Function names and variables
  - Comments and console output

### Thoughts So Far
**Going Well:**
- AT Protocol SDK is well-documented and straightforward
- TypeScript provides good type safety for schema definitions
- The decentralized nature means we can experiment without affecting other apps

**Potential Pitfalls:**
1. **Schema Evolution**: Once blips are created with `com.blonk.blip`, changing the schema later will be tricky. Need to plan the data structure carefully.
2. **Feed Algorithm**: Currently just showing blips in order. Will need sophisticated querying for hot/top/new sorting.
3. **Authentication**: Using app passwords is good for testing but a production app would need OAuth.
4. **Data Persistence**: All data lives in user repos - no central database means no global feed without aggregation.
5. **Discoverability**: Custom record types won't be indexed by Bluesky. Need our own indexing service eventually.

**Ideas for Next Steps:**
- Add "vibe" scores instead of simple votes
- Create "radar" feeds that aggregate blips by topic/mood
- Implement "echo" system (like retweets but for blips)
- Build a simple web UI to actually see the blips