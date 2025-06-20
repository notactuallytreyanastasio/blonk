defmodule ElixirBlonk.HotPosts.HotPost do
  @moduledoc """
  Represents a potential trending post from the Bluesky firehose awaiting engagement analysis.
  
  HotPost records are created by the firehose consumer when it samples posts with external
  links. These posts are then analyzed by the HotPostSweeper to determine if they have
  enough community engagement (replies) to become blips in the bsky_hot vibe.
  
  ## Blonk Integration
  
  **Hot Posts seed community engagement** by:
  - Monitoring Bluesky firehose for content with links
  - Sampling 1 in 10 posts to avoid overwhelming the system
  - Time-delayed engagement checking (posts need time to get replies)
  - Auto-converting trending content into blips for community grooves
  
  ## Lifecycle in Community Bootstrap
  
  1. **Capture**: Firehose consumer saves posts with links from Bluesky
  2. **Patience**: Posts wait for time delay to allow replies to accumulate
  3. **Analysis**: HotPostSweeper checks reply counts via ATProto API
  4. **Conversion**: Posts with ≥5 replies become blips in bsky_hot vibe
  5. **Cleanup**: Old or fully-processed posts are removed automatically
  
  ## Why This Matters for Blonk
  
  The hot posts system **bootstraps community engagement** by:
  - Seeding the radar with trending external content
  - Providing initial blips for users to groove on
  - Creating conversation starters across vibes
  - Attracting users through quality content discovery
  
  ## Schema Fields
  
  - `post_uri` - ATProto URI of the original Bluesky post
  - `author_did` - DID of the original post author
  - `text` - Post content/body text
  - `external_url` - The external link that made this post interesting
  - `record_data` - Full ATProto record for reference
  - `check_count` - How many times we've checked this post for replies
  - `reply_count` - Current number of replies from last check
  - `converted_to_blip` - Whether this became a blip in bsky_hot vibe
  - `last_checked_at` - When we last analyzed engagement
  
  ## Examples
  
      # A hot post awaiting analysis
      %HotPost{
        post_uri: "at://did:plc:user/app.bsky.feed.post/rkey",
        text: "Check out this amazing new protocol...",
        external_url: "https://protocol.xyz/announcement",
        check_count: 2,
        reply_count: 7,  # Above threshold!
        converted_to_blip: false  # Ready for conversion
      }
  """
  
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "hot_posts" do
    field :post_uri, :string
    field :author_did, :string
    field :text, :string
    field :external_url, :string
    field :record_data, :map  # Store the full ATProto record
    field :check_count, :integer, default: 0
    field :reply_count, :integer, default: 0
    field :converted_to_blip, :boolean, default: false
    field :last_checked_at, :utc_datetime

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(hot_post, attrs) do
    hot_post
    |> cast(attrs, [
      :post_uri, :author_did, :text, :external_url, :record_data,
      :check_count, :reply_count, :converted_to_blip, :last_checked_at
    ])
    |> validate_required([:post_uri, :author_did])
    |> unique_constraint(:post_uri)
  end

  @doc false
  def update_changeset(hot_post, attrs) do
    hot_post
    |> cast(attrs, [:check_count, :reply_count, :converted_to_blip, :last_checked_at])
  end
end