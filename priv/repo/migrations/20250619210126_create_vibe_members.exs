defmodule ElixirBlonk.Repo.Migrations.CreateVibeMembers do
  use Ecto.Migration

  def change do
    create table(:vibe_members, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :uri, :string, null: false
      add :cid, :string, null: false
      add :member_did, :string, null: false
      add :vibe_uri, :string, null: false
      add :vibe_id, references(:vibes, type: :binary_id, on_delete: :delete_all)

      timestamps(type: :utc_datetime)
    end

    create unique_index(:vibe_members, [:member_did, :vibe_uri])
    create index(:vibe_members, [:vibe_id])
  end
end
