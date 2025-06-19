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
const agent_1 = require("./agent");
function postTestVibe() {
    return __awaiter(this, void 0, void 0, function* () {
        const agent = new agent_1.BlonkAgent();
        yield agent.login();
        const bskyAgent = agent.getAgent();
        const testVibeName = `blonk_test_${Date.now()}`;
        console.log(`Posting test vibe: #vibe-${testVibeName}`);
        const result = yield bskyAgent.post({
            text: `Testing Blonk vibe detection! #vibe-${testVibeName}`,
            createdAt: new Date().toISOString(),
        });
        console.log('Posted:', result.uri);
        console.log(`Now search for: #vibe-${testVibeName}`);
    });
}
postTestVibe().catch(console.error);
