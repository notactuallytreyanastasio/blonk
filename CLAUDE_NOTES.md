# Claude Development Notes - Blonk

## Session 1: Initial Setup & Renaming Posts to Blips

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