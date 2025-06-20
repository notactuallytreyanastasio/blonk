# Blonk 🎯

**A place to find blips on the radar of your web, with a focus on vibes.**

Blonk is a community-driven content discovery platform built on ATProto that enables organic topic communities to form around "vibes" - interest-based feeds where users submit "blips" (content) to get "grooves" (community engagement).

## 🌟 Core Concepts

### The Blonk Ecosystem

**🎯 Radar** - The frontpage that surfaces trending content across all vibes  
**🌊 Vibes** - Topic-based communities created by community action (#vibe-your_topic)  
**📡 Blips** - Content submissions to vibes that appear on the radar  
**🎵 Grooves** - Community engagement: `looks_good` or `shit_rips`  
**🏷️ Tags** - Universal labels that connect content across vibes  

### How It Works

1. **Vibe Creation**: Communities emerge when `#vibe-topic_name` reaches critical mass
2. **Content Submission**: Users submit blips to vibes with tags for categorization  
3. **Community Engagement**: Others groove on blips, driving popularity
4. **Radar Discovery**: Trending tagged content surfaces on the frontpage
5. **Organic Growth**: Popular content attracts more users to related vibes

### Community Seeding

- **🔥 Hot Posts**: AI monitors the Bluesky firehose for trending content (>5 replies)
- **Auto-Population**: Trending external content auto-populates the `bsky_hot` vibe
- **Community Bootstrap**: Seeds engagement to kickstart organic community growth

## 🏗️ Architecture

### ATProto-Native

Blonk is built as a first-class ATProto application with custom record types:

- `com.blonk.vibe` - Community topic feeds
- `com.blonk.blip` - Content submissions  
- `com.blonk.groove` - Community engagement
- `com.blonk.tag` - Universal content labels
- `com.blonk.blipTag` - Content categorization associations

### Technology Stack

- **Backend**: Elixir/Phoenix LiveView
- **Database**: PostgreSQL with ATProto record sync
- **Real-time**: WebSocket firehose integration with Bluesky
- **Authentication**: ATProto app passwords
- **Deployment**: Docker-ready

## 🚀 Getting Started

### Prerequisites

- Elixir 1.18+
- PostgreSQL 14+
- Bluesky account with app password

### Installation

```bash
# Clone the repository
git clone https://github.com/your-org/elixir_blonk.git
cd elixir_blonk

# Install dependencies
mix deps.get

# Set up environment
cp .env.example .env
# Edit .env with your Bluesky credentials

# Set up database
mix ecto.setup

# Start the server
source .env && mix phx.server
```

### Environment Configuration

```bash
# .env
export ATP_SERVICE=https://bsky.social
export ATP_IDENTIFIER=your-handle.bsky.social
export ATP_PASSWORD=your-app-password
```

## 🎮 Usage

### Creating Vibes

Post `#vibe-topic_name` to create new community vibes:

```
Check out this cool #vibe-blockchain project! #defi #web3
```

Once enough community members use `#vibe-blockchain`, it becomes an official vibe.

### Submitting Blips

Submit content to vibes with relevant tags:

```
Title: "New DeFi Protocol Launch"
Body: "Exciting developments in yield farming..."
Vibe: blockchain_vibe
Tags: #defi #yield #ethereum
```

### Community Engagement

- **👍 looks_good** - Positive community feedback
- **💩 shit_rips** - Critical community feedback  

Grooves drive content visibility and trending algorithms.

### Discovery

- **Radar**: Trending content across all vibes
- **Vibe Pages**: Topic-specific content feeds
- **Tag Pages**: Cross-vibe content by topic
- **Hot Posts**: AI-curated trending external content

## 🏷️ Tag System

### Universal Tags

Tags are community-owned labels that enable cross-vibe discovery:

- **One Tag Per Name**: Only one `#blockchain` tag exists globally
- **Community Driven**: Anyone can use any tag
- **Usage Tracking**: Popular tags surface trending content
- **Rich Metadata**: Tags support descriptions and attribution

### Tag Lifecycle

1. **First Use**: Creates universal tag record in ATProto
2. **Association**: Links to blips via BlipTag junction records  
3. **Community Growth**: Usage count drives popularity
4. **Discovery**: Popular tags surface on radar

## 🤖 AI Integration

### Hot Post Detection

The HotPostSweeper monitors Bluesky's firehose for trending content:

- **Sampling**: 1 in 10 posts with links
- **Engagement Check**: Looks for >5 replies after time delay
- **Auto-Population**: Creates blips in `bsky_hot` vibe
- **Community Seeding**: Bootstraps engagement for organic growth

## 🎯 Community Philosophy

### Vibe-Driven Discovery

Blonk prioritizes **community vibes over algorithmic feeds**:

- Communities form organically around shared interests
- Content quality emerges through peer grooves  
- Cross-vibe discovery happens through universal tags
- Trending content reflects genuine community engagement

### Decentralized Social

Built on ATProto for true decentralization:

- **Data Portability**: Your content, your control
- **Cross-Platform**: Records work across ATProto apps
- **Community Ownership**: Vibes and tags are community resources
- **Open Protocol**: Extensible and interoperable

## 🛠️ Development

### Project Structure

```
lib/
├── elixir_blonk/           # Core business logic
│   ├── vibes/              # Community topic management
│   ├── blips/              # Content submission system
│   ├── grooves/            # Community engagement
│   ├── tags/               # Universal tag system  
│   ├── blip_tags/          # Tag associations
│   ├── hot_posts/          # AI content curation
│   ├── atproto/            # ATProto client & sync
│   └── firehose/           # Real-time data ingestion
├── elixir_blonk_web/       # Phoenix web interface
└── priv/repo/migrations/   # Database schema
```

### Key Services

- **SessionManager**: ATProto authentication & session management
- **Firehose.Consumer**: Real-time Bluesky data ingestion  
- **HotPostSweeper**: AI-driven content curation
- **ATProto.Client**: Custom record type operations

### Testing

```bash
# Run tests
mix test

# Run with coverage
mix test --cover
```

## 📈 Roadmap

### Phase 1: Community Bootstrap ✅
- [x] Basic vibe/blip/groove system
- [x] ATProto integration
- [x] Hot post AI curation
- [x] Universal tag system

### Phase 2: Enhanced Discovery
- [ ] Advanced radar algorithms  
- [ ] User following/recommendations
- [ ] Cross-vibe trending
- [ ] Mobile app

### Phase 3: Community Tools
- [ ] Vibe moderation tools
- [ ] Community governance
- [ ] Creator monetization  
- [ ] External integrations

## 🤝 Contributing

We welcome contributions! Please see [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines.

### Development Setup

1. Fork the repository
2. Create feature branch (`git checkout -b feature/amazing-feature`)
3. Commit changes (`git commit -m 'Add amazing feature'`)
4. Push to branch (`git push origin feature/amazing-feature`)
5. Open Pull Request

## 📄 License

This project is licensed under the MIT License - see [LICENSE](LICENSE) for details.

## 🙏 Acknowledgments

- **ATProto Team** - For the decentralized social protocol
- **Bluesky** - For the firehose API and ecosystem
- **Phoenix/Elixir** - For the robust web framework
- **Community** - For making vibes happen

---

**Ready to find your vibe?** 🌊

Start exploring at [blonk.app](https://blonk.app) or run your own instance!