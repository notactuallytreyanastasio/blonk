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
exports.ATProtoFirehoseMonitor = void 0;
const sync_1 = require("@atproto/sync");
const vibe_monitor_1 = require("./vibe-monitor");
class ATProtoFirehoseMonitor {
    constructor(agent) {
        this.messageCount = 0;
        this.vibeDetectionCount = 0;
        this.statsInterval = null;
        this.vibeMonitor = new vibe_monitor_1.VibeMonitor(agent);
        this.firehose = new sync_1.Firehose({
            filterCollections: ['app.bsky.feed.post'],
            handleEvent: (evt) => __awaiter(this, void 0, void 0, function* () {
                this.messageCount++;
                if (evt.event === 'create') {
                    const ops = (0, sync_1.getOpsByType)(evt);
                    for (const op of ops.posts.creates) {
                        try {
                            const record = op.record;
                            // Check for #vibe- hashtags
                            if (record.text && typeof record.text === 'string' && record.text.toLowerCase().includes('#vibe-')) {
                                this.vibeDetectionCount++;
                                console.log(`\n🎯 Detected #vibe-* in Bluesky post!`);
                                console.log(`   Author DID: ${op.author}`);
                                console.log(`   Text: "${record.text.substring(0, 100)}${record.text.length > 100 ? '...' : ''}"`);
                                console.log(`   URI: ${op.uri}`);
                                // Process the vibe mention
                                yield this.vibeMonitor.checkPost(record.text, op.author, op.uri);
                            }
                        }
                        catch (e) {
                            console.error('Error processing post:', e);
                        }
                    }
                }
            }),
            onError: (error) => {
                console.error('Firehose error:', error);
            }
        });
    }
    start() {
        return __awaiter(this, void 0, void 0, function* () {
            console.log('🔥 Starting AT Protocol Sync Firehose monitoring for #vibe-* hashtags...');
            // Start stats logging
            this.statsInterval = setInterval(() => {
                console.log(`📊 Firehose stats: ${this.messageCount} messages processed, ${this.vibeDetectionCount} #vibe-* detections`);
            }, 30000);
            // Start the firehose
            yield this.firehose.start();
            console.log('📡 Connected to AT Protocol Firehose - monitoring all posts for #vibe-*');
        });
    }
    stop() {
        if (this.statsInterval) {
            clearInterval(this.statsInterval);
            this.statsInterval = null;
        }
        this.firehose.stop();
    }
}
exports.ATProtoFirehoseMonitor = ATProtoFirehoseMonitor;
