# Script for populating the database. You can run it as:
#
#     mix run priv/repo/seeds.exs
#
# Inside the script, you can read and write to any of your
# repositories directly:
#
#     ElixirBlonk.Repo.insert!(%ElixirBlonk.SomeSchema{})
#
# We recommend using the bang functions (`insert!`, `update!`
# and so on) as they will fail if something goes wrong.

alias ElixirBlonk.{Repo, Vibes, Blips, Grooves}

# Create the default elixirlang vibe
{:ok, elixir_vibe} = Vibes.create_vibe(%{
  uri: "at://blonk.app/vibe/elixirlang",
  cid: "bafyrei#{:crypto.strong_rand_bytes(32) |> Base.encode32(case: :lower, padding: false)}",
  creator_did: "did:plc:blonk",
  name: "elixirlang",
  mood: "building amazing things with elixir",
  emoji: "💜",
  color: "#6B46C1",
  member_count: 250,
  pulse_score: 10.0
})

# Create some vibes
{:ok, sunset_vibe} = Vibes.create_vibe(%{
  uri: "at://blonk.app/vibe/sunset_sunglasses_struts",
  cid: "bafyrei#{:crypto.strong_rand_bytes(32) |> Base.encode32(case: :lower, padding: false)}",
  creator_did: "did:plc:creator1",
  name: "sunset_sunglasses_struts",
  mood: "walking into the sunset with sunglasses on",
  emoji: "😎",
  color: "#FF6B6B",
  member_count: 42,
  pulse_score: 8.5
})

{:ok, lofi_vibe} = Vibes.create_vibe(%{
  uri: "at://blonk.app/vibe/lofi_bedroom_producer",
  cid: "bafyrei#{:crypto.strong_rand_bytes(32) |> Base.encode32(case: :lower, padding: false)}",
  creator_did: "did:plc:creator2",
  name: "lofi_bedroom_producer",
  mood: "making beats at 3am",
  emoji: "🎧",
  color: "#4ECDC4",
  member_count: 89,
  pulse_score: 7.2
})

{:ok, coffee_vibe} = Vibes.create_vibe(%{
  uri: "at://blonk.app/vibe/third_wave_coffee_thoughts",
  cid: "bafyrei#{:crypto.strong_rand_bytes(32) |> Base.encode32(case: :lower, padding: false)}",
  creator_did: "did:plc:creator3",
  name: "third_wave_coffee_thoughts",
  mood: "contemplating life over a pour-over",
  emoji: "☕",
  color: "#6C5CE7",
  member_count: 156,
  pulse_score: 9.1
})

# Create some blips
{:ok, elixir_blip} = Blips.create_blip(%{
  uri: "at://blonk.app/blip/elixir1",
  cid: "bafyrei#{:crypto.strong_rand_bytes(32) |> Base.encode32(case: :lower, padding: false)}",
  author_did: "did:plc:author1",
  title: "Phoenix LiveView is incredible",
  body: "Just built a real-time collaborative editor in 50 lines of code. The DX is unmatched!",
  tags: ["elixir", "phoenix", "liveview"],
  vibe_uri: elixir_vibe.uri,
  vibe_id: elixir_vibe.id,
  indexed_at: DateTime.utc_now()
})

{:ok, blip1} = Blips.create_blip(%{
  uri: "at://blonk.app/blip/blip1",
  cid: "bafyrei#{:crypto.strong_rand_bytes(32) |> Base.encode32(case: :lower, padding: false)}",
  author_did: "did:plc:author1",
  title: "just discovered the perfect golden hour spot",
  body: "there's this rooftop parking garage downtown that hits different at 6pm. bringing the camera tomorrow",
  tags: ["photography", "goldenhour", "urban"],
  vibe_uri: sunset_vibe.uri,
  vibe_id: sunset_vibe.id,
  indexed_at: DateTime.utc_now()
})

{:ok, blip2} = Blips.create_blip(%{
  uri: "at://blonk.app/blip/blip2",
  cid: "bafyrei#{:crypto.strong_rand_bytes(32) |> Base.encode32(case: :lower, padding: false)}",
  author_did: "did:plc:author2",
  title: "new track: 'midnight loops'",
  body: "made this while it was raining. free download, no strings",
  url: "https://soundcloud.com/example/midnight-loops",
  tags: ["music", "lofi", "free"],
  vibe_uri: lofi_vibe.uri,
  vibe_id: lofi_vibe.id,
  indexed_at: DateTime.utc_now()
})

{:ok, blip3} = Blips.create_blip(%{
  uri: "at://blonk.app/blip/blip3",
  cid: "bafyrei#{:crypto.strong_rand_bytes(32) |> Base.encode32(case: :lower, padding: false)}",
  author_did: "did:plc:author3",
  title: "the barista remembered my order today",
  body: "small victories. also they're using a new ethiopian single origin that's absolutely singing",
  tags: ["coffee", "smallwins"],
  vibe_uri: coffee_vibe.uri,
  vibe_id: coffee_vibe.id,
  indexed_at: DateTime.utc_now()
})

{:ok, blip4} = Blips.create_blip(%{
  uri: "at://blonk.app/blip/blip4",
  cid: "bafyrei#{:crypto.strong_rand_bytes(32) |> Base.encode32(case: :lower, padding: false)}",
  author_did: "did:plc:author1",
  title: "building a personal atproto app",
  body: "it's called blonk. radar for your web. still figuring out what that means",
  url: "https://github.com/example/blonk",
  tags: ["coding", "atproto", "opensource"],
  indexed_at: DateTime.utc_now()
})

# Add some grooves
{:ok, _} = Grooves.create_groove(%{
  uri: "at://blonk.app/groove/groove1",
  cid: "bafyrei#{:crypto.strong_rand_bytes(32) |> Base.encode32(case: :lower, padding: false)}",
  author_did: "did:plc:user1",
  subject_uri: blip1.uri,
  groove_type: "looks_good",
  blip_id: blip1.id
})

{:ok, _} = Grooves.create_groove(%{
  uri: "at://blonk.app/groove/groove2",
  cid: "bafyrei#{:crypto.strong_rand_bytes(32) |> Base.encode32(case: :lower, padding: false)}",
  author_did: "did:plc:user2",
  subject_uri: blip2.uri,
  groove_type: "shit_rips",
  blip_id: blip2.id
})

{:ok, _} = Grooves.create_groove(%{
  uri: "at://blonk.app/groove/groove3",
  cid: "bafyrei#{:crypto.strong_rand_bytes(32) |> Base.encode32(case: :lower, padding: false)}",
  author_did: "did:plc:user3",
  subject_uri: blip2.uri,
  groove_type: "shit_rips",
  blip_id: blip2.id
})

# Add some vibe mentions to simulate emerging vibes
{:ok, _} = Vibes.record_vibe_mention(%{
  vibe_name: "midnight_city_walks",
  author_did: "did:plc:user1",
  post_uri: "at://did:plc:user1/app.bsky.feed.post/abc123",
  mentioned_at: DateTime.utc_now()
})

{:ok, _} = Vibes.record_vibe_mention(%{
  vibe_name: "midnight_city_walks",
  author_did: "did:plc:user2",
  post_uri: "at://did:plc:user2/app.bsky.feed.post/def456",
  mentioned_at: DateTime.utc_now()
})

{:ok, _} = Vibes.record_vibe_mention(%{
  vibe_name: "analog_photography",
  author_did: "did:plc:user3",
  post_uri: "at://did:plc:user3/app.bsky.feed.post/ghi789",
  mentioned_at: DateTime.utc_now()
})

IO.puts("Seeds created successfully!")
