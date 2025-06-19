import { Firehose } from '@skyware/firehose';
import { WebSocket } from 'ws';
import { VibeMonitor } from './vibe-monitor';
import { BskyAgent } from '@atproto/api';

export class SkywareFirehoseMonitor {
  private firehose: Firehose;
  private vibeMonitor: VibeMonitor;
  private messageCount = 0;
  private vibeDetectionCount = 0;
  private errorCount = 0;
  private statsInterval: NodeJS.Timeout | null = null;

  constructor(agent: BskyAgent) {
    this.vibeMonitor = new VibeMonitor(agent);
    this.firehose = new Firehose({
      ws: WebSocket as any,
      relay: 'wss://bsky.network'
    });
  }

  async start() {
    console.log('🔥 Starting Skyware Firehose monitoring for #vibe-* hashtags...');
    
    // Set up event handlers
    this.firehose.on('open', () => {
      console.log('📡 Connected to Bluesky Firehose - monitoring all posts for #vibe-*');
      this.messageCount = 0;
      this.vibeDetectionCount = 0;
      this.errorCount = 0;
      
      // Log stats every 30 seconds
      this.statsInterval = setInterval(() => {
        console.log(`📊 Firehose stats: ${this.messageCount} messages, ${this.vibeDetectionCount} #vibe-* detections, ${this.errorCount} errors`);
      }, 30000);
    });

    this.firehose.on('commit', async (commit: any) => {
      this.messageCount++;
      
      try {
        // Process operations in the commit
        for (const op of commit.ops || []) {
          // We only care about post creates
          if (op.action === 'create' && op.path.includes('app.bsky.feed.post')) {
            const record = op.record;
            
            // Check for #vibe- hashtags
            if (record?.text && typeof record.text === 'string' && record.text.toLowerCase().includes('#vibe-')) {
              this.vibeDetectionCount++;
              const authorDid = commit.repo;
              
              console.log(`\n🎯 Detected #vibe-* in Bluesky post!`);
              console.log(`   Author DID: ${authorDid}`);
              console.log(`   Text: "${record.text.substring(0, 100)}${record.text.length > 100 ? '...' : ''}"`);
              console.log(`   Path: ${op.path}`);
              
              // Process the vibe mention
              const postUri = `at://${authorDid}/${op.path}`;
              await this.vibeMonitor.checkPost(record.text, authorDid, postUri);
            }
          }
        }
      } catch (error) {
        // Only log every 100th error to avoid spam
        if (this.errorCount % 100 === 0) {
          console.error('Error processing commit:', error);
        }
        this.errorCount++;
      }
    });

    this.firehose.on('error', ({ error }) => {
      // Only log every 100th error to avoid spam
      if (this.errorCount % 100 === 0) {
        console.error('Firehose error:', error);
      }
      this.errorCount++;
    });

    this.firehose.on('websocketError', ({ error }) => {
      console.error('❌ WebSocket error:', error);
    });

    this.firehose.on('close', (cursor) => {
      console.log(`🔌 Firehose disconnected at cursor: ${cursor}`);
      console.log('   The firehose will auto-reconnect...');
      
      if (this.statsInterval) {
        clearInterval(this.statsInterval);
        this.statsInterval = null;
      }
    });

    // Start the firehose
    this.firehose.start();
  }

  stop() {
    if (this.statsInterval) {
      clearInterval(this.statsInterval);
      this.statsInterval = null;
    }
    this.firehose.close();
  }
}