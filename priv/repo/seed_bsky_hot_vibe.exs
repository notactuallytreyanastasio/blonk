# Seed script for "bsky_hot" vibe - auto-populated with trending content
import Ecto.Query
alias ElixirBlonk.{Repo, Vibes}
alias ElixirBlonk.Vibes.Vibe

# Create the "bsky_hot" vibe if it doesn't exist
case Repo.get_by(Vibe, name: "bsky_hot") do
  nil ->
    {:ok, vibe} = Vibes.create_vibe(%{
      uri: "at://blonk.app/vibe/bsky_hot",
      cid: "bafyrei#{:crypto.strong_rand_bytes(32) |> Base.encode32(case: :lower, padding: false)}",
      creator_did: "did:plc:system",
      name: "bsky_hot",
      mood: "trending links from across bluesky - the pulse of what's happening",
      emoji: "🔥",
      color: "#FF4444",
      member_count: 0,
      pulse_score: 10.0,  # High pulse score to keep it at the top
      is_emerging: false
    })
    IO.puts "✅ Created bsky_hot vibe: #{vibe.name}"
  
  existing_vibe -> 
    IO.puts "✅ bsky_hot vibe already exists: #{existing_vibe.name}"
end

IO.puts "🔥 bsky_hot vibe ready for auto-population with trending content!"