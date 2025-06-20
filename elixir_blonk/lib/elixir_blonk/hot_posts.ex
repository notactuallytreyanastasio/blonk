defmodule ElixirBlonk.HotPosts do
  @moduledoc """
  The HotPosts context for managing potential trending content.
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