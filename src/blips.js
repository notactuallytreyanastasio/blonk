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
exports.BlipManager = void 0;
const schemas_1 = require("./schemas");
class BlipManager {
    constructor(agent) {
        this.agent = agent;
    }
    createBlip(title, body, url, tags, vibe) {
        return __awaiter(this, void 0, void 0, function* () {
            var _a;
            const blip = {
                title,
                body,
                url,
                tags,
                vibe,
                createdAt: new Date().toISOString(),
                fluffs: 0,
            };
            const response = yield this.agent.com.atproto.repo.createRecord({
                repo: (_a = this.agent.session) === null || _a === void 0 ? void 0 : _a.did,
                collection: schemas_1.BLIP_NSID,
                record: blip,
            });
            console.log(`Created blip: ${title}`);
            return response.data.uri;
        });
    }
    getBlips() {
        return __awaiter(this, arguments, void 0, function* (limit = 50) {
            var _a;
            const response = yield this.agent.com.atproto.repo.listRecords({
                repo: (_a = this.agent.session) === null || _a === void 0 ? void 0 : _a.did,
                collection: schemas_1.BLIP_NSID,
                limit,
            });
            return response.data.records.map(record => (Object.assign({ uri: record.uri, cid: record.cid }, record.value)));
        });
    }
    getBlip(uri) {
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
exports.BlipManager = BlipManager;
