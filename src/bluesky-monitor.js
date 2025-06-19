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
exports.BlueskyFirehoseMonitor = void 0;
const sync_1 = require("@atproto/sync");
const vibe_monitor_1 = require("./vibe-monitor");
class BlueskyFirehoseMonitor {
    constructor(agent) {
        this.subscription = null;
        this.vibeMonitor = new vibe_monitor_1.VibeMonitor(agent);
    }
    start() {
        return __awaiter(this, void 0, void 0, function* () {
            console.log('🔥 Starting Bluesky Firehose monitoring for #vibe-* hashtags...');
            this.subscription = new sync_1.Subscription({
                service: 'wss://bsky.social',
                method: 'com.atproto.sync.subscribeRepos',
                getState: () => ({}),
                validate: (value) => value,
            });
            this.subscription.on('message', (msg) => {
                if (msg.commit) {
                    this.processCommit(msg.commit);
                }
            });
            this.subscription.on('error', (error) => {
                console.error('Bluesky Firehose error:', error);
            });
            yield this.subscription.start();
            console.log('📡 Connected to Bluesky Firehose');
        });
    }
    processCommit(commit) {
        return __awaiter(this, void 0, void 0, function* () {
            var _a;
            try {
                // Check each operation in the commit
                for (const op of commit.ops || []) {
                    if (op.action === 'create' && ((_a = op.path) === null || _a === void 0 ? void 0 : _a.includes('app.bsky.feed.post'))) {
                        // This is a new post
                        const record = op.record;
                        if (record && record.text) {
                            const text = record.text;
                            // Check for #vibe-* hashtags
                            if (text.includes('#vibe-')) {
                                const authorDid = commit.repo;
                                console.log(`🎯 Detected #vibe-* in Bluesky post from ${authorDid}: "${text.substring(0, 100)}..."`);
                                // Process the vibe mention
                                yield this.vibeMonitor.checkPost(text, authorDid, `at://${authorDid}/${op.path}`);
                            }
                        }
                    }
                }
            }
            catch (error) {
                // Ignore errors for individual commits
            }
        });
    }
    stop() {
        if (this.subscription) {
            this.subscription.stop();
            this.subscription = null;
        }
    }
}
exports.BlueskyFirehoseMonitor = BlueskyFirehoseMonitor;
