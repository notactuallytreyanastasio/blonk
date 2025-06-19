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
const { FirehoseSubscription } = require('@skyware/firehose');
function testFirehose() {
    return __awaiter(this, void 0, void 0, function* () {
        console.log('🔥 Testing Skyware Firehose...');
        const firehose = new FirehoseSubscription({
            service: 'wss://bsky.network',
            filter: {
                collections: ['app.bsky.feed.post']
            }
        });
        let messageCount = 0;
        let vibeCount = 0;
        firehose.on('commit', (commit) => {
            messageCount++;
            commit.ops.forEach((op) => {
                var _a;
                if (op.action === 'create' && ((_a = op.record) === null || _a === void 0 ? void 0 : _a.text)) {
                    const text = op.record.text;
                    if (text.toLowerCase().includes('#vibe-')) {
                        vibeCount++;
                        console.log(`\n🎯 FOUND #vibe-* POST!`);
                        console.log(`   Author: ${commit.repo}`);
                        console.log(`   Text: ${text}`);
                        console.log(`   Path: ${op.path}`);
                    }
                }
            });
        });
        firehose.on('error', (error) => {
            console.error('Firehose error:', error);
        });
        yield firehose.start();
        console.log('📡 Connected to Skyware Firehose');
        // Log stats every 10 seconds
        setInterval(() => {
            console.log(`📊 Stats: ${messageCount} messages, ${vibeCount} #vibe-* posts`);
        }, 10000);
    });
}
testFirehose().catch(console.error);
