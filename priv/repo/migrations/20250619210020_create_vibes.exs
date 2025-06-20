defmodule ElixirBlonk.Repo.Migrations.CreateVibes do
  use Ecto.Migration

  def change do
    create table(:vibes, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :uri, :string, null: false
      add :cid, :string, null: false
      add :creator_did, :string, null: false
      add :name, :string, null: false
      add :mood, :string, null: false
      add :emoji, :string
      add :color, :string
      add :member_count, :integer, default: 0
      add :pulse_score, :float, default: 0.0
      add :is_emerging, :boolean, default: false

      timestamps(type: :utc_datetime)
    end

    create unique_index(:vibes, [:uri])
    create unique_index(:vibes, [:name])
    create index(:vibes, [:creator_did])
    create index(:vibes, [:is_emerging])
  end
end
