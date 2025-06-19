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
exports.DebugFirehose = void 0;
const ws_1 = require("ws");
class DebugFirehose {
    constructor() {
        this.ws = null;
    }
    start() {
        return __awaiter(this, void 0, void 0, function* () {
            console.log('🔍 DEBUG: Starting firehose connection test...');
            const urls = [
                'wss://bsky.social/xrpc/com.atproto.sync.subscribeRepos',
                'wss://bsky.network/xrpc/com.atproto.sync.subscribeRepos',
            ];
            for (const url of urls) {
                console.log(`\n🔗 Trying: ${url}`);
                yield this.testConnection(url);
            }
        });
    }
    testConnection(url) {
        return __awaiter(this, void 0, void 0, function* () {
            return new Promise((resolve) => {
                const ws = new ws_1.WebSocket(url);
                let messageCount = 0;
                const timeout = setTimeout(() => {
                    console.log('⏱️ Timeout after 10 seconds');
                    ws.close();
                    resolve();
                }, 10000);
                ws.on('open', () => {
                    console.log('✅ Connected successfully!');
                });
                ws.on('message', (data) => {
                    messageCount++;
                    console.log(`📦 Message #${messageCount}: ${data.length} bytes`);
                    // Log first few bytes to see message type
                    const preview = data.slice(0, 100);
                    console.log(`   Preview: ${preview.toString('hex').substring(0, 50)}...`);
                    if (messageCount >= 5) {
                        console.log('✅ Successfully receiving messages');
                        clearTimeout(timeout);
                        ws.close();
                        resolve();
                    }
                });
                ws.on('error', (error) => {
                    console.log(`❌ Error: ${error.message}`);
                    console.log(`   Code: ${error.code}`);
                    if (error.stack) {
                        console.log(`   Stack: ${error.stack.split('\n')[0]}`);
                    }
                    clearTimeout(timeout);
                    resolve();
                });
                ws.on('close', (code, reason) => {
                    console.log(`🔌 Closed: Code ${code}${reason ? `, Reason: ${reason}` : ''}`);
                    clearTimeout(timeout);
                    resolve();
                });
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
exports.DebugFirehose = DebugFirehose;
// Run the test
const debugFirehose = new DebugFirehose();
debugFirehose.start();
