defmodule ElixirBlonk.Vibes.VibeMember do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "vibe_members" do
    field :uri, :string
    field :cid, :string
    field :member_did, :string
    field :vibe_uri, :string

    belongs_to :vibe, ElixirBlonk.Vibes.Vibe

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(vibe_member, attrs) do
    vibe_member
    |> cast(attrs, [:uri, :cid, :member_did, :vibe_uri, :vibe_id])
    |> validate_required([:uri, :cid, :member_did, :vibe_uri])
    |> unique_constraint([:member_did, :vibe_uri])
  end
end