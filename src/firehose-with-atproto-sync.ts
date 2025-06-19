import { Firehose, getOpsByType } from '@atproto/sync';
import { VibeMonitor } from './vibe-monitor';
import { BskyAgent } from '@atproto/api';

export class ATProtoFirehoseMonitor {
  private firehose: Firehose;
  private vibeMonitor: VibeMonitor;
  private messageCount = 0;
  private vibeDetectionCount = 0;
  private statsInterval: NodeJS.Timeout | null = null;

  constructor(agent: BskyAgent) {
    this.vibeMonitor = new VibeMonitor(agent);
    
    this.firehose = new Firehose({
      filterCollections: ['app.bsky.feed.post'],
      handleEvent: async (evt) => {
        this.messageCount++;
        
        if (evt.event === 'create') {
          const ops = getOpsByType(evt);
          
          for (const op of ops.posts.creates) {
            try {
              const record = op.record;
              
              // Check for #vibe- hashtags
              if (record.text && typeof record.text === 'string' && record.text.toLowerCase().includes('#vibe-')) {
                this.vibeDetectionCount++;
                
                console.log(`\n🎯 Detected #vibe-* in Bluesky post!`);
                console.log(`   Author DID: ${op.author}`);
                console.log(`   Text: "${record.text.substring(0, 100)}${record.text.length > 100 ? '...' : ''}"`);
                console.log(`   URI: ${op.uri}`);
                
                // Process the vibe mention
                await this.vibeMonitor.checkPost(record.text, op.author, op.uri);
              }
            } catch (e) {
              console.error('Error processing post:', e);
            }
          }
        }
      },
      onError: (error) => {
        console.error('Firehose error:', error);
      }
    });
  }

  async start() {
    console.log('🔥 Starting AT Protocol Sync Firehose monitoring for #vibe-* hashtags...');
    
    // Start stats logging
    this.statsInterval = setInterval(() => {
      console.log(`📊 Firehose stats: ${this.messageCount} messages processed, ${this.vibeDetectionCount} #vibe-* detections`);
    }, 30000);
    
    // Start the firehose
    await this.firehose.start();
    console.log('📡 Connected to AT Protocol Firehose - monitoring all posts for #vibe-*');
  }

  stop() {
    if (this.statsInterval) {
      clearInterval(this.statsInterval);
      this.statsInterval = null;
    }
    this.firehose.stop();
  }
}