defmodule ElixirBlonk.Repo.Migrations.CreateBlips do
  use Ecto.Migration

  def change do
    create table(:blips, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :uri, :string, null: false
      add :cid, :string, null: false
      add :author_did, :string, null: false
      add :title, :string, null: false
      add :body, :text
      add :url, :string
      add :tags, {:array, :string}, default: []
      add :vibe_uri, :string
      add :vibe_id, references(:vibes, type: :binary_id, on_delete: :nilify_all)
      add :grooves_looks_good, :integer, default: 0
      add :grooves_shit_rips, :integer, default: 0
      add :indexed_at, :utc_datetime

      timestamps(type: :utc_datetime)
    end

    create unique_index(:blips, [:uri])
    create index(:blips, [:author_did])
    create index(:blips, [:vibe_id])
    create index(:blips, [:indexed_at])
    create index(:blips, [:tags], using: :gin)
  end
end
