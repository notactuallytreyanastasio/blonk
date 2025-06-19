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
exports.FixedFirehoseMonitor = void 0;
const ws_1 = require("ws");
const cbor_x_1 = require("cbor-x");
const repo_1 = require("@atproto/repo");
const vibe_monitor_1 = require("./vibe-monitor");
class FixedFirehoseMonitor {
    constructor(agent) {
        this.ws = null;
        this.reconnectTimeout = null;
        this.statsInterval = null;
        this.messageCount = 0;
        this.vibeDetectionCount = 0;
        this.errorCount = 0;
        this.vibeMonitor = new vibe_monitor_1.VibeMonitor(agent);
    }
    start() {
        return __awaiter(this, void 0, void 0, function* () {
            console.log('🔥 Starting fixed Bluesky Firehose monitoring for #vibe-* hashtags...');
            const firehoseUrl = 'wss://bsky.network/xrpc/com.atproto.sync.subscribeRepos';
            console.log(`🔗 Connecting to: ${firehoseUrl}`);
            this.ws = new ws_1.WebSocket(firehoseUrl);
            this.ws.on('open', () => {
                console.log('📡 Connected to Bluesky Firehose - monitoring all posts for #vibe-*');
                this.messageCount = 0;
                this.vibeDetectionCount = 0;
                this.errorCount = 0;
                // Log stats every 30 seconds
                this.statsInterval = setInterval(() => {
                    console.log(`📊 Firehose stats: ${this.messageCount} messages processed, ${this.vibeDetectionCount} #vibe-* detections, ${this.errorCount} errors`);
                }, 30000);
            });
            this.ws.on('message', (data) => __awaiter(this, void 0, void 0, function* () {
                this.messageCount++;
                try {
                    // AT Protocol uses framed messages
                    // First decode the frame header
                    const [header, remainder] = this.decodeVarint(data);
                    // Then decode the actual message
                    const messageBytes = data.slice(data.length - remainder);
                    const message = (0, cbor_x_1.decode)(messageBytes);
                    // Handle commit messages
                    if (message && message.$type === 'com.atproto.sync.subscribeRepos#commit') {
                        yield this.handleCommit(message);
                    }
                }
                catch (error) {
                    // Only log every 100th error to avoid spam
                    if (this.errorCount % 100 === 0) {
                        console.error('Error processing message:', error);
                    }
                    this.errorCount++;
                }
            }));
            this.ws.on('error', (error) => {
                console.error('❌ Firehose WebSocket error:', error.message);
            });
            this.ws.on('close', (code, reason) => {
                console.log(`🔌 Firehose disconnected: Code ${code}${reason ? `, Reason: ${reason}` : ''}`);
                console.log('   Reconnecting in 5 seconds...');
                if (this.statsInterval) {
                    clearInterval(this.statsInterval);
                    this.statsInterval = null;
                }
                this.reconnectTimeout = setTimeout(() => this.start(), 5000);
            });
        });
    }
    decodeVarint(buf) {
        let value = 0;
        let shift = 0;
        let byte;
        let i = 0;
        do {
            byte = buf[i++];
            value |= (byte & 0x7f) << shift;
            shift += 7;
        } while (byte & 0x80);
        return [value, buf.length - i];
    }
    handleCommit(commit) {
        return __awaiter(this, void 0, void 0, function* () {
            var _a;
            try {
                if (!commit.blocks)
                    return;
                // Parse the CAR file from blocks
                const car = yield (0, repo_1.readCar)(commit.blocks);
                // Process each operation
                for (const op of commit.ops || []) {
                    // We only care about post creates
                    if (op.action === 'create' && ((_a = op.path) === null || _a === void 0 ? void 0 : _a.includes('app.bsky.feed.post'))) {
                        try {
                            // Get the record bytes from the CAR file
                            const recordBytes = car.blocks.get(op.cid);
                            if (!recordBytes)
                                continue;
                            // Convert CBOR to record
                            const record = (0, repo_1.cborToLexRecord)(recordBytes);
                            // Check for #vibe- hashtags
                            if (record.text && typeof record.text === 'string' && record.text.toLowerCase().includes('#vibe-')) {
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
                        catch (e) {
                            // Record-specific error
                            if (this.errorCount % 100 === 0) {
                                console.error('Error processing record:', e);
                            }
                            this.errorCount++;
                        }
                    }
                }
            }
            catch (error) {
                // CAR parsing error
                if (this.errorCount % 100 === 0) {
                    console.error('Error handling commit:', error);
                }
                this.errorCount++;
            }
        });
    }
    stop() {
        if (this.reconnectTimeout) {
            clearTimeout(this.reconnectTimeout);
            this.reconnectTimeout = null;
        }
        if (this.statsInterval) {
            clearInterval(this.statsInterval);
            this.statsInterval = null;
        }
        if (this.ws) {
            this.ws.close();
            this.ws = null;
        }
    }
}
exports.FixedFirehoseMonitor = FixedFirehoseMonitor;
