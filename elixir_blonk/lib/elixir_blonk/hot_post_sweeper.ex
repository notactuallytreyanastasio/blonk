defmodule ElixirBlonk.HotPostSweeper do
  @moduledoc """
  GenServer that periodically sweeps hot posts to check for engagement
  and creates blips for trending content.
  """

  use GenServer
  require Logger

  alias ElixirBlonk.{HotPosts, Vibes, Blips}
  alias ElixirBlonk.ATProto.{Client, SessionManager}

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
    case SessionManager.get_client() do
      {:ok, client} ->
        client_map = %{client: client}
        case Client.get_post_engagement(client_map, post_uri) do
          {:ok, %{reply_count: count}} -> {:ok, count}
          {:error, reason} -> {:error, reason}
        end
      
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