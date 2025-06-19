import { BlonkAgent } from './agent';
import { BlipManager } from './blips';

async function main() {
  try {
    const blonkAgent = new BlonkAgent();
    await blonkAgent.login();
    
    const agent = blonkAgent.getAgent();
    const blipManager = new BlipManager(agent);

    console.log('\n📡 Blonk - Vibe Radar');
    console.log('=====================\n');

    console.log('Transmitting a test blip...');
    const blipUri = await blipManager.createBlip(
      'Welcome to the Blonk Vibe Radar!',
      'This is the first blip on Blonk, where vibes are tracked on the radar.',
      'https://atproto.com'
    );
    console.log(`Blip transmitted with URI: ${blipUri}\n`);

    console.log('Scanning radar for recent blips...');
    const blips = await blipManager.getBlips(10);
    
    console.log(`\n📡 ${blips.length} blips on the radar:`);
    blips.forEach((blip, index) => {
      console.log(`\n${index + 1}. ${blip.title}`);
      if (blip.body) console.log(`   ${blip.body.substring(0, 100)}...`);
      if (blip.url) console.log(`   🔗 ${blip.url}`);
      console.log(`   📅 ${new Date(blip.createdAt).toLocaleString()}`);
      console.log(`   ✨ ${blip.fluffs} fluffs`);
    });

  } catch (error) {
    console.error('Error:', error);
    process.exit(1);
  }
}

main();