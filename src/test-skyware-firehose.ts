const { FirehoseSubscription } = require('@skyware/firehose');

async function testFirehose() {
  console.log('🔥 Testing Skyware Firehose...');
  
  const firehose = new FirehoseSubscription({
    service: 'wss://bsky.network',
    filter: {
      collections: ['app.bsky.feed.post']
    }
  });

  let messageCount = 0;
  let vibeCount = 0;

  firehose.on('commit', (commit: any) => {
    messageCount++;
    
    commit.ops.forEach((op: any) => {
      if (op.action === 'create' && op.record?.text) {
        const text = op.record.text;
        if (text.toLowerCase().includes('#vibe-')) {
          vibeCount++;
          console.log(`\n🎯 FOUND #vibe-* POST!`);
          console.log(`   Author: ${commit.repo}`);
          console.log(`   Text: ${text}`);
          console.log(`   Path: ${op.path}`);
        }
      }
    });
  });

  firehose.on('error', (error: any) => {
    console.error('Firehose error:', error);
  });

  await firehose.start();
  console.log('📡 Connected to Skyware Firehose');

  // Log stats every 10 seconds
  setInterval(() => {
    console.log(`📊 Stats: ${messageCount} messages, ${vibeCount} #vibe-* posts`);
  }, 10000);
}

testFirehose().catch(console.error);