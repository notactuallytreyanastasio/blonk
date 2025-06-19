"use strict";
var __awaiter = (this && this.__awaiter) || function (thisArg, _arguments, P, generator) {
    function adopt(value) { return value instanceof P ? value : new P(function (resolve) { resolve(value); }); }
    return new (P || (P = Promise))(function (resolve, reject) {
        function fulfilled(value) { try { step(generator.next(value)); } catch (e) { reject(e); } }
        function rejected(value) { try { step(generator["throw"](value)); } catch (e) { reject(e); } }
        function step(result) { result.done ? resolve(result.value) : adopt(result.value).then(fulfilled, rejected); }
        step((generator = generator.apply(thisArg, _arguments || [])).next());
    });
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.BlipAggregator = exports.FirehoseSubscriber = void 0;
const ws_1 = require("ws");
const database_1 = require("./database");
const schemas_1 = require("./schemas");
const vibe_monitor_1 = require("./vibe-monitor");
class FirehoseSubscriber {
    constructor(agent) {
        this.ws = null;
        this.agent = agent;
    }
    start() {
        return __awaiter(this, void 0, void 0, function* () {
            console.log('🔥 Starting Firehose subscription...');
            // Connect to the AT Protocol firehose
            this.ws = new ws_1.WebSocket('wss://bsky.social/xrpc/com.atproto.sync.subscribeRepos');
            this.ws.on('open', () => {
                console.log('📡 Connected to Firehose');
            });
            this.ws.on('message', (data) => __awaiter(this, void 0, void 0, function* () {
                try {
                    // The firehose sends CAR files, but for now we'll use a simpler approach
                    // In production, you'd parse the CAR files properly
                    // For now, let's poll known users instead
                }
                catch (error) {
                    console.error('Error processing firehose message:', error);
                }
            }));
            this.ws.on('error', (error) => {
                console.error('Firehose error:', error);
            });
            this.ws.on('close', () => {
                console.log('Firehose connection closed, reconnecting...');
                setTimeout(() => this.start(), 5000);
            });
        });
    }
    stop() {
        if (this.ws) {
            this.ws.close();
            this.ws = null;
        }
    }
}
exports.FirehoseSubscriber = FirehoseSubscriber;
// Simpler approach for now: poll known users
class BlipAggregator {
    constructor(agent) {
        var _a;
        this.knownUsers = new Set();
        this.agent = agent;
        this.vibeMonitor = new vibe_monitor_1.VibeMonitor(agent);
        // Add your own DID to start
        if ((_a = agent.session) === null || _a === void 0 ? void 0 : _a.did) {
            this.knownUsers.add(agent.session.did);
        }
    }
    aggregateBlips() {
        return __awaiter(this, void 0, void 0, function* () {
            var _a, _b;
            console.log('🔍 Aggregating blips and vibes from known users...');
            for (const did of this.knownUsers) {
                try {
                    // Get user profile
                    const profile = yield this.agent.getProfile({ actor: did });
                    // List their vibes
                    const vibeResponse = yield this.agent.com.atproto.repo.listRecords({
                        repo: did,
                        collection: schemas_1.VIBE_NSID,
                        limit: 100,
                    });
                    for (const record of vibeResponse.data.records) {
                        const vibe = record.value;
                        database_1.vibeDb.insertVibe({
                            uri: record.uri,
                            cid: record.cid,
                            creatorDid: did,
                            name: vibe.name,
                            mood: vibe.mood,
                            emoji: vibe.emoji,
                            color: vibe.color,
                            memberCount: vibe.memberCount || 0,
                            createdAt: vibe.createdAt,
                        });
                    }
                    console.log(`✅ Indexed ${vibeResponse.data.records.length} vibes from @${profile.data.handle}`);
                    // List their blips
                    const response = yield this.agent.com.atproto.repo.listRecords({
                        repo: did,
                        collection: schemas_1.BLIP_NSID,
                        limit: 100,
                    });
                    for (const record of response.data.records) {
                        const blip = record.value;
                        // Check for vibe hashtags in blip content
                        const textToCheck = `${blip.title || ''} ${blip.body || ''}`;
                        yield this.vibeMonitor.checkPost(textToCheck, did, record.uri);
                        database_1.blipDb.insertBlip({
                            uri: record.uri,
                            cid: record.cid,
                            authorDid: did,
                            authorHandle: profile.data.handle,
                            authorDisplayName: profile.data.displayName,
                            title: blip.title,
                            body: blip.body,
                            url: blip.url,
                            tags: blip.tags || [],
                            vibeUri: (_a = blip.vibe) === null || _a === void 0 ? void 0 : _a.uri,
                            vibeName: (_b = blip.vibe) === null || _b === void 0 ? void 0 : _b.name,
                            grooves: blip.grooves || 0,
                            createdAt: blip.createdAt,
                        });
                    }
                    console.log(`✅ Indexed ${response.data.records.length} blips from @${profile.data.handle}`);
                }
                catch (error) {
                    console.error(`Failed to aggregate blips from ${did}:`, error);
                }
            }
        });
    }
    addUser(did) {
        this.knownUsers.add(did);
    }
    startPolling() {
        return __awaiter(this, arguments, void 0, function* (intervalMs = 60000) {
            // Initial aggregation
            yield this.aggregateBlips();
            // Poll periodically
            setInterval(() => {
                this.aggregateBlips();
            }, intervalMs);
        });
    }
}
exports.BlipAggregator = BlipAggregator;
