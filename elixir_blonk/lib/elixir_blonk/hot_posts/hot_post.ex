defmodule ElixirBlonk.HotPosts.HotPost do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "hot_posts" do
    field :post_uri, :string
    field :author_did, :string
    field :text, :string
    field :external_url, :string
    field :record_data, :map  # Store the full ATProto record
    field :check_count, :integer, default: 0
    field :reply_count, :integer, default: 0
    field :converted_to_blip, :boolean, default: false
    field :last_checked_at, :utc_datetime

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(hot_post, attrs) do
    hot_post
    |> cast(attrs, [
      :post_uri, :author_did, :text, :external_url, :record_data,
      :check_count, :reply_count, :converted_to_blip, :last_checked_at
    ])
    |> validate_required([:post_uri, :author_did])
    |> unique_constraint(:post_uri)
  end

  @doc false
  def update_changeset(hot_post, attrs) do
    hot_post
    |> cast(attrs, [:check_count, :reply_count, :converted_to_blip, :last_checked_at])
  end
end