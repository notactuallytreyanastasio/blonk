defmodule ElixirBlonk.BlipTags.BlipTag do
  @moduledoc """
  Represents the association between a blip and a tag in the Blonk ecosystem.
  
  BlipTag is a junction record that creates many-to-many relationships between
  blips and universal tags. Each association is itself an ATProto record,
  enabling decentralized discovery and attribution of content categorization.
  
  ## Core Concepts
  
  - **Content Categorization**: Links specific blips to universal tags
  - **Community Attribution**: Tracks who associated a tag with a blip
  - **ATProto Native**: Each association is a `com.blonk.blipTag` record
  - **Cross-Vibe Discovery**: Enables finding related content across vibes
  - **Usage Tracking**: Drives tag popularity and trending algorithms
  
  ## Blonk Ecosystem Integration
  
  **BlipTags enable the radar to surface trending content** by connecting:
  - **Blips**: Individual content submissions to vibes
  - **Tags**: Universal community-owned labels
  - **Vibes**: Topic-based communities where blips get grooves
  - **Community**: Users who groove on tagged content
  
  ## Lifecycle in Community Engagement
  
  1. **Submission**: User submits blip to a vibe with tags
  2. **Association**: BlipTag records created for each tag
  3. **Discovery**: Other users find blip through tag searches
  4. **Grooves**: Community grooves (looks_good/shit_rips) on tagged content
  5. **Trending**: Popular tagged blips surface on the radar
  
  ## Examples
  
      # Associate a blip with multiple tags
      BlipTags.associate_tags_with_blip(blip_id, ["blockchain", "defi", "web3"], user_did)
      
      # Find all crypto-related blips across vibes
      crypto_blips = BlipTags.get_blips_for_tag(crypto_tag.id)
      
      # Remove tag association
      BlipTags.delete_blip_tag(blip_id, old_tag.id)
  
  ## Schema Fields
  
  - `uri` - ATProto record URI for this association
  - `cid` - Content identifier for the ATProto record  
  - `author_did` - DID of user who created this tag association
  - `blip_id` - Reference to the tagged blip
  - `tag_id` - Reference to the universal tag
  """
  
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "blip_tags" do
    field :uri, :string
    field :cid, :string
    field :author_did, :string

    belongs_to :blip, ElixirBlonk.Blips.Blip
    belongs_to :tag, ElixirBlonk.Tags.Tag

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(blip_tag, attrs) do
    blip_tag
    |> cast(attrs, [:uri, :cid, :author_did, :blip_id, :tag_id])
    |> validate_required([:author_did, :blip_id, :tag_id])
    |> unique_constraint(:uri)
    |> unique_constraint([:blip_id, :tag_id], message: "tag already associated with this blip")
  end
end