# Test script to verify the reply count API works
alias ElixirBlonk.ATProto.{Client, SessionManager}

# Test with a sample post URI (this won't exist, but we can test the API call structure)
test_post_uri = "at://did:plc:test123/app.bsky.feed.post/test123"

IO.puts "Testing reply count API with URI: #{test_post_uri}"

case SessionManager.get_client() do
  {:ok, client} ->
    IO.puts "✅ Got ATProto client successfully"
    
    case Client.get_post_engagement(client, test_post_uri) do
      {:ok, %{reply_count: count}} ->
        IO.puts "✅ Reply count: #{count}"
      
      {:error, reason} ->
        IO.puts "⚠️  Expected error (testing with fake URI): #{inspect(reason)}"
    end
  
  {:error, reason} ->
    IO.puts "❌ Failed to get ATProto client: #{inspect(reason)}"
end

IO.puts "🔍 Reply count API test complete!"