export const BLIP_NSID = 'com.blonk.blip';
export const GROOVE_NSID = 'com.blonk.groove';
export const COMMENT_NSID = 'com.blonk.comment';
export const VIBE_NSID = 'com.blonk.vibe';
export const VIBE_MEMBER_NSID = 'com.blonk.vibeMember';

export interface BlonkVibe {
  name: string;
  mood: string;
  emoji?: string;
  color?: string;
  createdAt: string;
  memberCount: number;
}

export interface BlonkVibeMember {
  vibe: {
    uri: string;
    cid: string;
  };
  createdAt: string;
}

export interface BlonkBlip {
  title: string;
  body?: string;
  url?: string;
  tags?: string[];
  vibe?: {
    uri: string;
    cid: string;
    name?: string; // denormalized for display
  };
  createdAt: string;
  grooves: number;
}

export interface BlonkGroove {
  subject: {
    uri: string;
    cid: string;
  };
  grooveType: 'looks_good' | 'shit_rips';
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