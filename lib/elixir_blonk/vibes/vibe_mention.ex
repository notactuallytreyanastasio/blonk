defmodule ElixirBlonk.Vibes.VibeMention do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "vibe_mentions" do
    field :vibe_name, :string
    field :author_did, :string
    field :post_uri, :string
    field :mentioned_at, :utc_datetime

    belongs_to :vibe, ElixirBlonk.Vibes.Vibe

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(vibe_mention, attrs) do
    vibe_mention
    |> cast(attrs, [:vibe_name, :author_did, :post_uri, :mentioned_at, :vibe_id])
    |> validate_required([:vibe_name, :author_did, :post_uri, :mentioned_at])
  end
end