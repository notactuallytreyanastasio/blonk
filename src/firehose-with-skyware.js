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
exports.SkywareFirehoseMonitor = void 0;
const firehose_1 = require("@skyware/firehose");
const ws_1 = require("ws");
const vibe_monitor_1 = require("./vibe-monitor");
class SkywareFirehoseMonitor {
    constructor(agent) {
        this.messageCount = 0;
        this.vibeDetectionCount = 0;
        this.errorCount = 0;
        this.statsInterval = null;
        this.vibeMonitor = new vibe_monitor_1.VibeMonitor(agent);
        this.firehose = new firehose_1.Firehose({
            ws: ws_1.WebSocket,
            relay: 'wss://bsky.network'
        });
    }
    start() {
        return __awaiter(this, void 0, void 0, function* () {
            console.log('🔥 Starting Skyware Firehose monitoring for #vibe-* hashtags...');
            // Set up event handlers
            this.firehose.on('open', () => {
                console.log('📡 Connected to Bluesky Firehose - monitoring all posts for #vibe-*');
                this.messageCount = 0;
                this.vibeDetectionCount = 0;
                this.errorCount = 0;
                // Log stats every 30 seconds
                this.statsInterval = setInterval(() => {
                    console.log(`📊 Firehose stats: ${this.messageCount} messages, ${this.vibeDetectionCount} #vibe-* detections, ${this.errorCount} errors`);
                }, 30000);
            });
            this.firehose.on('commit', (commit) => __awaiter(this, void 0, void 0, function* () {
                this.messageCount++;
                try {
                    // Process operations in the commit
                    for (const op of commit.ops || []) {
                        // We only care about post creates
                        if (op.action === 'create' && op.path.includes('app.bsky.feed.post')) {
                            const record = op.record;
                            // Check for #vibe- hashtags
                            if ((record === null || record === void 0 ? void 0 : record.text) && typeof record.text === 'string' && record.text.toLowerCase().includes('#vibe-')) {
                                this.vibeDetectionCount++;
                                const authorDid = commit.repo;
                                console.log(`\n🎯 Detected #vibe-* in Bluesky post!`);
                                console.log(`   Author DID: ${authorDid}`);
                                console.log(`   Text: "${record.text.substring(0, 100)}${record.text.length > 100 ? '...' : ''}"`);
                                console.log(`   Path: ${op.path}`);
                                // Process the vibe mention
                                const postUri = `at://${authorDid}/${op.path}`;
                                yield this.vibeMonitor.checkPost(record.text, authorDid, postUri);
                            }
                        }
                    }
                }
                catch (error) {
                    // Only log every 100th error to avoid spam
                    if (this.errorCount % 100 === 0) {
                        console.error('Error processing commit:', error);
                    }
                    this.errorCount++;
                }
            }));
            this.firehose.on('error', ({ error }) => {
                // Only log every 100th error to avoid spam
                if (this.errorCount % 100 === 0) {
                    console.error('Firehose error:', error);
                }
                this.errorCount++;
            });
            this.firehose.on('websocketError', ({ error }) => {
                console.error('❌ WebSocket error:', error);
            });
            this.firehose.on('close', (cursor) => {
                console.log(`🔌 Firehose disconnected at cursor: ${cursor}`);
                console.log('   The firehose will auto-reconnect...');
                if (this.statsInterval) {
                    clearInterval(this.statsInterval);
                    this.statsInterval = null;
                }
            });
            // Start the firehose
            this.firehose.start();
        });
    }
    stop() {
        if (this.statsInterval) {
            clearInterval(this.statsInterval);
            this.statsInterval = null;
        }
        this.firehose.close();
    }
}
exports.SkywareFirehoseMonitor = SkywareFirehoseMonitor;
