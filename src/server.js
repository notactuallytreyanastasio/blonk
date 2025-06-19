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
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
const express_1 = __importDefault(require("express"));
const cors_1 = __importDefault(require("cors"));
const agent_1 = require("./agent");
const blips_1 = require("./blips");
const vibes_1 = require("./vibes");
const firehose_1 = require("./firehose");
const search_monitor_1 = require("./search-monitor");
const database_1 = require("./database");
const dotenv = __importStar(require("dotenv"));
dotenv.config();
const app = (0, express_1.default)();
const PORT = process.env.PORT || 3001;
app.use((0, cors_1.default)());
app.use(express_1.default.json());
let agent;
let blipManager;
let vibeManager;
let aggregator;
let searchMonitor;
function initializeAgent() {
    return __awaiter(this, void 0, void 0, function* () {
        agent = new agent_1.BlonkAgent();
        yield agent.login();
        blipManager = new blips_1.BlipManager(agent.getAgent());
        vibeManager = new vibes_1.VibeManager(agent.getAgent());
        // Start aggregating blips from all users
        aggregator = new firehose_1.BlipAggregator(agent.getAgent());
        aggregator.startPolling(30000); // Poll every 30 seconds
        // Start searching for #vibe-* hashtags on Bluesky
        searchMonitor = new search_monitor_1.SearchMonitor(agent.getAgent());
        yield searchMonitor.start();
        console.log('✅ Connected to AT Protocol');
        console.log('📡 Starting blip aggregation...');
        console.log('🔍 Searching Bluesky for #vibe-* hashtags every 2 minutes...');
    });
}
app.get('/api/blips', (req, res) => __awaiter(void 0, void 0, void 0, function* () {
    try {
        // Get aggregated blips from all users
        const blips = database_1.blipDb.getBlips(50);
        res.json({ blips });
    }
    catch (error) {
        console.error('Error fetching blips:', error);
        res.status(500).json({ error: 'Failed to fetch blips' });
    }
}));
app.post('/api/blips', (req, res) => __awaiter(void 0, void 0, void 0, function* () {
    try {
        const { title, url, body, tags, vibe } = req.body;
        const tagArray = tags || [];
        const uri = yield blipManager.createBlip(title, body, url, tagArray, vibe);
        res.json({ success: true, uri });
    }
    catch (error) {
        console.error('Error creating blip:', error);
        res.status(500).json({ error: 'Failed to create blip' });
    }
}));
// Get all vibes
app.get('/api/vibes', (req, res) => __awaiter(void 0, void 0, void 0, function* () {
    try {
        const vibes = database_1.vibeDb.getVibes(50);
        res.json({ vibes });
    }
    catch (error) {
        console.error('Error fetching vibes:', error);
        res.status(500).json({ error: 'Failed to fetch vibes' });
    }
}));
// Get emerging vibes
app.get('/api/vibes/emerging', (req, res) => __awaiter(void 0, void 0, void 0, function* () {
    try {
        const emergingVibes = database_1.vibeMentionDb.getEmergingVibes();
        res.json({ emergingVibes });
    }
    catch (error) {
        console.error('Error fetching emerging vibes:', error);
        res.status(500).json({ error: 'Failed to fetch emerging vibes' });
    }
}));
// Get blips for a specific vibe
app.get('/api/vibes/:vibeUri/blips', (req, res) => __awaiter(void 0, void 0, void 0, function* () {
    try {
        const blips = database_1.blipDb.getBlipsByVibe(req.params.vibeUri);
        res.json({ blips });
    }
    catch (error) {
        console.error('Error fetching vibe blips:', error);
        res.status(500).json({ error: 'Failed to fetch vibe blips' });
    }
}));
// Vibe creation is now disabled - vibes are created through viral hashtags
app.post('/api/vibes', (req, res) => __awaiter(void 0, void 0, void 0, function* () {
    res.status(403).json({
        error: 'Manual vibe creation is disabled. Vibes are created when #vibe-YOUR_VIBE reaches 5 unique mentions.'
    });
}));
// Join a vibe
app.post('/api/vibes/:vibeUri/join', (req, res) => __awaiter(void 0, void 0, void 0, function* () {
    var _a;
    try {
        const { cid } = req.body;
        yield vibeManager.joinVibe(req.params.vibeUri, cid);
        database_1.vibeDb.addMember(req.params.vibeUri, (_a = agent.getAgent().session) === null || _a === void 0 ? void 0 : _a.did);
        res.json({ success: true });
    }
    catch (error) {
        console.error('Error joining vibe:', error);
        res.status(500).json({ error: 'Failed to join vibe' });
    }
}));
// Manual search trigger
app.post('/api/vibes/search', (req, res) => __awaiter(void 0, void 0, void 0, function* () {
    try {
        console.log('Manual vibe search triggered...');
        yield searchMonitor.searchForVibeMentions();
        res.json({ success: true, message: 'Search completed' });
    }
    catch (error) {
        console.error('Error searching for vibes:', error);
        res.status(500).json({ error: 'Failed to search for vibes' });
    }
}));
app.get('/api/blips/tag/:tag', (req, res) => __awaiter(void 0, void 0, void 0, function* () {
    try {
        const taggedBlips = database_1.blipDb.getBlipsByTag(req.params.tag);
        res.json({ blips: taggedBlips, tag: req.params.tag });
    }
    catch (error) {
        console.error('Error fetching tagged blips:', error);
        res.status(500).json({ error: 'Failed to fetch tagged blips' });
    }
}));
// Add endpoint to follow new users
app.post('/api/follow', (req, res) => __awaiter(void 0, void 0, void 0, function* () {
    try {
        const { did } = req.body;
        if (!did) {
            return res.status(400).json({ error: 'DID required' });
        }
        aggregator.addUser(did);
        res.json({ success: true, message: `Now following ${did}` });
    }
    catch (error) {
        console.error('Error following user:', error);
        res.status(500).json({ error: 'Failed to follow user' });
    }
}));
initializeAgent().then(() => {
    app.listen(PORT, () => {
        console.log(`🚀 Blonk API server running at http://localhost:${PORT}`);
    });
}).catch(error => {
    console.error('Failed to initialize:', error);
    process.exit(1);
});
