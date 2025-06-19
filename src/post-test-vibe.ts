import { BskyAgent } from '@atproto/api';
import { BlonkAgent } from './agent';

async function postTestVibe() {
  const agent = new BlonkAgent();
  await agent.login();
  
  const bskyAgent = agent.getAgent();
  
  const testVibeName = `blonk_test_${Date.now()}`;
  
  console.log(`Posting test vibe: #vibe-${testVibeName}`);
  
  const result = await bskyAgent.post({
    text: `Testing Blonk vibe detection! #vibe-${testVibeName}`,
    createdAt: new Date().toISOString(),
  });

  console.log('Posted:', result.uri);
  console.log(`Now search for: #vibe-${testVibeName}`);
}

postTestVibe().catch(console.error);