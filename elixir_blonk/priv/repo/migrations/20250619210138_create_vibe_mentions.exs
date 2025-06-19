defmodule ElixirBlonk.Repo.Migrations.CreateVibeMentions do
  use Ecto.Migration

  def change do
    create table(:vibe_mentions, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :vibe_name, :string, null: false
      add :author_did, :string, null: false
      add :post_uri, :string, null: false
      add :mentioned_at, :utc_datetime, null: false
      add :vibe_id, references(:vibes, type: :binary_id, on_delete: :nilify_all)

      timestamps(type: :utc_datetime)
    end

    create index(:vibe_mentions, [:vibe_name])
    create index(:vibe_mentions, [:author_did])
    create index(:vibe_mentions, [:vibe_id])
  end
end
