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
const api_1 = require("@atproto/api");
const firehose_with_atproto_sync_1 = require("./firehose-with-atproto-sync");
function main() {
    return __awaiter(this, void 0, void 0, function* () {
        console.log('🚀 Starting AT Protocol Sync Firehose Test...');
        const agent = new api_1.BskyAgent({
            service: 'https://bsky.social'
        });
        const monitor = new firehose_with_atproto_sync_1.AtprotoSyncFirehoseMonitor(agent);
        // Handle graceful shutdown
        process.on('SIGINT', () => __awaiter(this, void 0, void 0, function* () {
            console.log('\n⏹️  Shutting down...');
            yield monitor.stop();
            process.exit(0);
        }));
        process.on('SIGTERM', () => __awaiter(this, void 0, void 0, function* () {
            console.log('\n⏹️  Shutting down...');
            yield monitor.stop();
            process.exit(0);
        }));
        yield monitor.start();
    });
}
main().catch((error) => {
    console.error('Fatal error:', error);
    process.exit(1);
});
