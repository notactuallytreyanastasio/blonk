import { BskyAgent } from '@atproto/api';
import { FixedFirehoseMonitor } from './firehose-fixed';

async function main() {
  console.log('🚀 Starting Fixed Firehose Test...');
  
  const agent = new BskyAgent({
    service: 'https://bsky.social'
  });

  const monitor = new FixedFirehoseMonitor(agent);
  
  // Handle graceful shutdown
  process.on('SIGINT', () => {
    console.log('\n⏹️  Shutting down...');
    monitor.stop();
    process.exit(0);
  });

  process.on('SIGTERM', () => {
    console.log('\n⏹️  Shutting down...');
    monitor.stop();
    process.exit(0);
  });

  await monitor.start();
}

main().catch((error) => {
  console.error('Fatal error:', error);
  process.exit(1);
});