defmodule ElixirBlonk.Repo.Migrations.UpdateTagsRemoveAuthorConstraint do
  use Ecto.Migration

  def change do
    # Drop the old unique constraint on name+author_did
    drop_if_exists unique_index(:tags, [:name, :author_did])
    
    # Add new unique constraint on name only (universal tags)
    create unique_index(:tags, [:name])
    
    # Make author_did nullable since tags are now universal
    alter table(:tags) do
      modify :author_did, :string, null: true
    end
  end
end