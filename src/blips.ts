import { BskyAgent } from '@atproto/api';
import { BlonkBlip, BLIP_NSID } from './schemas';

export class BlipManager {
  constructor(private agent: BskyAgent) {}

  async createBlip(
    title: string, 
    body?: string, 
    url?: string, 
    tags?: string[],
    vibe?: { uri: string; cid: string; name?: string }
  ): Promise<string> {
    const blip: BlonkBlip = {
      title,
      body,
      url,
      tags,
      vibe,
      createdAt: new Date().toISOString(),
      fluffs: 0,
    };

    const response = await this.agent.com.atproto.repo.createRecord({
      repo: this.agent.session?.did!,
      collection: BLIP_NSID,
      record: blip,
    });

    console.log(`Created blip: ${title}`);
    return response.data.uri;
  }

  async getBlips(limit: number = 50) {
    const response = await this.agent.com.atproto.repo.listRecords({
      repo: this.agent.session?.did!,
      collection: BLIP_NSID,
      limit,
    });

    return response.data.records.map(record => ({
      uri: record.uri,
      cid: record.cid,
      ...record.value as BlonkBlip,
    }));
  }

  async getBlip(uri: string) {
    const [repo, collection, rkey] = uri.replace('at://', '').split('/');
    
    const response = await this.agent.com.atproto.repo.getRecord({
      repo,
      collection,
      rkey,
    });

    return {
      uri,
      cid: response.data.cid,
      ...response.data.value as BlonkBlip,
    };
  }
}