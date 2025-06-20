defmodule ElixirBlonk.Repo.Migrations.CreateHotPosts do
  use Ecto.Migration

  def change do
    create table(:hot_posts, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :post_uri, :string, null: false
      add :author_did, :string, null: false
      add :text, :text
      add :external_url, :string
      add :record_data, :map
      add :check_count, :integer, default: 0
      add :reply_count, :integer, default: 0
      add :converted_to_blip, :boolean, default: false
      add :last_checked_at, :utc_datetime

      timestamps(type: :utc_datetime)
    end

    create unique_index(:hot_posts, [:post_uri])
    create index(:hot_posts, [:check_count])
    create index(:hot_posts, [:reply_count])
    create index(:hot_posts, [:inserted_at])
    create index(:hot_posts, [:converted_to_blip])
  end
end
