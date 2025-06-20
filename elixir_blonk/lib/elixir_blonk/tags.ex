defmodule ElixirBlonk.Tags do
  @moduledoc """
  The Tags context for managing tag records in ATProto.
  """

  import Ecto.Query, warn: false
  require Logger
  alias ElixirBlonk.Repo

  alias ElixirBlonk.Tags.Tag

  @doc """
  Returns the list of tags.
  """
  def list_tags do
    Tag
    |> order_by([t], desc: t.usage_count)
    |> Repo.all()
  end

  @doc """
  Returns the list of tags by author.
  """
  def list_tags_by_author(author_did) do
    Tag
    |> where([t], t.author_did == ^author_did)
    |> order_by([t], desc: t.usage_count)
    |> Repo.all()
  end

  @doc """
  Gets a single tag by ID.
  """
  def get_tag!(id), do: Repo.get!(Tag, id)

  @doc """
  Gets a tag by name and author.
  """
  def get_tag_by_name_and_author(name, author_did) do
    Tag
    |> where([t], t.name == ^name and t.author_did == ^author_did)
    |> Repo.one()
  end

  @doc """
  Gets a tag by URI.
  """
  def get_tag_by_uri(uri) do
    Repo.get_by(Tag, uri: uri)
  end

  @doc """
  Searches for tags by name.
  """
  def search_tags(query) do
    search_term = "%#{query}%"
    
    Tag
    |> where([t], ilike(t.name, ^search_term) or ilike(t.description, ^search_term))
    |> order_by([t], desc: t.usage_count)
    |> Repo.all()
  end

  @doc """
  Creates a tag.
  """
  def create_tag(attrs \\ %{}) do
    # First create in local database
    with {:ok, tag} <- %Tag{}
                       |> Tag.changeset(attrs)
                       |> Repo.insert() do
      
      # Then try to create in ATProto if enabled
      if Application.get_env(:elixir_blonk, :atproto_enabled, true) do
        Task.Supervisor.start_child(ElixirBlonk.TaskSupervisor, fn ->
          create_tag_in_atproto(tag)
        end)
      end
      
      {:ok, tag}
    end
  end

  @doc """
  Finds or creates a tag by name and author.
  """
  def find_or_create_tag(name, author_did, description \\ nil) do
    case get_tag_by_name_and_author(name, author_did) do
      nil ->
        create_tag(%{
          name: name,
          author_did: author_did,
          description: description,
          indexed_at: DateTime.utc_now()
        })
      
      existing_tag ->
        {:ok, existing_tag}
    end
  end

  @doc """
  Updates a tag.
  """
  def update_tag(%Tag{} = tag, attrs) do
    tag
    |> Tag.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Increments the usage count for a tag.
  """
  def increment_usage_count(%Tag{} = tag) do
    update_tag(tag, %{usage_count: tag.usage_count + 1})
  end

  @doc """
  Deletes a tag.
  """
  def delete_tag(%Tag{} = tag) do
    Repo.delete(tag)
  end

  @doc """
  Gets the most popular tags.
  """
  def get_popular_tags(limit \\ 20) do
    Tag
    |> where([t], t.usage_count > 0)
    |> order_by([t], desc: t.usage_count)
    |> limit(^limit)
    |> Repo.all()
  end

  # Private functions

  defp create_tag_in_atproto(tag) do
    with {:ok, client} <- ElixirBlonk.ATProto.SessionManager.get_client(),
         {:ok, %{uri: uri, cid: cid}} <- ElixirBlonk.ATProto.Client.create_tag(client, tag) do
      
      # Update local record with ATProto URI and CID
      update_tag(tag, %{uri: uri, cid: cid})
      Logger.info("Created tag in ATProto: #{uri}")
    else
      {:error, reason} ->
        Logger.error("Failed to create tag in ATProto: #{inspect(reason)}")
    end
  end
end