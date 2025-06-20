defmodule ElixirBlonk.Tags.Tag do
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
    |> validate_required([:name, :author_did])
    |> validate_length(:name, min: 1, max: 50)
    |> validate_length(:description, max: 280)
    |> validate_format(:name, ~r/^[a-zA-Z0-9_]+$/, message: "can only contain letters, numbers, and underscores")
    |> unique_constraint(:uri)
    |> unique_constraint([:name, :author_did], message: "tag name already exists for this author")
  end
end