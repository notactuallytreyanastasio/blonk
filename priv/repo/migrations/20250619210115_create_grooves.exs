defmodule ElixirBlonk.Repo.Migrations.CreateGrooves do
  use Ecto.Migration

  def change do
    create table(:grooves, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :uri, :string, null: false
      add :cid, :string, null: false
      add :author_did, :string, null: false
      add :subject_uri, :string, null: false
      add :groove_type, :string, null: false
      add :blip_id, references(:blips, type: :binary_id, on_delete: :delete_all)

      timestamps(type: :utc_datetime)
    end

    create unique_index(:grooves, [:author_did, :subject_uri])
    create index(:grooves, [:blip_id])
    create index(:grooves, [:groove_type])
  end
end
