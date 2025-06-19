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
const blips_1 = require("./blips");
function main() {
    return __awaiter(this, void 0, void 0, function* () {
        try {
            const blonkAgent = new agent_1.BlonkAgent();
            yield blonkAgent.login();
            const agent = blonkAgent.getAgent();
            const blipManager = new blips_1.BlipManager(agent);
            console.log('\n📡 Blonk - Vibe Radar');
            console.log('=====================\n');
            console.log('Transmitting a test blip...');
            const blipUri = yield blipManager.createBlip('Welcome to the Blonk Vibe Radar!', 'This is the first blip on Blonk, where vibes are tracked on the radar.', 'https://atproto.com', ['welcome', 'atproto', 'blonk']);
            console.log(`Blip transmitted with URI: ${blipUri}\n`);
            console.log('Scanning radar for recent blips...');
            const blips = yield blipManager.getBlips(10);
            console.log(`\n📡 ${blips.length} blips on the radar:`);
            blips.forEach((blip, index) => {
                console.log(`\n${index + 1}. ${blip.title}`);
                if (blip.body)
                    console.log(`   ${blip.body.substring(0, 100)}...`);
                if (blip.url)
                    console.log(`   🔗 ${blip.url}`);
                console.log(`   📅 ${new Date(blip.createdAt).toLocaleString()}`);
                console.log(`   ✨ ${blip.fluffs} fluffs`);
            });
        }
        catch (error) {
            console.error('Error:', error);
            process.exit(1);
        }
    });
}
main();
