defmodule ElixirBlonk.Repo.Migrations.CreateComments do
  use Ecto.Migration

  def change do
    create table(:comments, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :uri, :string, null: false
      add :cid, :string, null: false
      add :author_did, :string, null: false
      add :body, :text, null: false
      add :subject_uri, :string, null: false
      add :blip_id, references(:blips, type: :binary_id, on_delete: :delete_all)

      timestamps(type: :utc_datetime)
    end

    create unique_index(:comments, [:uri])
    create index(:comments, [:blip_id])
    create index(:comments, [:author_did])
  end
end
