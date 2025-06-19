import { BskyAgent } from '@atproto/api';
import { BlonkPost, POST_NSID } from './schemas';

export class PostManager {
  constructor(private agent: BskyAgent) {}

  async createPost(title: string, body?: string, url?: string): Promise<string> {
    const post: BlonkPost = {
      title,
      body,
      url,
      createdAt: new Date().toISOString(),
      votes: 0,
    };

    const response = await this.agent.com.atproto.repo.createRecord({
      repo: this.agent.session?.did!,
      collection: POST_NSID,
      record: post,
    });

    console.log(`Created post: ${title}`);
    return response.data.uri;
  }

  async getPosts(limit: number = 50) {
    const response = await this.agent.com.atproto.repo.listRecords({
      repo: this.agent.session?.did!,
      collection: POST_NSID,
      limit,
    });

    return response.data.records.map(record => ({
      uri: record.uri,
      cid: record.cid,
      ...record.value as BlonkPost,
    }));
  }

  async getPost(uri: string) {
    const [repo, collection, rkey] = uri.replace('at://', '').split('/');
    
    const response = await this.agent.com.atproto.repo.getRecord({
      repo,
      collection,
      rkey,
    });

    return {
      uri,
      cid: response.data.cid,
      ...response.data.value as BlonkPost,
    };
  }
}