defmodule ElixirBlonk.Repo.Migrations.CreateBlipTags do
  use Ecto.Migration

  def change do
    create table(:blip_tags, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :uri, :string
      add :cid, :string
      add :author_did, :string, null: false
      add :blip_id, references(:blips, on_delete: :delete_all, type: :binary_id), null: false
      add :tag_id, references(:tags, on_delete: :delete_all, type: :binary_id), null: false

      timestamps(type: :utc_datetime)
    end

    create unique_index(:blip_tags, [:uri])
    create unique_index(:blip_tags, [:blip_id, :tag_id])
    create index(:blip_tags, [:blip_id])
    create index(:blip_tags, [:tag_id])
    create index(:blip_tags, [:author_did])
  end
end