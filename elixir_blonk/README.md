# Blonk - Phoenix LiveView Edition

This is a Phoenix LiveView port of the Blonk TypeScript application - a reddit-like ATProto application with "vibes" instead of subreddits.

## Current Implementation Status

### ✅ Completed
- Database schemas for blips, vibes, grooves, vibe_members, vibe_mentions, and comments
- Core business logic contexts (Blips, Vibes, Grooves)
- LiveView components for:
  - Blip list with real-time updates
  - Blip creation form
  - Vibe list and emerging vibes
  - Vibe detail pages
  - Tag browsing
- Groove (voting) system with "looks_good" and "shit_rips" reactions
- Real-time updates via Phoenix PubSub
- Basic navigation and routing
- Seed data for testing

### 🚧 Not Yet Implemented
- ATProto/Bluesky integration (stopped before firehose as requested)
- User authentication (currently using placeholder DIDs)
- Search monitor for vibe hashtags
- Pulse score calculations
- Full styling to match the minimalist radar theme

## Getting Started

To start your Phoenix server:

  * Run `mix setup` to install and setup dependencies
  * Start Phoenix endpoint with `mix phx.server` or inside IEx with `iex -S mix phx.server`

Now you can visit [`localhost:4000`](http://localhost:4000) from your browser.

## Key Features

- **Blips**: Posts with title, optional body/URL, tags, and vibe association
- **Vibes**: Mood-based communities (not topics) like "sunset_sunglasses_struts"
- **Grooves**: Two types of reactions - "looks_good" and "shit_rips"
- **Emerging Vibes**: Track #vibe-* mentions to create new vibes virally
- **Real-time Updates**: LiveView provides instant updates for new blips and grooves

## Architecture

The application follows standard Phoenix patterns:
- Ecto schemas define the data models
- Context modules (Blips, Vibes, Grooves) contain business logic
- LiveView modules handle real-time UI updates
- Phoenix PubSub broadcasts changes across connected clients

## Next Steps

When you're ready to add the Bluesky firehose integration, you'll need to:
1. Create an ATProto client module
2. Implement WebSocket connection to the firehose
3. Parse CAR files and ATProto records
4. Process incoming posts for vibe mentions
5. Create records in Bluesky for blips, vibes, and grooves

## Learn more

  * Official website: https://www.phoenixframework.org/
  * Guides: https://hexdocs.pm/phoenix/overview.html
  * Docs: https://hexdocs.pm/phoenix
  * Forum: https://elixirforum.com/c/phoenix-forum
  * Source: https://github.com/phoenixframework/phoenix
