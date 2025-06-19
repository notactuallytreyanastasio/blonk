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
exports.VibeManager = void 0;
const schemas_1 = require("./schemas");
const vibe_validation_1 = require("./utils/vibe-validation");
const database_1 = require("./database");
class VibeManager {
    constructor(agent) {
        this.agent = agent;
    }
    createVibe(name, mood, emoji, color) {
        return __awaiter(this, void 0, void 0, function* () {
            var _a;
            // Validate vibe name
            if (!(0, vibe_validation_1.isValidVibeName)(name)) {
                throw new Error('Invalid vibe name. Must be alphanumeric with underscores only, no spaces.');
            }
            // Normalize the name
            const normalizedName = (0, vibe_validation_1.normalizeVibeName)(name);
            // Check for duplicates
            const existingVibe = database_1.vibeMentionDb.getVibeByName(normalizedName);
            if (existingVibe) {
                throw new Error(`Vibe "${normalizedName}" already exists`);
            }
            const vibe = {
                name: normalizedName,
                mood,
                emoji,
                color,
                createdAt: new Date().toISOString(),
                memberCount: 1, // Creator is automatically a member
            };
            const response = yield this.agent.com.atproto.repo.createRecord({
                repo: (_a = this.agent.session) === null || _a === void 0 ? void 0 : _a.did,
                collection: schemas_1.VIBE_NSID,
                record: vibe,
            });
            // Automatically join the vibe you created
            yield this.joinVibe(response.data.uri, response.data.cid);
            console.log(`Created vibe: ${name} - ${mood}`);
            return response.data.uri;
        });
    }
    joinVibe(vibeUri, vibeCid) {
        return __awaiter(this, void 0, void 0, function* () {
            var _a;
            const membership = {
                vibe: {
                    uri: vibeUri,
                    cid: vibeCid,
                },
                createdAt: new Date().toISOString(),
            };
            yield this.agent.com.atproto.repo.createRecord({
                repo: (_a = this.agent.session) === null || _a === void 0 ? void 0 : _a.did,
                collection: schemas_1.VIBE_MEMBER_NSID,
                record: membership,
            });
        });
    }
    getVibes() {
        return __awaiter(this, arguments, void 0, function* (limit = 50) {
            var _a;
            const response = yield this.agent.com.atproto.repo.listRecords({
                repo: (_a = this.agent.session) === null || _a === void 0 ? void 0 : _a.did,
                collection: schemas_1.VIBE_NSID,
                limit,
            });
            return response.data.records.map(record => (Object.assign({ uri: record.uri, cid: record.cid }, record.value)));
        });
    }
    getMyVibes() {
        return __awaiter(this, void 0, void 0, function* () {
            var _a;
            const response = yield this.agent.com.atproto.repo.listRecords({
                repo: (_a = this.agent.session) === null || _a === void 0 ? void 0 : _a.did,
                collection: schemas_1.VIBE_MEMBER_NSID,
                limit: 100,
            });
            return response.data.records.map(record => ({
                uri: record.uri,
                membership: record.value,
            }));
        });
    }
    getVibe(uri) {
        return __awaiter(this, void 0, void 0, function* () {
            const [repo, collection, rkey] = uri.replace('at://', '').split('/');
            const response = yield this.agent.com.atproto.repo.getRecord({
                repo,
                collection,
                rkey,
            });
            return Object.assign({ uri, cid: response.data.cid }, response.data.value);
        });
    }
}
exports.VibeManager = VibeManager;
