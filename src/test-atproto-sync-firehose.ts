import { BskyAgent } from '@atproto/api';
import { AtprotoSyncFirehoseMonitor } from './firehose-with-atproto-sync';

async function main() {
  console.log('🚀 Starting AT Protocol Sync Firehose Test...');
  
  const agent = new BskyAgent({
    service: 'https://bsky.social'
  });

  const monitor = new AtprotoSyncFirehoseMonitor(agent);
  
  // Handle graceful shutdown
  process.on('SIGINT', async () => {
    console.log('\n⏹️  Shutting down...');
    await monitor.stop();
    process.exit(0);
  });

  process.on('SIGTERM', async () => {
    console.log('\n⏹️  Shutting down...');
    await monitor.stop();
    process.exit(0);
  });

  await monitor.start();
}

main().catch((error) => {
  console.error('Fatal error:', error);
  process.exit(1);
});