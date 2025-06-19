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
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.blipsApi = void 0;
const axios_1 = __importDefault(require("axios"));
const API_BASE = '/api';
exports.blipsApi = {
    getBlips: () => __awaiter(void 0, void 0, void 0, function* () {
        const { data } = yield axios_1.default.get(`${API_BASE}/blips`);
        return data.blips;
    }),
    getBlipsByTag: (tag) => __awaiter(void 0, void 0, void 0, function* () {
        const { data } = yield axios_1.default.get(`${API_BASE}/blips/tag/${tag}`);
        return data.blips;
    }),
    createBlip: (blip) => __awaiter(void 0, void 0, void 0, function* () {
        const { data } = yield axios_1.default.post(`${API_BASE}/blips`, blip);
        return data;
    }),
};
