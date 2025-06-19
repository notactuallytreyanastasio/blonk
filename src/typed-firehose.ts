import { WebSocket } from 'ws';
import { decode } from 'cbor-x';
import { readCar, cborToLexRecord } from '@atproto/repo';
import { VibeMonitor } from './vibe-monitor';
import { BskyAgent } from '@atproto/api';

// Firehose message types
interface FirehoseCommit {
  $type: 'com.atproto.sync.subscribeRepos#commit';
  seq: number;
  rebase: boolean;
  tooBig: boolean;
  repo: string; // DID of the repo
  commit: string; // CID of the commit
  prev?: string;
  blocks: Uint8Array; // CAR file containing the record blocks
  ops: CommitOperation[];
  time: string;
}

interface CommitOperation {
  action: 'create' | 'update' | 'delete';
  path: string;
  cid: string;
}

interface PostRecord {
  $type?: string;
  text: string;
  createdAt: string;
  langs?: string[];
  reply?: any;
  embed?: any;
  facets?: any[];
  tags?: string[];
  labels?: any;
}

interface FirehoseError {
  $type: 'com.atproto.sync.subscribeRepos#error';
  error: string;
  message?: string;
}

interface FirehoseInfo {
  $type: 'com.atproto.sync.subscribeRepos#info';
  name: string;
  message?: string;
}

type FirehoseMessage = FirehoseCommit | FirehoseError | FirehoseInfo;

export class TypedFirehoseMonitor {
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
    console.log('🔥 Starting typed Bluesky Firehose monitoring for #vibe-* hashtags...');
    
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
        console.log(`📊 Firehose stats: ${this.messageCount} messages, ${this.vibeDetectionCount} #vibe-* detections, ${this.errorCount} errors`);
      }, 30000);
    });

    this.ws.on('message', async (data: Buffer) => {
      this.messageCount++;
      
      try {
        // Decode the CBOR message
        const decoded = decode(new Uint8Array(data)) as FirehoseMessage;
        
        // Handle different message types
        switch (decoded.$type) {
          case 'com.atproto.sync.subscribeRepos#commit':
            await this.handleCommit(decoded);
            break;
          case 'com.atproto.sync.subscribeRepos#error':
            console.error('Firehose error:', decoded.error, decoded.message);
            this.errorCount++;
            break;
          case 'com.atproto.sync.subscribeRepos#info':
            console.log('Firehose info:', decoded.name, decoded.message);
            break;
          default:
            // Unknown message type
            if (this.messageCount % 1000 === 0) {
              console.log(`Unknown message type: ${(decoded as any)?.$type}`);
            }
        }
      } catch (error) {
        // Only log every 100th error to avoid spam
        if (this.errorCount % 100 === 0) {
          console.error('Error processing firehose message:', error);
        }
        this.errorCount++;
      }
    });

    this.ws.on('error', (error: any) => {
      console.error('❌ Firehose WebSocket error:', error.message);
      if (error.code) {
        console.error('   Error code:', error.code);
      }
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

  private async handleCommit(commit: FirehoseCommit) {
    try {
      // Parse the CAR file from blocks
      const car = await readCar(commit.blocks);
      
      // Process each operation
      for (const op of commit.ops) {
        // We only care about post creates
        if (op.action === 'create' && op.path.includes('app.bsky.feed.post')) {
          try {
            // Get the record bytes from the CAR file using the operation's CID
            const recordBytes = car.blocks.get(op.cid);
            if (!recordBytes) continue;
            
            // Convert CBOR to lexicon record
            const record = cborToLexRecord(recordBytes) as PostRecord;
            
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
            // Record-specific error, don't spam logs
            if (this.errorCount % 100 === 0) {
              console.error('Error processing post record:', e);
            }
            this.errorCount++;
          }
        }
      }
    } catch (error) {
      // CAR parsing error
      if (this.errorCount % 100 === 0) {
        console.error('Error parsing CAR file:', error);
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