export const POST_NSID = 'com.blonk.post';
export const VOTE_NSID = 'com.blonk.vote';
export const COMMENT_NSID = 'com.blonk.comment';

export interface BlonkPost {
  title: string;
  body?: string;
  url?: string;
  createdAt: string;
  votes: number;
}

export interface BlonkVote {
  subject: {
    uri: string;
    cid: string;
  };
  direction: 'up' | 'down';
  createdAt: string;
}

export interface BlonkComment {
  post: {
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