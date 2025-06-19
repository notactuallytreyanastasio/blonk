import { WebSocket } from 'ws';

export class DebugFirehose {
  private ws: WebSocket | null = null;

  async start() {
    console.log('🔍 DEBUG: Starting firehose connection test...');
    
    const urls = [
      'wss://bsky.social/xrpc/com.atproto.sync.subscribeRepos',
      'wss://bsky.network/xrpc/com.atproto.sync.subscribeRepos',
    ];

    for (const url of urls) {
      console.log(`\n🔗 Trying: ${url}`);
      await this.testConnection(url);
    }
  }

  private async testConnection(url: string): Promise<void> {
    return new Promise((resolve) => {
      const ws = new WebSocket(url);
      let messageCount = 0;
      const timeout = setTimeout(() => {
        console.log('⏱️ Timeout after 10 seconds');
        ws.close();
        resolve();
      }, 10000);

      ws.on('open', () => {
        console.log('✅ Connected successfully!');
      });

      ws.on('message', (data: Buffer) => {
        messageCount++;
        console.log(`📦 Message #${messageCount}: ${data.length} bytes`);
        
        // Log first few bytes to see message type
        const preview = data.slice(0, 100);
        console.log(`   Preview: ${preview.toString('hex').substring(0, 50)}...`);
        
        if (messageCount >= 5) {
          console.log('✅ Successfully receiving messages');
          clearTimeout(timeout);
          ws.close();
          resolve();
        }
      });

      ws.on('error', (error: any) => {
        console.log(`❌ Error: ${error.message}`);
        console.log(`   Code: ${error.code}`);
        if (error.stack) {
          console.log(`   Stack: ${error.stack.split('\n')[0]}`);
        }
        clearTimeout(timeout);
        resolve();
      });

      ws.on('close', (code, reason) => {
        console.log(`🔌 Closed: Code ${code}${reason ? `, Reason: ${reason}` : ''}`);
        clearTimeout(timeout);
        resolve();
      });
    });
  }

  stop() {
    if (this.ws) {
      this.ws.close();
      this.ws = null;
    }
  }
}

// Run the test
const debugFirehose = new DebugFirehose();
debugFirehose.start();