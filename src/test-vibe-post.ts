import { BskyAgent } from '@atproto/api';
import * as dotenv from 'dotenv';

dotenv.config();

async function postVibeTest() {
  const agent = new BskyAgent({
    service: 'https://bsky.social'
  });

  await agent.login({
    identifier: process.env.BLUESKY_HANDLE!,
    password: process.env.BLUESKY_PASSWORD!,
  });

  const testVibeName = `test_firehose_${Date.now()}`;
  
  console.log(`Posting test vibe: #vibe-${testVibeName}`);
  
  const result = await agent.post({
    text: `Testing Blonk firehose monitoring! #vibe-${testVibeName}`,
    createdAt: new Date().toISOString(),
  });

  console.log('Posted:', result.uri);
  console.log(`Now monitor the firehose logs to see if it detects: #vibe-${testVibeName}`);
}

postVibeTest().catch(console.error);