import express from 'express';
import cors from 'cors';
import { BlonkAgent } from './agent';
import { BlipManager } from './blips';
import { VibeManager } from './vibes';
import { BlipAggregator } from './firehose';
import { SearchMonitor } from './search-monitor';
import { blipDb, vibeDb, vibeMentionDb } from './database';
import * as dotenv from 'dotenv';

dotenv.config();

const app = express();
const PORT = process.env.PORT || 3001;

app.use(cors());
app.use(express.json());

let agent: BlonkAgent;
let blipManager: BlipManager;
let vibeManager: VibeManager;
let aggregator: BlipAggregator;
let searchMonitor: SearchMonitor;

async function initializeAgent() {
  agent = new BlonkAgent();
  await agent.login();
  blipManager = new BlipManager(agent.getAgent());
  vibeManager = new VibeManager(agent.getAgent());
  
  // Start aggregating blips from all users
  aggregator = new BlipAggregator(agent.getAgent());
  aggregator.startPolling(30000); // Poll every 30 seconds
  
  // Start searching for #vibe-* hashtags on Bluesky
  searchMonitor = new SearchMonitor(agent.getAgent());
  await searchMonitor.start();
  
  console.log('✅ Connected to AT Protocol');
  console.log('📡 Starting blip aggregation...');
  console.log('🔍 Searching Bluesky for #vibe-* hashtags every 2 minutes...');
}

app.get('/api/blips', async (req, res) => {
  try {
    // Get aggregated blips from all users
    const blips = blipDb.getBlips(50);
    res.json({ blips });
  } catch (error) {
    console.error('Error fetching blips:', error);
    res.status(500).json({ error: 'Failed to fetch blips' });
  }
});


app.post('/api/blips', async (req, res) => {
  try {
    const { title, url, body, tags, vibe } = req.body;
    const tagArray = tags || [];
    
    const uri = await blipManager.createBlip(title, body, url, tagArray, vibe);
    res.json({ success: true, uri });
  } catch (error) {
    console.error('Error creating blip:', error);
    res.status(500).json({ error: 'Failed to create blip' });
  }
});

// Get all vibes
app.get('/api/vibes', async (req, res) => {
  try {
    const vibes = vibeDb.getVibes(50);
    res.json({ vibes });
  } catch (error) {
    console.error('Error fetching vibes:', error);
    res.status(500).json({ error: 'Failed to fetch vibes' });
  }
});

// Get emerging vibes
app.get('/api/vibes/emerging', async (req, res) => {
  try {
    const emergingVibes = vibeMentionDb.getEmergingVibes();
    res.json({ emergingVibes });
  } catch (error) {
    console.error('Error fetching emerging vibes:', error);
    res.status(500).json({ error: 'Failed to fetch emerging vibes' });
  }
});

// Get blips for a specific vibe
app.get('/api/vibes/:vibeUri/blips', async (req, res) => {
  try {
    const blips = blipDb.getBlipsByVibe(req.params.vibeUri);
    res.json({ blips });
  } catch (error) {
    console.error('Error fetching vibe blips:', error);
    res.status(500).json({ error: 'Failed to fetch vibe blips' });
  }
});

// Vibe creation is now disabled - vibes are created through viral hashtags
app.post('/api/vibes', async (req, res) => {
  res.status(403).json({ 
    error: 'Manual vibe creation is disabled. Vibes are created when #vibe-YOUR_VIBE reaches 5 unique mentions.' 
  });
});

// Join a vibe
app.post('/api/vibes/:vibeUri/join', async (req, res) => {
  try {
    const { cid } = req.body;
    await vibeManager.joinVibe(req.params.vibeUri, cid);
    vibeDb.addMember(req.params.vibeUri, agent.getAgent().session?.did!);
    res.json({ success: true });
  } catch (error) {
    console.error('Error joining vibe:', error);
    res.status(500).json({ error: 'Failed to join vibe' });
  }
});

// Manual search trigger
app.post('/api/vibes/search', async (req, res) => {
  try {
    console.log('Manual vibe search triggered...');
    await searchMonitor.searchForVibeMentions();
    res.json({ success: true, message: 'Search completed' });
  } catch (error) {
    console.error('Error searching for vibes:', error);
    res.status(500).json({ error: 'Failed to search for vibes' });
  }
});

app.get('/api/blips/tag/:tag', async (req, res) => {
  try {
    const taggedBlips = blipDb.getBlipsByTag(req.params.tag);
    res.json({ blips: taggedBlips, tag: req.params.tag });
  } catch (error) {
    console.error('Error fetching tagged blips:', error);
    res.status(500).json({ error: 'Failed to fetch tagged blips' });
  }
});

// Add endpoint to follow new users
app.post('/api/follow', async (req, res) => {
  try {
    const { did } = req.body;
    if (!did) {
      return res.status(400).json({ error: 'DID required' });
    }
    
    aggregator.addUser(did);
    res.json({ success: true, message: `Now following ${did}` });
  } catch (error) {
    console.error('Error following user:', error);
    res.status(500).json({ error: 'Failed to follow user' });
  }
});

initializeAgent().then(() => {
  app.listen(PORT, () => {
    console.log(`🚀 Blonk API server running at http://localhost:${PORT}`);
  });
}).catch(error => {
  console.error('Failed to initialize:', error);
  process.exit(1);
});