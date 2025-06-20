defmodule ElixirBlonk.BlipTags.BlipTag do
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