import { BlonkAgent } from './agent';
import { VibeManager } from './vibes';
import * as dotenv from 'dotenv';

dotenv.config();

const sampleVibes = [
  {
    name: "sunset_sunglasses_struts",
    mood: "confident, golden hour energy, main character walking down the street",
    emoji: "😎",
    color: "#FF6B6B"
  },
  {
    name: "doinkin_right",
    mood: "playful chaos, doing things correctly but in a silly way",
    emoji: "🤪",
    color: "#4ECDC4"
  },
  {
    name: "dork_nerd_linkage", 
    mood: "excitedly sharing obscure knowledge, Wikipedia rabbit holes at 3am",
    emoji: "🤓",
    color: "#95E1D3"
  },
  {
    name: "cozy_corner_contemplation",
    mood: "rainy day thoughts, tea and blankets, gentle introspection",
    emoji: "☕",
    color: "#C7CEEA"
  },
  {
    name: "midnight_snack_attack",
    mood: "impulsive 2am decisions, standing in front of the fridge energy",
    emoji: "🌙",
    color: "#2C3E50"
  },
  {
    name: "sparkle_hustle_flow",
    mood: "getting things done but make it glamorous, productive but cute",
    emoji: "✨",
    color: "#FF6B9D"
  }
];

async function seedVibes() {
  try {
    const blonkAgent = new BlonkAgent();
    await blonkAgent.login();
    
    const agent = blonkAgent.getAgent();
    const vibeManager = new VibeManager(agent);

    console.log('🌈 Creating sample vibes...\n');

    for (const vibe of sampleVibes) {
      try {
        const uri = await vibeManager.createVibe(
          vibe.name,
          vibe.mood,
          vibe.emoji,
          vibe.color
        );
        console.log(`✅ Created vibe: ${vibe.emoji} ${vibe.name}`);
        console.log(`   Mood: ${vibe.mood}`);
        console.log(`   URI: ${uri}\n`);
      } catch (error) {
        console.error(`❌ Failed to create vibe "${vibe.name}":`, error);
      }
    }

    console.log('🎉 Vibe seeding complete!');
    console.log('Run the web server to see and join these vibes.');

  } catch (error) {
    console.error('Error:', error);
    process.exit(1);
  }
}

seedVibes();