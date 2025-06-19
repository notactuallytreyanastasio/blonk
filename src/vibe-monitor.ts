import { BskyAgent } from '@atproto/api';
import { VibeManager } from './vibes';
import { vibeMentionDb, vibeDb } from './database';
import { extractVibeFromHashtag, normalizeVibeName } from './utils/vibe-validation';

const VIBE_CREATION_THRESHOLD = 5; // Number of unique users needed to create a vibe

export class VibeMonitor {
  private agent: BskyAgent;
  private vibeManager: VibeManager;

  constructor(agent: BskyAgent) {
    this.agent = agent;
    this.vibeManager = new VibeManager(agent);
  }

  async checkPost(text: string, authorDid: string, postUri?: string) {
    const vibeName = extractVibeFromHashtag(text);
    
    if (!vibeName) return;

    console.log(`📡 Detected vibe mention: #vibe-${vibeName} by ${authorDid}`);

    // Track the mention
    vibeMentionDb.trackMention(vibeName, authorDid, postUri);

    // Check if vibe already exists
    const existingVibe = vibeMentionDb.getVibeByName(vibeName);
    if (existingVibe) {
      console.log(`✅ Vibe "${vibeName}" already exists`);
      return;
    }

    // Check if we've hit the threshold
    const mentionCount = vibeMentionDb.getMentionCount(vibeName);
    console.log(`📊 Vibe "${vibeName}" has ${mentionCount} unique mentions`);

    if (mentionCount >= VIBE_CREATION_THRESHOLD) {
      await this.createVibeFromHashtag(vibeName, mentionCount);
    }
  }

  private async createVibeFromHashtag(vibeName: string, mentionCount: number) {
    try {
      console.log(`🎉 Creating new vibe "${vibeName}" after ${mentionCount} mentions!`);

      // Generate a mood based on the vibe name
      const mood = this.generateMood(vibeName);
      
      // Create the vibe
      const uri = await this.vibeManager.createVibe(
        vibeName,
        mood,
        '🌊', // Default emoji
        '#7B68EE' // Default color (medium purple)
      );

      // Store in local database
      vibeDb.insertVibe({
        uri,
        cid: 'generated', // We'd get this from the creation response
        creatorDid: 'system',
        name: vibeName,
        mood,
        emoji: '🌊',
        color: '#7B68EE',
        memberCount: mentionCount,
        createdAt: new Date().toISOString(),
      });

      console.log(`✨ Vibe "${vibeName}" created successfully!`);
    } catch (error) {
      console.error(`Failed to create vibe "${vibeName}":`, error);
    }
  }

  private generateMood(vibeName: string): string {
    // Generate a mood description based on the vibe name
    const words = vibeName.split('_').filter(w => w.length > 0);
    
    if (words.length === 0) return 'mysterious energy';
    
    // Some fun default moods based on patterns
    if (vibeName.includes('chill')) return 'relaxed and easy-going vibes';
    if (vibeName.includes('chaos')) return 'delightfully unpredictable energy';
    if (vibeName.includes('nerd')) return 'enthusiastically geeky discussions';
    if (vibeName.includes('midnight')) return 'late night contemplative mood';
    if (vibeName.includes('morning')) return 'fresh start energy';
    
    // Default: create a mood from the words
    return `${words.join(' ')} energy, discovered by the community`;
  }
}