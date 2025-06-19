"use strict";
var __createBinding = (this && this.__createBinding) || (Object.create ? (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    var desc = Object.getOwnPropertyDescriptor(m, k);
    if (!desc || ("get" in desc ? !m.__esModule : desc.writable || desc.configurable)) {
      desc = { enumerable: true, get: function() { return m[k]; } };
    }
    Object.defineProperty(o, k2, desc);
}) : (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    o[k2] = m[k];
}));
var __setModuleDefault = (this && this.__setModuleDefault) || (Object.create ? (function(o, v) {
    Object.defineProperty(o, "default", { enumerable: true, value: v });
}) : function(o, v) {
    o["default"] = v;
});
var __importStar = (this && this.__importStar) || (function () {
    var ownKeys = function(o) {
        ownKeys = Object.getOwnPropertyNames || function (o) {
            var ar = [];
            for (var k in o) if (Object.prototype.hasOwnProperty.call(o, k)) ar[ar.length] = k;
            return ar;
        };
        return ownKeys(o);
    };
    return function (mod) {
        if (mod && mod.__esModule) return mod;
        var result = {};
        if (mod != null) for (var k = ownKeys(mod), i = 0; i < k.length; i++) if (k[i] !== "default") __createBinding(result, mod, k[i]);
        __setModuleDefault(result, mod);
        return result;
    };
})();
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
const agent_1 = require("./agent");
const vibes_1 = require("./vibes");
const dotenv = __importStar(require("dotenv"));
dotenv.config();
const sampleVibes = [
    {
        name: "sunset_sunglasses_struts",
        mood: "confident, golden hour energy, main character walking down the street",
        emoji: "😎",
        color: "#FF6B6B"
    },
    {
        name: "doinkin_right",
        mood: "playful chaos, doing things correctly but in a silly way",
        emoji: "🤪",
        color: "#4ECDC4"
    },
    {
        name: "dork_nerd_linkage",
        mood: "excitedly sharing obscure knowledge, Wikipedia rabbit holes at 3am",
        emoji: "🤓",
        color: "#95E1D3"
    },
    {
        name: "cozy_corner_contemplation",
        mood: "rainy day thoughts, tea and blankets, gentle introspection",
        emoji: "☕",
        color: "#C7CEEA"
    },
    {
        name: "midnight_snack_attack",
        mood: "impulsive 2am decisions, standing in front of the fridge energy",
        emoji: "🌙",
        color: "#2C3E50"
    },
    {
        name: "sparkle_hustle_flow",
        mood: "getting things done but make it glamorous, productive but cute",
        emoji: "✨",
        color: "#FF6B9D"
    }
];
function seedVibes() {
    return __awaiter(this, void 0, void 0, function* () {
        try {
            const blonkAgent = new agent_1.BlonkAgent();
            yield blonkAgent.login();
            const agent = blonkAgent.getAgent();
            const vibeManager = new vibes_1.VibeManager(agent);
            console.log('🌈 Creating sample vibes...\n');
            for (const vibe of sampleVibes) {
                try {
                    const uri = yield vibeManager.createVibe(vibe.name, vibe.mood, vibe.emoji, vibe.color);
                    console.log(`✅ Created vibe: ${vibe.emoji} ${vibe.name}`);
                    console.log(`   Mood: ${vibe.mood}`);
                    console.log(`   URI: ${uri}\n`);
                }
                catch (error) {
                    console.error(`❌ Failed to create vibe "${vibe.name}":`, error);
                }
            }
            console.log('🎉 Vibe seeding complete!');
            console.log('Run the web server to see and join these vibes.');
        }
        catch (error) {
            console.error('Error:', error);
            process.exit(1);
        }
    });
}
seedVibes();
