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
exports.Submit = Submit;
const react_1 = require("react");
const react_router_dom_1 = require("react-router-dom");
const useBlips_1 = require("../hooks/useBlips");
const useVibes_1 = require("../hooks/useVibes");
function Submit() {
    const navigate = (0, react_router_dom_1.useNavigate)();
    const createBlip = (0, useBlips_1.useCreateBlip)();
    const { data: vibes } = (0, useVibes_1.useVibes)();
    const [formData, setFormData] = (0, react_1.useState)({
        title: '',
        url: '',
        body: '',
        tags: '',
        vibeUri: '',
    });
    const handleSubmit = (e) => __awaiter(this, void 0, void 0, function* () {
        e.preventDefault();
        const tagArray = formData.tags
            .split(' ')
            .filter(tag => tag.length > 0)
            .map(tag => tag.toLowerCase());
        const selectedVibe = vibes === null || vibes === void 0 ? void 0 : vibes.find(v => v.uri === formData.vibeUri);
        try {
            yield createBlip.mutateAsync({
                title: formData.title,
                url: formData.url || undefined,
                body: formData.body || undefined,
                tags: tagArray,
                vibe: selectedVibe ? {
                    uri: selectedVibe.uri,
                    cid: selectedVibe.cid,
                    name: selectedVibe.name,
                } : undefined,
            });
            navigate('/');
        }
        catch (error) {
            console.error('Failed to create blip:', error);
        }
    });
    return (<>
      <h2 className="page-title">transmit a new blip</h2>
      
      <form onSubmit={handleSubmit} className="submit-form">
        <div className="form-group">
          <label htmlFor="title">signal</label>
          <input type="text" id="title" name="title" required placeholder="What's on the radar?" value={formData.title} onChange={(e) => setFormData(Object.assign(Object.assign({}, formData), { title: e.target.value }))}/>
        </div>

        <div className="form-group">
          <label htmlFor="url">frequency (optional)</label>
          <input type="url" id="url" name="url" placeholder="https://..." value={formData.url} onChange={(e) => setFormData(Object.assign(Object.assign({}, formData), { url: e.target.value }))}/>
          <div className="form-note">link to external content</div>
        </div>

        <div className="form-group">
          <label htmlFor="body">transmission details (optional)</label>
          <textarea id="body" name="body" placeholder="Additional context or thoughts..." value={formData.body} onChange={(e) => setFormData(Object.assign(Object.assign({}, formData), { body: e.target.value }))}/>
        </div>

        <div className="form-group">
          <label htmlFor="vibe">vibe</label>
          <select id="vibe" name="vibe" value={formData.vibeUri} onChange={(e) => setFormData(Object.assign(Object.assign({}, formData), { vibeUri: e.target.value }))} className="vibe-select">
            <option value="">-- choose a vibe --</option>
            {vibes === null || vibes === void 0 ? void 0 : vibes.map(vibe => (<option key={vibe.uri} value={vibe.uri}>
                {vibe.emoji} {vibe.name} - {vibe.mood}
              </option>))}
          </select>
          <div className="form-note">select the mood for your blip</div>
        </div>

        <div className="form-group">
          <label htmlFor="tags">tags</label>
          <input type="text" id="tags" name="tags" placeholder="space separated tags" value={formData.tags} onChange={(e) => setFormData(Object.assign(Object.assign({}, formData), { tags: e.target.value }))}/>
          <div className="form-note">e.g., programming atproto bluesky</div>
        </div>

        {createBlip.isError && (<div className="error-message">Failed to transmit blip</div>)}

        <button type="submit" className="submit-button" disabled={createBlip.isPending}>
          {createBlip.isPending ? 'transmitting...' : 'transmit blip'}
        </button>
      </form>
    </>);
}
