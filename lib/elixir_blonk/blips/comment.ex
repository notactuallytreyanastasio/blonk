defmodule ElixirBlonk.Blips.Comment do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "comments" do
    field :uri, :string
    field :cid, :string
    field :author_did, :string
    field :body, :string
    field :subject_uri, :string

    belongs_to :blip, ElixirBlonk.Blips.Blip

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(comment, attrs) do
    comment
    |> cast(attrs, [:uri, :cid, :author_did, :body, :subject_uri, :blip_id])
    |> validate_required([:uri, :cid, :author_did, :body, :subject_uri])
    |> validate_length(:body, max: 2000)
    |> unique_constraint(:uri)
  end
end