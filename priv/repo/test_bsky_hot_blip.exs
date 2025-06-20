# Test script to create a sample blip in bsky_hot vibe
alias ElixirBlonk.{Repo, Vibes, Blips}

# Find the bsky_hot vibe
case Vibes.get_vibe_by_name("bsky_hot") do
  nil ->
    IO.puts "❌ bsky_hot vibe not found - run the seed script first"
  
  bsky_hot_vibe ->
    # Create a test blip
    blip_params = %{
      uri: "at://blonk.app/blip/#{Ecto.UUID.generate()}",
      cid: "bafyrei#{:crypto.strong_rand_bytes(32) |> Base.encode32(case: :lower, padding: false)}",
      author_did: "did:plc:test123",
      title: "Test trending content from Bluesky firehose",
      body: "This is a test blip to verify the bsky_hot content system works. Check out this cool link: https://example.com",
      url: "https://example.com",
      tags: ["trending", "hot", "bsky", "test"],
      vibe_id: bsky_hot_vibe.id,
      vibe_uri: bsky_hot_vibe.uri,
      grooves_looks_good: 8,
      grooves_shit_rips: 3,
      indexed_at: DateTime.utc_now()
    }
    
    case Blips.create_blip(blip_params) do
      {:ok, blip} ->
        IO.puts "✅ Created test blip in bsky_hot: #{blip.title}"
      {:error, reason} ->
        IO.puts "❌ Failed to create test blip: #{inspect(reason)}"
    end
end

IO.puts "🔥 bsky_hot system test complete!"