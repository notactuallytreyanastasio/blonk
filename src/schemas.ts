export const BLIP_NSID = 'com.blonk.blip';
export const FLUFF_NSID = 'com.blonk.fluff';
export const COMMENT_NSID = 'com.blonk.comment';

export interface BlonkBlip {
  title: string;
  body?: string;
  url?: string;
  createdAt: string;
  fluffs: number;
}

export interface BlonkFluff {
  subject: {
    uri: string;
    cid: string;
  };
  direction: 'up' | 'down';
  createdAt: string;
}

export interface BlonkComment {
  blip: {
    uri: string;
    cid: string;
  };
  parent?: {
    uri: string;
    cid: string;
  };
  text: string;
  createdAt: string;
}