import { BskyAgent } from '@atproto/api';
import * as dotenv from 'dotenv';

dotenv.config();

export class BlonkAgent {
  private agent: BskyAgent;

  constructor() {
    this.agent = new BskyAgent({
      service: process.env.ATP_SERVICE || 'https://bsky.social',
    });
  }

  async login() {
    const identifier = process.env.ATP_IDENTIFIER;
    const password = process.env.ATP_PASSWORD;

    if (!identifier || !password) {
      throw new Error('Missing ATP_IDENTIFIER or ATP_PASSWORD in environment variables');
    }

    await this.agent.login({
      identifier,
      password,
    });

    console.log('Successfully authenticated with AT Protocol');
    return this.agent;
  }

  getAgent() {
    return this.agent;
  }
}