defmodule ElixirBlonk.Tags.Tag do
  @moduledoc """
  Represents a universal tag in the Blonk ecosystem.
  
  Tags are community-owned labels that categorize blips across the radar.
  Unlike traditional hashtags that exist only within individual posts,
  Blonk tags are first-class ATProto records that enable rich metadata,
  community curation, and cross-platform discovery.
  
  ## Core Concepts
  
  - **Universal**: Only one tag exists per name (e.g., one `#blockchain` tag)
  - **Community-Owned**: Anyone can use any tag, promoting shared vocabulary
  - **ATProto Native**: Each tag is a `com.blonk.tag` record with URI/CID
  - **Usage Tracking**: Popular tags surface naturally through `usage_count`
  - **Rich Metadata**: Tags can have descriptions and creator attribution
  
  ## Tag Lifecycle
  
  1. **Creation**: First user to use a tag name creates the record
  2. **Association**: Users associate tags with blips via BlipTag records
  3. **Community Growth**: Usage count increases with each blip association
  4. **Discovery**: Popular tags appear in trending/suggested lists
  
  ## Examples
  
      # Create a new universal tag
      {:ok, tag} = Tags.find_or_create_tag("blockchain", "did:plc:user123", "Decentralized tech")
      
      # Anyone can use this tag
      BlipTags.associate_tags_with_blip(blip_id, ["blockchain"], user_did)
      
      # Tag popularity grows organically
      tag.usage_count # => increments with each use
  
  ## Schema Fields
  
  - `uri` - ATProto record URI (e.g., "at://did:plc:blonk/com.blonk.tag/rkey")
  - `cid` - Content identifier for the ATProto record
  - `name` - Tag name without # symbol (e.g., "blockchain")
  - `description` - Optional description of the tag's purpose
  - `author_did` - DID of the user who first created this tag (optional)
  - `usage_count` - Number of blips associated with this tag
  - `indexed_at` - When this tag was first created in Blonk
  """
  
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "tags" do
    field :uri, :string
    field :cid, :string
    field :name, :string
    field :description, :string
    field :author_did, :string
    field :usage_count, :integer, default: 0
    field :indexed_at, :utc_datetime

    many_to_many :blips, ElixirBlonk.Blips.Blip, join_through: "blip_tags"

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(tag, attrs) do
    tag
    |> cast(attrs, [:uri, :cid, :name, :description, :author_did, :usage_count, :indexed_at])
    |> validate_required([:name])
    |> validate_length(:name, min: 1, max: 50)
    |> validate_length(:description, max: 280)
    |> validate_format(:name, ~r/^[a-zA-Z0-9_]+$/, message: "can only contain letters, numbers, and underscores")
    |> unique_constraint(:uri)
    |> unique_constraint(:name, message: "tag name already exists")
  end
end