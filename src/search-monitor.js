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
exports.SearchMonitor = void 0;
const vibe_monitor_1 = require("./vibe-monitor");
class SearchMonitor {
    constructor(agent) {
        this.searchInterval = null;
        this.agent = agent;
        this.vibeMonitor = new vibe_monitor_1.VibeMonitor(agent);
    }
    start() {
        return __awaiter(this, void 0, void 0, function* () {
            console.log('🔍 Starting periodic search for #vibe-* mentions...');
            // Initial search
            yield this.searchForVibeMentions();
            // Search every 2 minutes
            this.searchInterval = setInterval(() => {
                this.searchForVibeMentions();
            }, 2 * 60 * 1000);
        });
    }
    searchForVibeMentions() {
        return __awaiter(this, void 0, void 0, function* () {
            try {
                console.log('🔎 Searching Bluesky for #vibe-* mentions...');
                // Search for posts containing #vibe-
                const searchResponse = yield this.agent.app.bsky.feed.searchPosts({
                    q: '#vibe-',
                    limit: 50,
                });
                let newMentions = 0;
                for (const post of searchResponse.data.posts) {
                    const text = post.record.text;
                    const authorDid = post.author.did;
                    if (text && text.includes('#vibe-')) {
                        console.log(`Found #vibe-* mention by @${post.author.handle}: "${text.substring(0, 100)}..."`);
                        yield this.vibeMonitor.checkPost(text, authorDid, post.uri);
                        newMentions++;
                    }
                }
                if (newMentions > 0) {
                    console.log(`✅ Processed ${newMentions} new #vibe-* mentions`);
                }
                else {
                    console.log('No new #vibe-* mentions found in this search');
                }
            }
            catch (error) {
                console.error('Error searching for vibe mentions:', error);
            }
        });
    }
    stop() {
        if (this.searchInterval) {
            clearInterval(this.searchInterval);
            this.searchInterval = null;
        }
    }
}
exports.SearchMonitor = SearchMonitor;
