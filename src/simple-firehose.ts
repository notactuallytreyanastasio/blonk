import { WebSocket } from 'ws';
import { decode } from 'cbor-x';
import { VibeMonitor } from './vibe-monitor';
import { BskyAgent } from '@atproto/api';

export class SimpleFirehoseMonitor {
  private ws: WebSocket | null = null;
  private vibeMonitor: VibeMonitor;
  private reconnectTimeout: NodeJS.Timeout | null = null;
  private messageCount = 0;
  private vibeDetectionCount = 0;

  constructor(agent: BskyAgent) {
    this.vibeMonitor = new VibeMonitor(agent);
  }

  async start() {
    console.log('🔥 Starting simple Bluesky Firehose monitoring for #vibe-* hashtags...');
    
    // Connect to Bluesky firehose - use the working network endpoint
    const firehoseUrl = 'wss://bsky.network/xrpc/com.atproto.sync.subscribeRepos';
    console.log(`🔗 Connecting to: ${firehoseUrl}`);
    
    this.ws = new WebSocket(firehoseUrl);

    this.ws.on('open', () => {
      console.log('📡 Connected to Bluesky Firehose - monitoring all posts for #vibe-*');
      this.messageCount = 0;
      this.vibeDetectionCount = 0;
      
      // Log stats every 30 seconds
      setInterval(() => {
        console.log(`📊 Firehose stats: ${this.messageCount} messages processed, ${this.vibeDetectionCount} #vibe-* detections`);
      }, 30000);
    });

    this.ws.on('message', async (data: Buffer) => {
      this.messageCount++;
      
      try {
        // Decode the CBOR message
        const decoded = decode(new Uint8Array(data));
        
        if (decoded && decoded.$type === 'com.atproto.sync.subscribeRepos#commit') {
          // Process commits
          const commit = decoded.commit;
          if (!commit) return;

          // Look for post creates
          for (const op of decoded.ops || []) {
            if (op.action === 'create' && op.path?.includes('app.bsky.feed.post')) {
              try {
                // Try to decode the blocks
                const blocks = decoded.blocks;
                if (!blocks) continue;

                // blocks might be a Uint8Array that needs to be decoded
                let record;
                if (blocks instanceof Uint8Array) {
                  // If blocks is raw bytes, decode it
                  const blocksDecoded = decode(blocks);
                  record = blocksDecoded;
                } else if (typeof blocks.get === 'function') {
                  // If blocks is a Map
                  const recordBytes = blocks.get(op.cid);
                  if (!recordBytes) continue;
                  record = decode(recordBytes);
                } else if (Array.isArray(blocks)) {
                  // If blocks is an array, find the matching CID
                  const block = blocks.find(b => b.cid === op.cid);
                  if (!block) continue;
                  record = decode(block.bytes);
                } else {
                  // Try direct decoding
                  record = blocks;
                }
                
                if (record && record.text && typeof record.text === 'string') {
                  // Check for #vibe- hashtags
                  if (record.text.toLowerCase().includes('#vibe-')) {
                    this.vibeDetectionCount++;
                    const authorDid = decoded.repo;
                    console.log(`\n🎯 Detected #vibe-* in Bluesky post!`);
                    console.log(`   Author: ${authorDid}`);
                    console.log(`   Text: "${record.text.substring(0, 100)}${record.text.length > 100 ? '...' : ''}"`);
                    
                    // Process the vibe mention
                    await this.vibeMonitor.checkPost(record.text, authorDid, `at://${authorDid}/${op.path}`);
                  }
                }
              } catch (e) {
                // Ignore individual record errors
              }
            }
          }
        }
      } catch (error) {
        // Ignore decoding errors - firehose sends various message types
      }
    });

    this.ws.on('error', (error: any) => {
      console.error('❌ Firehose WebSocket error:', error.message);
      if (error.code) {
        console.error('   Error code:', error.code);
      }
      if (error.stack) {
        console.error('   Stack trace:', error.stack.split('\n').slice(0, 3).join('\n'));
      }
    });

    this.ws.on('close', (code, reason) => {
      console.log(`🔌 Firehose disconnected: Code ${code}${reason ? `, Reason: ${reason}` : ''}`);
      console.log('   Reconnecting in 5 seconds...');
      this.reconnectTimeout = setTimeout(() => this.start(), 5000);
    });
  }

  stop() {
    if (this.reconnectTimeout) {
      clearTimeout(this.reconnectTimeout);
      this.reconnectTimeout = null;
    }
    if (this.ws) {
      this.ws.close();
      this.ws = null;
    }
  }
}