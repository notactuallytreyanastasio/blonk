defmodule ElixirBlonk.Repo.Migrations.AddAtprotoFieldsToUsers do
  use Ecto.Migration

  def change do
    alter table(:users) do
      add :did, :string, null: true
      add :handle, :string, null: true
      add :display_name, :string, null: true
      add :avatar_url, :string, null: true
      add :access_jwt, :text, null: true
      add :refresh_jwt, :text, null: true
      add :atproto_service, :string, null: true, default: "https://bsky.social"
    end

    create unique_index(:users, [:did])
    create unique_index(:users, [:handle])
  end
end
