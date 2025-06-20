defmodule ElixirBlonk.HotPosts do
  @moduledoc """
  The HotPosts context for managing AI-driven content curation in the Blonk ecosystem.
  
  This context orchestrates the discovery and analysis of trending content from the
  Bluesky firehose, providing the community bootstrap mechanism that seeds engagement
  and attracts users to the platform.
  
  ## Core Purpose in Blonk
  
  **HotPosts solve the cold start problem** for community platforms by:
  - Automatically discovering trending external content
  - Analyzing community engagement through reply counts
  - Converting popular content into blips for community grooves
  - Seeding the radar with quality content to drive initial engagement
  
  ## Integration with Blonk Ecosystem
  
  - **Firehose**: Captures posts with links from Bluesky's real-time feed
  - **bsky_hot Vibe**: Auto-populated community space for trending content
  - **Radar**: Hot blips surface on the frontpage across all vibes
  - **Grooves**: Community engagement on converted content drives visibility
  - **AI Curation**: Algorithmic filtering ensures quality over quantity
  
  ## Community Bootstrap Strategy
  
  1. **Content Discovery**: Monitor Bluesky firehose for posts with external links
  2. **Smart Sampling**: Take 1 in 10 posts to avoid overwhelming the system
  3. **Time-Delayed Analysis**: Wait for posts to accumulate replies naturally
  4. **Engagement Threshold**: Convert posts with ≥5 replies to community blips
  5. **Automatic Cleanup**: Remove old/processed posts to maintain performance
  
  ## Why This Matters
  
  Without hot posts, Blonk would face the **empty restaurant problem**:
  - No content → no users → no engagement → no growth
  - Hot posts create the initial activity that attracts real community
  - Quality external content gives users something to groove on immediately
  - Trending topics seed organic vibe creation and community formation
  
  ## Lifecycle Management
  
  **Capture Phase**: Firehose consumer saves promising posts
  **Analysis Phase**: HotPostSweeper checks engagement metrics  
  **Conversion Phase**: Popular posts become blips in bsky_hot vibe
  **Cleanup Phase**: Old/processed posts are automatically removed
  
  ## Examples
  
      # Find posts ready for engagement analysis
      posts_to_check = HotPosts.get_posts_for_checking(25)
      
      # Convert highly-engaged posts to community blips
      trending_posts = HotPosts.get_trending_posts(5)
      
      # Cleanup old posts to maintain performance
      cleanup_count = HotPosts.cleanup_old_posts()
  """

  import Ecto.Query, warn: false
  alias ElixirBlonk.Repo
  alias ElixirBlonk.HotPosts.HotPost

  @doc """
  Creates a hot post record for later processing.
  """
  def create_hot_post(attrs \\ %{}) do
    %HotPost{}
    |> HotPost.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Gets posts ready for reply checking.
  Returns up to `limit` posts that haven't been checked too many times.
  """
  def get_posts_for_checking(limit \\ 25) do
    HotPost
    |> where([h], h.check_count < 10)
    |> where([h], h.inserted_at > ago(1, "day"))
    |> order_by([h], asc: h.inserted_at)
    |> limit(^limit)
    |> Repo.all()
  end

  @doc """
  Updates the check count and reply count for a hot post.
  """
  def update_hot_post_check(hot_post, reply_count) do
    hot_post
    |> HotPost.update_changeset(%{
      check_count: hot_post.check_count + 1,
      reply_count: reply_count,
      last_checked_at: DateTime.utc_now()
    })
    |> Repo.update()
  end

  @doc """
  Deletes old or fully processed hot posts.
  """
  def cleanup_old_posts do
    # Delete posts older than 1 day OR that have been checked 10 times
    {count, _} = 
      HotPost
      |> where([h], h.inserted_at < ago(1, "day") or h.check_count >= 10)
      |> Repo.delete_all()
    
    count
  end

  @doc """
  Gets all hot posts with high reply counts that haven't been converted to blips yet.
  """
  def get_trending_posts(min_replies \\ 5) do
    HotPost
    |> where([h], h.reply_count >= ^min_replies)
    |> where([h], not h.converted_to_blip)
    |> Repo.all()
  end

  @doc """
  Marks a hot post as converted to a blip.
  """
  def mark_as_converted(hot_post) do
    hot_post
    |> HotPost.update_changeset(%{converted_to_blip: true})
    |> Repo.update()
  end
end