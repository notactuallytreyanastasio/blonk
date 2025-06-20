defmodule ElixirBlonk.Grooves.Groove do
  @moduledoc """
  Represents community engagement on blips in the Blonk ecosystem.
  
  Grooves are the fundamental feedback mechanism that drives content curation
  and community engagement. Each groove represents a user's reaction to a
  specific blip, creating the social signal that powers Blonk's trending
  algorithms and community-driven content discovery.
  
  ## Blip-Groove Relationship
  
  **Every groove is tightly coupled to a specific blip:**
  - `blip_id` - Database foreign key to the blip being grooved
  - `subject_uri` - ATProto URI of the blip for cross-platform reference
  - `belongs_to :blip` - Ecto association for database queries
  - Cascade deletion when blip is removed
  
  ## ATProto Integration
  
  **Grooves become `com.blonk.groove` ATProto records:**
  - `uri` - ATProto record URI for the groove
  - `cid` - Content identifier for the groove record
  - `blip` reference in ATProto record links to the grooved blip
  - Enables cross-platform groove discovery and portability
  
  ## Community Engagement Types
  
  - **looks_good** (👍) - Positive community endorsement
  - **shit_rips** - Critical community feedback
  
  ## Schema Fields
  
  - `uri` - ATProto record URI (e.g., "at://did:plc:user/com.blonk.groove/rkey")
  - `cid` - Content identifier for ATProto record
  - `author_did` - DID of user who created this groove
  - `subject_uri` - ATProto URI of the blip being grooved
  - `groove_type` - Either "looks_good" or "shit_rips"
  - `blip_id` - Foreign key to the grooved blip
  
  ## Examples
  
      # Groove on a blip
      %Groove{
        author_did: "did:plc:user123",
        groove_type: "looks_good",
        subject_uri: "at://did:plc:author/com.blonk.blip/tech-news",
        blip_id: tech_blip.id
      }
  """
  
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "grooves" do
    field :uri, :string
    field :cid, :string
    field :author_did, :string
    field :subject_uri, :string
    field :groove_type, :string

    belongs_to :blip, ElixirBlonk.Blips.Blip

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(groove, attrs) do
    groove
    |> cast(attrs, [:uri, :cid, :author_did, :subject_uri, :groove_type, :blip_id])
    |> validate_required([:uri, :cid, :author_did, :subject_uri, :groove_type])
    |> validate_inclusion(:groove_type, ["looks_good", "shit_rips"])
    |> unique_constraint([:author_did, :subject_uri])
  end
end