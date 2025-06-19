import { WebSocket } from 'ws';
import { decode } from 'cbor-x';
import { readCar, cborToLexRecord } from '@atproto/repo';
import { VibeMonitor } from './vibe-monitor';
import { BskyAgent } from '@atproto/api';

export class FixedFirehoseMonitor {
  private ws: WebSocket | null = null;
  private vibeMonitor: VibeMonitor;
  private reconnectTimeout: NodeJS.Timeout | null = null;
  private statsInterval: NodeJS.Timeout | null = null;
  private messageCount = 0;
  private vibeDetectionCount = 0;
  private errorCount = 0;

  constructor(agent: BskyAgent) {
    this.vibeMonitor = new VibeMonitor(agent);
  }

  async start() {
    console.log('🔥 Starting fixed Bluesky Firehose monitoring for #vibe-* hashtags...');
    
    const firehoseUrl = 'wss://bsky.network/xrpc/com.atproto.sync.subscribeRepos';
    console.log(`🔗 Connecting to: ${firehoseUrl}`);
    
    this.ws = new WebSocket(firehoseUrl);

    this.ws.on('open', () => {
      console.log('📡 Connected to Bluesky Firehose - monitoring all posts for #vibe-*');
      this.messageCount = 0;
      this.vibeDetectionCount = 0;
      this.errorCount = 0;
      
      // Log stats every 30 seconds
      this.statsInterval = setInterval(() => {
        console.log(`📊 Firehose stats: ${this.messageCount} messages processed, ${this.vibeDetectionCount} #vibe-* detections, ${this.errorCount} errors`);
      }, 30000);
    });

    this.ws.on('message', async (data: Buffer) => {
      this.messageCount++;
      
      try {
        // AT Protocol uses framed messages
        // First decode the frame header
        const [header, remainder] = this.decodeVarint(data);
        
        // Then decode the actual message
        const messageBytes = data.slice(data.length - remainder);
        const message = decode(messageBytes);
        
        // Handle commit messages
        if (message && message.$type === 'com.atproto.sync.subscribeRepos#commit') {
          await this.handleCommit(message);
        }
      } catch (error) {
        // Only log every 100th error to avoid spam
        if (this.errorCount % 100 === 0) {
          console.error('Error processing message:', error);
        }
        this.errorCount++;
      }
    });

    this.ws.on('error', (error: any) => {
      console.error('❌ Firehose WebSocket error:', error.message);
    });

    this.ws.on('close', (code, reason) => {
      console.log(`🔌 Firehose disconnected: Code ${code}${reason ? `, Reason: ${reason}` : ''}`);
      console.log('   Reconnecting in 5 seconds...');
      
      if (this.statsInterval) {
        clearInterval(this.statsInterval);
        this.statsInterval = null;
      }
      
      this.reconnectTimeout = setTimeout(() => this.start(), 5000);
    });
  }

  private decodeVarint(buf: Buffer): [number, number] {
    let value = 0;
    let shift = 0;
    let byte: number;
    let i = 0;
    
    do {
      byte = buf[i++];
      value |= (byte & 0x7f) << shift;
      shift += 7;
    } while (byte & 0x80);
    
    return [value, buf.length - i];
  }

  private async handleCommit(commit: any) {
    try {
      if (!commit.blocks) return;
      
      // Parse the CAR file from blocks
      const car = await readCar(commit.blocks);
      
      // Process each operation
      for (const op of commit.ops || []) {
        // We only care about post creates
        if (op.action === 'create' && op.path?.includes('app.bsky.feed.post')) {
          try {
            // Get the record bytes from the CAR file
            const recordBytes = car.blocks.get(op.cid);
            if (!recordBytes) continue;
            
            // Convert CBOR to record
            const record = cborToLexRecord(recordBytes);
            
            // Check for #vibe- hashtags
            if (record.text && typeof record.text === 'string' && record.text.toLowerCase().includes('#vibe-')) {
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
          } catch (e) {
            // Record-specific error
            if (this.errorCount % 100 === 0) {
              console.error('Error processing record:', e);
            }
            this.errorCount++;
          }
        }
      }
    } catch (error) {
      // CAR parsing error
      if (this.errorCount % 100 === 0) {
        console.error('Error handling commit:', error);
      }
      this.errorCount++;
    }
  }

  stop() {
    if (this.reconnectTimeout) {
      clearTimeout(this.reconnectTimeout);
      this.reconnectTimeout = null;
    }
    if (this.statsInterval) {
      clearInterval(this.statsInterval);
      this.statsInterval = null;
    }
    if (this.ws) {
      this.ws.close();
      this.ws = null;
    }
  }
}