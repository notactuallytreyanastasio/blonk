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
exports.SimpleFirehoseMonitor = void 0;
const ws_1 = require("ws");
const cbor_x_1 = require("cbor-x");
const vibe_monitor_1 = require("./vibe-monitor");
class SimpleFirehoseMonitor {
    constructor(agent) {
        this.ws = null;
        this.reconnectTimeout = null;
        this.messageCount = 0;
        this.vibeDetectionCount = 0;
        this.vibeMonitor = new vibe_monitor_1.VibeMonitor(agent);
    }
    start() {
        return __awaiter(this, void 0, void 0, function* () {
            console.log('🔥 Starting simple Bluesky Firehose monitoring for #vibe-* hashtags...');
            // Connect to Bluesky firehose - use the working network endpoint
            const firehoseUrl = 'wss://bsky.network/xrpc/com.atproto.sync.subscribeRepos';
            console.log(`🔗 Connecting to: ${firehoseUrl}`);
            this.ws = new ws_1.WebSocket(firehoseUrl);
            this.ws.on('open', () => {
                console.log('📡 Connected to Bluesky Firehose - monitoring all posts for #vibe-*');
                this.messageCount = 0;
                this.vibeDetectionCount = 0;
                // Log stats every 30 seconds
                setInterval(() => {
                    console.log(`📊 Firehose stats: ${this.messageCount} messages processed, ${this.vibeDetectionCount} #vibe-* detections`);
                }, 30000);
            });
            this.ws.on('message', (data) => __awaiter(this, void 0, void 0, function* () {
                var _a;
                this.messageCount++;
                try {
                    // Decode the CBOR message
                    const decoded = (0, cbor_x_1.decode)(new Uint8Array(data));
                    if (decoded && decoded.$type === 'com.atproto.sync.subscribeRepos#commit') {
                        // Process commits
                        const commit = decoded.commit;
                        if (!commit)
                            return;
                        // Look for post creates
                        for (const op of decoded.ops || []) {
                            if (op.action === 'create' && ((_a = op.path) === null || _a === void 0 ? void 0 : _a.includes('app.bsky.feed.post'))) {
                                try {
                                    // Try to decode the blocks
                                    const blocks = decoded.blocks;
                                    if (!blocks)
                                        continue;
                                    // blocks might be a Uint8Array that needs to be decoded
                                    let record;
                                    if (blocks instanceof Uint8Array) {
                                        // If blocks is raw bytes, decode it
                                        const blocksDecoded = (0, cbor_x_1.decode)(blocks);
                                        record = blocksDecoded;
                                    }
                                    else if (typeof blocks.get === 'function') {
                                        // If blocks is a Map
                                        const recordBytes = blocks.get(op.cid);
                                        if (!recordBytes)
                                            continue;
                                        record = (0, cbor_x_1.decode)(recordBytes);
                                    }
                                    else if (Array.isArray(blocks)) {
                                        // If blocks is an array, find the matching CID
                                        const block = blocks.find(b => b.cid === op.cid);
                                        if (!block)
                                            continue;
                                        record = (0, cbor_x_1.decode)(block.bytes);
                                    }
                                    else {
                                        // Try direct decoding
                                        record = blocks;
                                    }
                                    if (record && record.text && typeof record.text === 'string') {
                                        // Check for #vibe- hashtags
                                        if (record.text.toLowerCase().includes('#vibe-')) {
                                            this.vibeDetectionCount++;
                                            const authorDid = decoded.repo;
                                            console.log(`\n🎯 Detected #vibe-* in Bluesky post!`);
                                            console.log(`   Author: ${authorDid}`);
                                            console.log(`   Text: "${record.text.substring(0, 100)}${record.text.length > 100 ? '...' : ''}"`);
                                            // Process the vibe mention
                                            yield this.vibeMonitor.checkPost(record.text, authorDid, `at://${authorDid}/${op.path}`);
                                        }
                                    }
                                }
                                catch (e) {
                                    // Ignore individual record errors
                                }
                            }
                        }
                    }
                }
                catch (error) {
                    // Ignore decoding errors - firehose sends various message types
                }
            }));
            this.ws.on('error', (error) => {
                console.error('❌ Firehose WebSocket error:', error.message);
                if (error.code) {
                    console.error('   Error code:', error.code);
                }
                if (error.stack) {
                    console.error('   Stack trace:', error.stack.split('\n').slice(0, 3).join('\n'));
                }
            });
            this.ws.on('close', (code, reason) => {
                console.log(`🔌 Firehose disconnected: Code ${code}${reason ? `, Reason: ${reason}` : ''}`);
                console.log('   Reconnecting in 5 seconds...');
                this.reconnectTimeout = setTimeout(() => this.start(), 5000);
            });
        });
    }
    stop() {
        if (this.reconnectTimeout) {
            clearTimeout(this.reconnectTimeout);
            this.reconnectTimeout = null;
        }
        if (this.ws) {
            this.ws.close();
            this.ws = null;
        }
    }
}
exports.SimpleFirehoseMonitor = SimpleFirehoseMonitor;
