defmodule ElixirBlonk.HotPostSweeper do
  @moduledoc """
  AI-powered content curation service that transforms trending Bluesky posts into Blonk blips.
  
  The HotPostSweeper is the heart of Blonk's community bootstrap strategy, running every
  10 minutes to analyze engagement on posts captured from the firehose and converting
  highly-engaged content into blips that seed community activity.
  
  ## Core Mission
  
  **Solve the cold start problem** by ensuring there's always engaging content on the radar:
  - Continuously analyze posts captured from Bluesky firehose
  - Check reply counts to gauge community interest
  - Convert trending content into blips for the bsky_hot vibe
  - Maintain system performance through intelligent cleanup
  
  ## Why Every 10 Minutes?
  
  - **Fresh Content**: Recent posts need time to accumulate replies
  - **System Performance**: Avoid overwhelming ATProto APIs with constant requests
  - **Quality Control**: Allows natural filtering - truly engaging content rises
  - **Community Timing**: Balances freshness with engagement validation
  
  ## Integration with Blonk Ecosystem
  
  - **Firehose Consumer**: Receives posts to analyze from real-time capture
  - **ATProto API**: Checks reply counts via authenticated Bluesky calls
  - **bsky_hot Vibe**: Creates blips for trending content in this community space
  - **Radar**: Newly created blips surface on the frontpage for community grooves
  - **HotPosts Context**: Manages the lifecycle of potential trending content
  
  ## AI Curation Logic
  
  1. **Batch Processing**: Analyzes up to 25 posts per sweep for efficiency
  2. **Engagement Threshold**: Posts with ≥5 replies qualify as "hot"
  3. **Retry Logic**: Failed API calls don't block other posts from processing
  4. **Smart Cleanup**: Removes posts >1 day old or checked >10 times
  5. **Conversion Tracking**: Prevents duplicate blips from same hot post
  
  ## Community Impact
  
  The sweeper creates a **virtuous cycle of engagement**:
  - Quality external content attracts users to Blonk
  - Users groove on hot blips, increasing visibility
  - Popular topics inspire organic vibe creation
  - Growing community activity attracts more users
  
  ## Performance Characteristics
  
  - **Non-blocking**: Runs in background without affecting user experience
  - **Error Recovery**: Individual post failures don't crash the system
  - **Rate Limited**: Respects ATProto API limits through batching
  - **Self-cleaning**: Automatically maintains database efficiency
  
  ## Examples
  
      # Sweeper finds a trending crypto post
      hot_post = %HotPost{
        text: "New DeFi protocol just launched...",
        external_url: "https://protocol.xyz",
        reply_count: 12  # Above threshold!
      }
      
      # Creates blip in bsky_hot vibe
      # → Surfaces on radar
      # → Users groove on it
      # → Drives more engagement
  """

  use GenServer
  require Logger

  alias ElixirBlonk.{HotPosts, Vibes, Blips}

  # Check every 10 minutes
  @sweep_interval_ms 10 * 60 * 1000

  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @impl true
  def init(_opts) do
    Logger.info("Starting HotPostSweeper - checking posts every 10 minutes")
    
    # Schedule the first sweep
    schedule_sweep()
    
    {:ok, %{}}
  end

  @impl true
  def handle_info(:sweep, state) do
    Logger.info("Starting hot post sweep")
    
    try do
      # Get posts to check (up to 25)
      posts_to_check = HotPosts.get_posts_for_checking(25)
      Logger.info("Found #{length(posts_to_check)} posts to check for replies")
      
      # Check each post for replies
      Enum.each(posts_to_check, &check_post_replies/1)
      
      # Clean up old posts
      cleanup_count = HotPosts.cleanup_old_posts()
      if cleanup_count > 0 do
        Logger.info("Cleaned up #{cleanup_count} old hot posts")
      end
      
      # Create blips for trending posts
      create_blips_for_trending()
      
    rescue
      error ->
        Logger.error("Error in hot post sweep: #{inspect(error)}")
    end
    
    # Schedule next sweep
    schedule_sweep()
    
    {:noreply, state}
  end

  defp schedule_sweep do
    Process.send_after(self(), :sweep, @sweep_interval_ms)
  end

  defp check_post_replies(hot_post) do
    Logger.debug("Checking replies for post: #{hot_post.post_uri}")
    
    case get_post_reply_count(hot_post.post_uri) do
      {:ok, reply_count} ->
        Logger.debug("Post #{hot_post.post_uri} has #{reply_count} replies")
        HotPosts.update_hot_post_check(hot_post, reply_count)
      
      {:error, reason} ->
        Logger.warning("Failed to check replies for #{hot_post.post_uri}: #{inspect(reason)}")
        # Still increment check count even if API failed
        HotPosts.update_hot_post_check(hot_post, hot_post.reply_count)
    end
  end

  defp get_post_reply_count(post_uri) do
    case ElixirBlonk.ATProto.SimpleSession.get_client() do
      {:ok, client} ->
        ElixirBlonk.ATProto.get_post_engagement(client, post_uri)
      
      {:error, reason} ->
        {:error, reason}
    end
  end

  defp create_blips_for_trending do
    trending_posts = HotPosts.get_trending_posts(5)
    
    if length(trending_posts) > 0 do
      Logger.info("Found #{length(trending_posts)} trending posts to convert to blips")
    end
    
    Enum.each(trending_posts, &create_blip_from_hot_post/1)
  end

  defp create_blip_from_hot_post(hot_post) do
    case Vibes.get_vibe_by_name("bsky_hot") do
      nil ->
        Logger.error("bsky_hot vibe not found - cannot create hot blip")
      
      bsky_hot_vibe ->
        blip_params = %{
          uri: "at://blonk.app/blip/#{Ecto.UUID.generate()}",
          cid: "bafyrei#{:crypto.strong_rand_bytes(32) |> Base.encode32(case: :lower, padding: false)}",
          author_did: hot_post.author_did,
          title: truncate_text(hot_post.text || "", 100),
          body: hot_post.text || "",
          url: hot_post.external_url || hot_post.post_uri,
          tags: ["trending", "hot", "bsky"],
          vibe_id: bsky_hot_vibe.id,
          vibe_uri: bsky_hot_vibe.uri,
          grooves_looks_good: 0,
          grooves_shit_rips: 0,
          indexed_at: DateTime.utc_now()
        }
        
        case Blips.create_blip(blip_params) do
          {:ok, blip} ->
            Logger.info("Created hot blip: #{String.slice(blip.title, 0, 50)}... (#{hot_post.reply_count} replies)")
            HotPosts.mark_as_converted(hot_post)
          
          {:error, reason} ->
            Logger.error("Failed to create hot blip: #{inspect(reason)}")
        end
    end
  end

  defp truncate_text(text, max_length) when byte_size(text) <= max_length, do: text
  defp truncate_text(text, max_length), do: String.slice(text, 0, max_length) <> "..."
end