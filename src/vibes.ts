import { BskyAgent } from '@atproto/api';
import { BlonkVibe, BlonkVibeMember, VIBE_NSID, VIBE_MEMBER_NSID } from './schemas';
import { isValidVibeName, normalizeVibeName } from './utils/vibe-validation';
import { vibeMentionDb } from './database';

export class VibeManager {
  constructor(private agent: BskyAgent) {}

  async createVibe(name: string, mood: string, emoji?: string, color?: string): Promise<string> {
    // Validate vibe name
    if (!isValidVibeName(name)) {
      throw new Error('Invalid vibe name. Must be alphanumeric with underscores only, no spaces.');
    }

    // Normalize the name
    const normalizedName = normalizeVibeName(name);

    // Check for duplicates
    const existingVibe = vibeMentionDb.getVibeByName(normalizedName);
    if (existingVibe) {
      throw new Error(`Vibe "${normalizedName}" already exists`);
    }

    const vibe: BlonkVibe = {
      name: normalizedName,
      mood,
      emoji,
      color,
      createdAt: new Date().toISOString(),
      memberCount: 1, // Creator is automatically a member
    };

    const response = await this.agent.com.atproto.repo.createRecord({
      repo: this.agent.session?.did!,
      collection: VIBE_NSID,
      record: vibe,
    });

    // Automatically join the vibe you created
    await this.joinVibe(response.data.uri, response.data.cid);

    console.log(`Created vibe: ${name} - ${mood}`);
    return response.data.uri;
  }

  async joinVibe(vibeUri: string, vibeCid: string): Promise<void> {
    const membership: BlonkVibeMember = {
      vibe: {
        uri: vibeUri,
        cid: vibeCid,
      },
      createdAt: new Date().toISOString(),
    };

    await this.agent.com.atproto.repo.createRecord({
      repo: this.agent.session?.did!,
      collection: VIBE_MEMBER_NSID,
      record: membership,
    });
  }

  async getVibes(limit: number = 50) {
    const response = await this.agent.com.atproto.repo.listRecords({
      repo: this.agent.session?.did!,
      collection: VIBE_NSID,
      limit,
    });

    return response.data.records.map(record => ({
      uri: record.uri,
      cid: record.cid,
      ...record.value as BlonkVibe,
    }));
  }

  async getMyVibes() {
    const response = await this.agent.com.atproto.repo.listRecords({
      repo: this.agent.session?.did!,
      collection: VIBE_MEMBER_NSID,
      limit: 100,
    });

    return response.data.records.map(record => ({
      uri: record.uri,
      membership: record.value as BlonkVibeMember,
    }));
  }

  async getVibe(uri: string) {
    const [repo, collection, rkey] = uri.replace('at://', '').split('/');
    
    const response = await this.agent.com.atproto.repo.getRecord({
      repo,
      collection,
      rkey,
    });

    return {
      uri,
      cid: response.data.cid,
      ...response.data.value as BlonkVibe,
    };
  }
}