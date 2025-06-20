defmodule ElixirBlonk.Repo.Migrations.CreateTags do
  use Ecto.Migration

  def change do
    create table(:tags, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :uri, :string
      add :cid, :string
      add :name, :string, null: false
      add :description, :string
      add :author_did, :string, null: false
      add :usage_count, :integer, default: 0
      add :indexed_at, :utc_datetime

      timestamps(type: :utc_datetime)
    end

    create unique_index(:tags, [:uri])
    create unique_index(:tags, [:name, :author_did])
    create index(:tags, [:author_did])
    create index(:tags, [:usage_count])
    create index(:tags, [:name])
  end
end