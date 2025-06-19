import { BskyAgent } from '@atproto/api';
import { VibeMonitor } from './vibe-monitor';

export class SearchMonitor {
  private agent: BskyAgent;
  private vibeMonitor: VibeMonitor;
  private searchInterval: NodeJS.Timer | null = null;

  constructor(agent: BskyAgent) {
    this.agent = agent;
    this.vibeMonitor = new VibeMonitor(agent);
  }

  async start() {
    console.log('🔍 Starting periodic search for #vibe-* mentions...');
    
    // Initial search
    await this.searchForVibeMentions();
    
    // Search every 2 minutes
    this.searchInterval = setInterval(() => {
      this.searchForVibeMentions();
    }, 2 * 60 * 1000);
  }

  async searchForVibeMentions() {
    try {
      console.log('🔎 Searching Bluesky for #vibe-* mentions...');
      
      // Search for posts containing #vibe-
      const searchResponse = await this.agent.app.bsky.feed.searchPosts({
        q: '#vibe-',
        limit: 50,
      });

      let newMentions = 0;
      
      for (const post of searchResponse.data.posts) {
        const text = post.record.text;
        const authorDid = post.author.did;
        
        if (text && text.includes('#vibe-')) {
          console.log(`Found #vibe-* mention by @${post.author.handle}: "${text.substring(0, 100)}..."`);
          await this.vibeMonitor.checkPost(text, authorDid, post.uri);
          newMentions++;
        }
      }
      
      if (newMentions > 0) {
        console.log(`✅ Processed ${newMentions} new #vibe-* mentions`);
      } else {
        console.log('No new #vibe-* mentions found in this search');
      }
    } catch (error) {
      console.error('Error searching for vibe mentions:', error);
    }
  }

  stop() {
    if (this.searchInterval) {
      clearInterval(this.searchInterval);
      this.searchInterval = null;
    }
  }
}