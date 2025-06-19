import { WebSocket } from 'ws';
import { blipDb, vibeDb } from './database';
import { BLIP_NSID, VIBE_NSID } from './schemas';
import { BskyAgent } from '@atproto/api';
import { VibeMonitor } from './vibe-monitor';

export class FirehoseSubscriber {
  private ws: WebSocket | null = null;
  private agent: BskyAgent;

  constructor(agent: BskyAgent) {
    this.agent = agent;
  }

  async start() {
    console.log('🔥 Starting Firehose subscription...');
    
    // Connect to the AT Protocol firehose
    this.ws = new WebSocket('wss://bsky.social/xrpc/com.atproto.sync.subscribeRepos');

    this.ws.on('open', () => {
      console.log('📡 Connected to Firehose');
    });

    this.ws.on('message', async (data: Buffer) => {
      try {
        // The firehose sends CAR files, but for now we'll use a simpler approach
        // In production, you'd parse the CAR files properly
        // For now, let's poll known users instead
      } catch (error) {
        console.error('Error processing firehose message:', error);
      }
    });

    this.ws.on('error', (error) => {
      console.error('Firehose error:', error);
    });

    this.ws.on('close', () => {
      console.log('Firehose connection closed, reconnecting...');
      setTimeout(() => this.start(), 5000);
    });
  }

  stop() {
    if (this.ws) {
      this.ws.close();
      this.ws = null;
    }
  }
}

// Simpler approach for now: poll known users
export class BlipAggregator {
  private agent: BskyAgent;
  private knownUsers: Set<string> = new Set();
  private vibeMonitor: VibeMonitor;

  constructor(agent: BskyAgent) {
    this.agent = agent;
    this.vibeMonitor = new VibeMonitor(agent);
    // Add your own DID to start
    if (agent.session?.did) {
      this.knownUsers.add(agent.session.did);
    }
  }

  async aggregateBlips() {
    console.log('🔍 Aggregating blips and vibes from known users...');
    
    for (const did of this.knownUsers) {
      try {
        // Get user profile
        const profile = await this.agent.getProfile({ actor: did });
        
        // List their vibes
        const vibeResponse = await this.agent.com.atproto.repo.listRecords({
          repo: did,
          collection: VIBE_NSID,
          limit: 100,
        });

        for (const record of vibeResponse.data.records) {
          const vibe = record.value as any;
          
          vibeDb.insertVibe({
            uri: record.uri,
            cid: record.cid,
            creatorDid: did,
            name: vibe.name,
            mood: vibe.mood,
            emoji: vibe.emoji,
            color: vibe.color,
            memberCount: vibe.memberCount || 0,
            createdAt: vibe.createdAt,
          });
        }

        console.log(`✅ Indexed ${vibeResponse.data.records.length} vibes from @${profile.data.handle}`);
        
        // List their blips
        const response = await this.agent.com.atproto.repo.listRecords({
          repo: did,
          collection: BLIP_NSID,
          limit: 100,
        });

        for (const record of response.data.records) {
          const blip = record.value as any;
          
          // Check for vibe hashtags in blip content
          const textToCheck = `${blip.title || ''} ${blip.body || ''}`;
          await this.vibeMonitor.checkPost(textToCheck, did, record.uri);
          
          blipDb.insertBlip({
            uri: record.uri,
            cid: record.cid,
            authorDid: did,
            authorHandle: profile.data.handle,
            authorDisplayName: profile.data.displayName,
            title: blip.title,
            body: blip.body,
            url: blip.url,
            tags: blip.tags || [],
            vibeUri: blip.vibe?.uri,
            vibeName: blip.vibe?.name,
            grooves: blip.grooves || 0,
            createdAt: blip.createdAt,
          });
        }

        console.log(`✅ Indexed ${response.data.records.length} blips from @${profile.data.handle}`);
      } catch (error) {
        console.error(`Failed to aggregate blips from ${did}:`, error);
      }
    }
  }

  addUser(did: string) {
    this.knownUsers.add(did);
  }

  async startPolling(intervalMs = 60000) {
    // Initial aggregation
    await this.aggregateBlips();
    
    // Poll periodically
    setInterval(() => {
      this.aggregateBlips();
    }, intervalMs);
  }
}