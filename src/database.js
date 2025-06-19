"use strict";
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.vibeMentionDb = exports.vibeDb = exports.blipDb = void 0;
const better_sqlite3_1 = __importDefault(require("better-sqlite3"));
const path_1 = __importDefault(require("path"));
const db = new better_sqlite3_1.default(path_1.default.join(__dirname, '../blonk.db'));
// Initialize database schema
db.exec(`
  CREATE TABLE IF NOT EXISTS blips (
    uri TEXT PRIMARY KEY,
    cid TEXT NOT NULL,
    author_did TEXT NOT NULL,
    author_handle TEXT,
    author_display_name TEXT,
    title TEXT NOT NULL,
    body TEXT,
    url TEXT,
    tags TEXT,
    vibe_uri TEXT,
    vibe_name TEXT,
    fluffs INTEGER DEFAULT 0,
    created_at TEXT NOT NULL,
    indexed_at TEXT DEFAULT CURRENT_TIMESTAMP
  );

  CREATE INDEX IF NOT EXISTS idx_blips_created_at ON blips(created_at DESC);
  CREATE INDEX IF NOT EXISTS idx_blips_author ON blips(author_did);
  CREATE INDEX IF NOT EXISTS idx_blips_fluffs ON blips(fluffs DESC);
  CREATE INDEX IF NOT EXISTS idx_blips_vibe ON blips(vibe_uri);

  CREATE TABLE IF NOT EXISTS vibes (
    uri TEXT PRIMARY KEY,
    cid TEXT NOT NULL,
    creator_did TEXT NOT NULL,
    name TEXT NOT NULL,
    mood TEXT NOT NULL,
    emoji TEXT,
    color TEXT,
    member_count INTEGER DEFAULT 0,
    created_at TEXT NOT NULL,
    indexed_at TEXT DEFAULT CURRENT_TIMESTAMP
  );

  CREATE INDEX IF NOT EXISTS idx_vibes_name ON vibes(name);
  CREATE INDEX IF NOT EXISTS idx_vibes_member_count ON vibes(member_count DESC);

  CREATE TABLE IF NOT EXISTS vibe_members (
    vibe_uri TEXT NOT NULL,
    member_did TEXT NOT NULL,
    joined_at TEXT NOT NULL,
    PRIMARY KEY (vibe_uri, member_did)
  );

  CREATE TABLE IF NOT EXISTS vibe_mentions (
    vibe_name TEXT NOT NULL,
    mentioned_by_did TEXT NOT NULL,
    mentioned_at TEXT NOT NULL,
    post_uri TEXT,
    PRIMARY KEY (vibe_name, mentioned_by_did, mentioned_at)
  );

  CREATE INDEX IF NOT EXISTS idx_vibe_mentions_name ON vibe_mentions(vibe_name);
  CREATE UNIQUE INDEX IF NOT EXISTS idx_vibes_unique_name ON vibes(LOWER(name));
`);
exports.blipDb = {
    insertBlip: (blip) => {
        const stmt = db.prepare(`
      INSERT OR REPLACE INTO blips 
      (uri, cid, author_did, author_handle, author_display_name, title, body, url, tags, vibe_uri, vibe_name, fluffs, created_at)
      VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
    `);
        stmt.run(blip.uri, blip.cid, blip.authorDid, blip.authorHandle, blip.authorDisplayName, blip.title, blip.body, blip.url, JSON.stringify(blip.tags || []), blip.vibeUri, blip.vibeName, blip.fluffs, blip.createdAt);
    },
    getBlips: (limit = 50, offset = 0) => {
        const stmt = db.prepare(`
      SELECT * FROM blips 
      ORDER BY created_at DESC 
      LIMIT ? OFFSET ?
    `);
        const rows = stmt.all(limit, offset);
        return rows.map(row => ({
            uri: row.uri,
            cid: row.cid,
            authorDid: row.author_did,
            authorHandle: row.author_handle,
            authorDisplayName: row.author_display_name,
            title: row.title,
            body: row.body,
            url: row.url,
            tags: JSON.parse(row.tags || '[]'),
            vibeUri: row.vibe_uri,
            vibeName: row.vibe_name,
            fluffs: row.fluffs,
            createdAt: row.created_at,
            indexedAt: row.indexed_at,
        }));
    },
    getBlipsByTag: (tag, limit = 50) => {
        const stmt = db.prepare(`
      SELECT * FROM blips 
      WHERE tags LIKE ? 
      ORDER BY created_at DESC 
      LIMIT ?
    `);
        const rows = stmt.all(`%"${tag}"%`, limit);
        return rows.map(row => ({
            uri: row.uri,
            cid: row.cid,
            authorDid: row.author_did,
            authorHandle: row.author_handle,
            authorDisplayName: row.author_display_name,
            title: row.title,
            body: row.body,
            url: row.url,
            tags: JSON.parse(row.tags || '[]'),
            vibeUri: row.vibe_uri,
            vibeName: row.vibe_name,
            fluffs: row.fluffs,
            createdAt: row.created_at,
            indexedAt: row.indexed_at,
        }));
    },
    getBlipsByVibe: (vibeUri, limit = 50) => {
        const stmt = db.prepare(`
      SELECT * FROM blips 
      WHERE vibe_uri = ? 
      ORDER BY created_at DESC 
      LIMIT ?
    `);
        const rows = stmt.all(vibeUri, limit);
        return rows.map(row => ({
            uri: row.uri,
            cid: row.cid,
            authorDid: row.author_did,
            authorHandle: row.author_handle,
            authorDisplayName: row.author_display_name,
            title: row.title,
            body: row.body,
            url: row.url,
            tags: JSON.parse(row.tags || '[]'),
            vibeUri: row.vibe_uri,
            vibeName: row.vibe_name,
            fluffs: row.fluffs,
            createdAt: row.created_at,
            indexedAt: row.indexed_at,
        }));
    },
};
exports.vibeDb = {
    insertVibe: (vibe) => {
        const stmt = db.prepare(`
      INSERT OR REPLACE INTO vibes 
      (uri, cid, creator_did, name, mood, emoji, color, member_count, created_at)
      VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)
    `);
        stmt.run(vibe.uri, vibe.cid, vibe.creatorDid, vibe.name, vibe.mood, vibe.emoji, vibe.color, vibe.memberCount, vibe.createdAt);
    },
    getVibes: (limit = 50) => {
        const stmt = db.prepare(`
      SELECT * FROM vibes 
      ORDER BY member_count DESC, created_at DESC 
      LIMIT ?
    `);
        const rows = stmt.all(limit);
        return rows.map(row => ({
            uri: row.uri,
            cid: row.cid,
            creatorDid: row.creator_did,
            name: row.name,
            mood: row.mood,
            emoji: row.emoji,
            color: row.color,
            memberCount: row.member_count,
            createdAt: row.created_at,
            indexedAt: row.indexed_at,
        }));
    },
    addMember: (vibeUri, memberDid) => {
        const stmt = db.prepare(`
      INSERT OR IGNORE INTO vibe_members 
      (vibe_uri, member_did, joined_at)
      VALUES (?, ?, ?)
    `);
        stmt.run(vibeUri, memberDid, new Date().toISOString());
        // Update member count
        const updateStmt = db.prepare(`
      UPDATE vibes 
      SET member_count = (SELECT COUNT(*) FROM vibe_members WHERE vibe_uri = ?)
      WHERE uri = ?
    `);
        updateStmt.run(vibeUri, vibeUri);
    },
};
exports.vibeMentionDb = {
    trackMention: (vibeName, mentionedByDid, postUri) => {
        const stmt = db.prepare(`
      INSERT OR IGNORE INTO vibe_mentions 
      (vibe_name, mentioned_by_did, mentioned_at, post_uri)
      VALUES (?, ?, ?, ?)
    `);
        stmt.run(vibeName, mentionedByDid, new Date().toISOString(), postUri);
    },
    getMentionCount: (vibeName) => {
        const stmt = db.prepare(`
      SELECT COUNT(DISTINCT mentioned_by_did) as count 
      FROM vibe_mentions 
      WHERE vibe_name = ?
    `);
        const result = stmt.get(vibeName);
        return (result === null || result === void 0 ? void 0 : result.count) || 0;
    },
    getEmergingVibes: () => {
        const stmt = db.prepare(`
      SELECT 
        vm.vibe_name,
        COUNT(DISTINCT vm.mentioned_by_did) as mention_count,
        MIN(vm.mentioned_at) as first_mentioned,
        MAX(vm.mentioned_at) as last_mentioned
      FROM vibe_mentions vm
      LEFT JOIN vibes v ON LOWER(vm.vibe_name) = LOWER(v.name)
      WHERE v.uri IS NULL
      GROUP BY vm.vibe_name
      ORDER BY mention_count DESC, last_mentioned DESC
    `);
        return stmt.all().map(row => ({
            vibeName: row.vibe_name,
            mentionCount: row.mention_count,
            firstMentioned: row.first_mentioned,
            lastMentioned: row.last_mentioned,
            progress: (row.mention_count / 5) * 100, // 5 is the threshold
        }));
    },
    getVibeByName: (name) => {
        const stmt = db.prepare(`
      SELECT * FROM vibes 
      WHERE LOWER(name) = LOWER(?)
    `);
        const row = stmt.get(name);
        if (!row)
            return null;
        return {
            uri: row.uri,
            cid: row.cid,
            creatorDid: row.creator_did,
            name: row.name,
            mood: row.mood,
            emoji: row.emoji,
            color: row.color,
            memberCount: row.member_count,
            createdAt: row.created_at,
            indexedAt: row.indexed_at,
        };
    },
};
exports.default = db;
