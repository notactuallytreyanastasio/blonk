defmodule ElixirBlonk.Repo.Migrations.UpdateHotPostsExternalUrlToText do
  use Ecto.Migration

  def change do
    alter table(:hot_posts) do
      modify :external_url, :text
    end
  end
end