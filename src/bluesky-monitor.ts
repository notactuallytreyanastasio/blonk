import { Subscription } from '@atproto/sync';
import { VibeMonitor } from './vibe-monitor';
import { BskyAgent } from '@atproto/api';
import { ids, lexicons } from '@atproto/api';

export class BlueskyFirehoseMonitor {
  private subscription: Subscription | null = null;
  private vibeMonitor: VibeMonitor;

  constructor(agent: BskyAgent) {
    this.vibeMonitor = new VibeMonitor(agent);
  }

  async start() {
    console.log('🔥 Starting Bluesky Firehose monitoring for #vibe-* hashtags...');
    
    this.subscription = new Subscription({
      service: 'wss://bsky.social',
      method: 'com.atproto.sync.subscribeRepos',
      getState: () => ({}),
      validate: (value) => value,
    });

    this.subscription.on('message', (msg: any) => {
      if (msg.commit) {
        this.processCommit(msg.commit);
      }
    });

    this.subscription.on('error', (error) => {
      console.error('Bluesky Firehose error:', error);
    });

    await this.subscription.start();
    console.log('📡 Connected to Bluesky Firehose');
  }

  private async processCommit(commit: any) {
    try {
      // Check each operation in the commit
      for (const op of commit.ops || []) {
        if (op.action === 'create' && op.path?.includes('app.bsky.feed.post')) {
          // This is a new post
          const record = op.record;
          
          if (record && record.text) {
            const text = record.text;
            
            // Check for #vibe-* hashtags
            if (text.includes('#vibe-')) {
              const authorDid = commit.repo;
              console.log(`🎯 Detected #vibe-* in Bluesky post from ${authorDid}: "${text.substring(0, 100)}..."`);
              
              // Process the vibe mention
              await this.vibeMonitor.checkPost(text, authorDid, `at://${authorDid}/${op.path}`);
            }
          }
        }
      }
    } catch (error) {
      // Ignore errors for individual commits
    }
  }

  stop() {
    if (this.subscription) {
      this.subscription.stop();
      this.subscription = null;
    }
  }
}