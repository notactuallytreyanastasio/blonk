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
exports.VibeMonitor = void 0;
const vibes_1 = require("./vibes");
const database_1 = require("./database");
const vibe_validation_1 = require("./utils/vibe-validation");
const VIBE_CREATION_THRESHOLD = 5; // Number of unique users needed to create a vibe
class VibeMonitor {
    constructor(agent) {
        this.agent = agent;
        this.vibeManager = new vibes_1.VibeManager(agent);
    }
    checkPost(text, authorDid, postUri) {
        return __awaiter(this, void 0, void 0, function* () {
            const vibeName = (0, vibe_validation_1.extractVibeFromHashtag)(text);
            if (!vibeName)
                return;
            console.log(`📡 Detected vibe mention: #vibe-${vibeName} by ${authorDid}`);
            // Track the mention
            database_1.vibeMentionDb.trackMention(vibeName, authorDid, postUri);
            // Check if vibe already exists
            const existingVibe = database_1.vibeMentionDb.getVibeByName(vibeName);
            if (existingVibe) {
                console.log(`✅ Vibe "${vibeName}" already exists`);
                return;
            }
            // Check if we've hit the threshold
            const mentionCount = database_1.vibeMentionDb.getMentionCount(vibeName);
            console.log(`📊 Vibe "${vibeName}" has ${mentionCount} unique mentions`);
            if (mentionCount >= VIBE_CREATION_THRESHOLD) {
                yield this.createVibeFromHashtag(vibeName, mentionCount);
            }
        });
    }
    createVibeFromHashtag(vibeName, mentionCount) {
        return __awaiter(this, void 0, void 0, function* () {
            try {
                console.log(`🎉 Creating new vibe "${vibeName}" after ${mentionCount} mentions!`);
                // Generate a mood based on the vibe name
                const mood = this.generateMood(vibeName);
                // Create the vibe
                const uri = yield this.vibeManager.createVibe(vibeName, mood, '🌊', // Default emoji
                '#7B68EE' // Default color (medium purple)
                );
                // Store in local database
                database_1.vibeDb.insertVibe({
                    uri,
                    cid: 'generated', // We'd get this from the creation response
                    creatorDid: 'system',
                    name: vibeName,
                    mood,
                    emoji: '🌊',
                    color: '#7B68EE',
                    memberCount: mentionCount,
                    createdAt: new Date().toISOString(),
                });
                console.log(`✨ Vibe "${vibeName}" created successfully!`);
            }
            catch (error) {
                console.error(`Failed to create vibe "${vibeName}":`, error);
            }
        });
    }
    generateMood(vibeName) {
        // Generate a mood description based on the vibe name
        const words = vibeName.split('_').filter(w => w.length > 0);
        if (words.length === 0)
            return 'mysterious energy';
        // Some fun default moods based on patterns
        if (vibeName.includes('chill'))
            return 'relaxed and easy-going vibes';
        if (vibeName.includes('chaos'))
            return 'delightfully unpredictable energy';
        if (vibeName.includes('nerd'))
            return 'enthusiastically geeky discussions';
        if (vibeName.includes('midnight'))
            return 'late night contemplative mood';
        if (vibeName.includes('morning'))
            return 'fresh start energy';
        // Default: create a mood from the words
        return `${words.join(' ')} energy, discovered by the community`;
    }
}
exports.VibeMonitor = VibeMonitor;
