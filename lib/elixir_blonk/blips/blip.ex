defmodule ElixirBlonk.Blips.Blip do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "blips" do
    field :uri, :string
    field :cid, :string
    field :author_did, :string
    field :title, :string
    field :body, :string
    field :url, :string
    field :tags, {:array, :string}, default: []
    field :vibe_uri, :string
    field :grooves_looks_good, :integer, default: 0
    field :grooves_shit_rips, :integer, default: 0
    field :indexed_at, :utc_datetime

    belongs_to :vibe, ElixirBlonk.Vibes.Vibe, references: :id, foreign_key: :vibe_id
    has_many :grooves, ElixirBlonk.Grooves.Groove
    has_many :comments, ElixirBlonk.Blips.Comment

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(blip, attrs) do
    blip
    |> cast(attrs, [:uri, :cid, :author_did, :title, :body, :url, :tags, :vibe_uri, :vibe_id, :grooves_looks_good, :grooves_shit_rips, :indexed_at])
    |> validate_required([:uri, :cid, :author_did, :title])
    |> validate_length(:title, max: 280)
    |> validate_length(:body, max: 2000)
    |> unique_constraint(:uri)
  end
end