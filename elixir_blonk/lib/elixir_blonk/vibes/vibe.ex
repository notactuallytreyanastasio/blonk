defmodule ElixirBlonk.Vibes.Vibe do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "vibes" do
    field :uri, :string
    field :cid, :string
    field :creator_did, :string
    field :name, :string
    field :mood, :string
    field :emoji, :string
    field :color, :string
    field :member_count, :integer, default: 0
    field :pulse_score, :float, default: 0.0
    field :is_emerging, :boolean, default: false

    has_many :blips, ElixirBlonk.Blips.Blip
    has_many :vibe_members, ElixirBlonk.Vibes.VibeMember
    has_many :vibe_mentions, ElixirBlonk.Vibes.VibeMention

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(vibe, attrs) do
    vibe
    |> cast(attrs, [:uri, :cid, :creator_did, :name, :mood, :emoji, :color, :member_count, :pulse_score, :is_emerging])
    |> validate_required([:uri, :cid, :creator_did, :name, :mood])
    |> unique_constraint(:uri)
    |> unique_constraint(:name)
  end
end