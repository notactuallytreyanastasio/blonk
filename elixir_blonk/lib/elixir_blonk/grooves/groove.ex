defmodule ElixirBlonk.Grooves.Groove do
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