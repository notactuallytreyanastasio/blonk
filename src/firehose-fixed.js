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
const common_1 = require("@atproto/common");
const repo_1 = require("@atproto/repo");
const vibe_monitor_1 = require("./vibe-monitor");
// Frame types based on AT Protocol spec
var FrameType;
(function (FrameType) {
    FrameType[FrameType["Message"] = 1] = "Message";
    FrameType[FrameType["Error"] = -1] = "Error";
})(FrameType || (FrameType = {}));
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
            console.log('🔥 Starting FIXED Bluesky Firehose monitoring for #vibe-* hashtags...');
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
                    console.log(`📊 Firehose stats: ${this.messageCount} messages, ${this.vibeDetectionCount} #vibe-* detections, ${this.errorCount} errors`);
                }, 30000);
            });
            this.ws.on('message', (data) => __awaiter(this, void 0, void 0, function* () {
                this.messageCount++;
                try {
                    // Decode the frame structure
                    const frame = this.decodeFrame(new Uint8Array(data));
                    if (!frame) {
                        return;
                    }
                    // Handle different message types
                    switch (frame.body.$type) {
                        case 'com.atproto.sync.subscribeRepos#commit':
                            yield this.handleCommit(frame.body);
                            break;
                        case 'com.atproto.sync.subscribeRepos#error':
                            console.error('Firehose error:', frame.body.error, frame.body.message);
                            this.errorCount++;
                            break;
                        case 'com.atproto.sync.subscribeRepos#info':
                            console.log('Firehose info:', frame.body.name, frame.body.message);
                            break;
                        default:
                            // Unknown message type
                            if (this.messageCount % 1000 === 0) {
                                console.log(`Unknown message type: ${frame.body.$type}`);
                            }
                    }
                }
                catch (error) {
                    // Only log every 100th error to avoid spam
                    if (this.errorCount % 100 === 0) {
                        console.error('Error processing firehose message:', error);
                    }
                    this.errorCount++;
                }
            }));
            this.ws.on('error', (error) => {
                console.error('❌ Firehose WebSocket error:', error.message);
                if (error.code) {
                    console.error('   Error code:', error.code);
                }
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
    decodeFrame(bytes) {
        try {
            // Decode multiple CBOR items (header and body)
            const decoded = (0, common_1.cborDecodeMulti)(bytes);
            if (decoded.length < 2) {
                throw new Error('Frame must have at least header and body');
            }
            const header = decoded[0];
            const body = decoded[1];
            // Validate header
            if (!header || typeof header.op !== 'number') {
                throw new Error('Invalid frame header');
            }
            // Handle message frames
            if (header.op === FrameType.Message) {
                // Add the $type field based on the header type
                if (body && typeof body === 'object' && header.t) {
                    body.$type = header.t.startsWith('#')
                        ? `com.atproto.sync.subscribeRepos${header.t}`
                        : header.t;
                }
                return { header, body };
            }
            // Handle error frames
            if (header.op === FrameType.Error) {
                return { header, body };
            }
            throw new Error(`Unknown frame type: ${header.op}`);
        }
        catch (error) {
            if (this.errorCount % 100 === 0) {
                console.error('Error decoding frame:', error);
            }
            return null;
        }
    }
    handleCommit(commit) {
        return __awaiter(this, void 0, void 0, function* () {
            try {
                // Parse the CAR file from blocks
                const car = yield (0, repo_1.readCar)(commit.blocks);
                // Process each operation
                for (const op of commit.ops) {
                    // We only care about post creates
                    if (op.action === 'create' && op.path.includes('app.bsky.feed.post')) {
                        try {
                            // Get the record bytes from the CAR file using the operation's CID
                            const recordBytes = car.blocks.get(op.cid);
                            if (!recordBytes)
                                continue;
                            // Convert CBOR to lexicon record
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
                            // Record-specific error, don't spam logs
                            if (this.errorCount % 100 === 0) {
                                console.error('Error processing post record:', e);
                            }
                            this.errorCount++;
                        }
                    }
                }
            }
            catch (error) {
                // CAR parsing error
                if (this.errorCount % 100 === 0) {
                    console.error('Error parsing CAR file:', error);
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
