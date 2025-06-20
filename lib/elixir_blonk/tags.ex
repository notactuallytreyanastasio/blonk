defmodule ElixirBlonk.Tags do
  @moduledoc """
  The Tags context for managing universal tag records in the Blonk ecosystem.
  
  This context provides the core functionality for Blonk's tag system, where
  tags are first-class ATProto records that enable community-driven content
  categorization and discovery across the radar.
  
  ## Core Concepts
  
  **Tags in Blonk** are universal, community-owned labels that categorize blips.
  Unlike traditional hashtags that exist only within posts, Blonk tags are 
  persistent records with rich metadata, usage tracking, and cross-platform
  discoverability through ATProto.
  
  ## Key Features
  
  - **Universal Tags**: Only one tag exists per name globally
  - **Community Ownership**: Anyone can use any tag, promoting shared vocabulary
  - **Usage Tracking**: Popular tags surface through organic community engagement
  - **ATProto Native**: Each tag is a `com.blonk.tag` record with URI/CID
  - **Rich Metadata**: Tags support descriptions and creator attribution
  
  ## Tag Lifecycle in Blonk's Ecosystem
  
  1. **Discovery**: Users encounter tags on blips across vibes
  2. **Creation**: First use of a tag name creates the universal record
  3. **Association**: Tags get linked to blips via BlipTag junction records
  4. **Community Growth**: Usage count increases, surfacing popular tags
  5. **Radar Integration**: Popular tags appear in trending/discovery feeds
  
  ## Relationship to Blonk Core Concepts
  
  - **Vibes**: Tags help categorize blips within vibes (e.g., #crypto blips in crypto_vibe)
  - **Blips**: Each blip can have multiple tags for cross-vibe discovery
  - **Radar**: Popular tags surface trending content across all vibes
  - **Grooves**: Users groove on tagged content, increasing tag visibility
  - **Community**: Shared tags create natural topic-based communities
  
  ## Examples
  
      # Find trending blockchain content across all vibes
      blockchain_tag = Tags.get_tag_by_name("blockchain")
      trending_blips = BlipTags.get_blips_for_tag(blockchain_tag.id)
      
      # Create a new tag when first used
      {:ok, ai_tag} = Tags.find_or_create_tag("ai", user_did, "Artificial Intelligence")
      
      # Get most popular tags for discovery
      popular_tags = Tags.get_popular_tags(20)
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
  Gets a tag by name (universal).
  """
  def get_tag_by_name(name) do
    Tag
    |> where([t], t.name == ^name)
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
  Finds or creates a universal tag by name.
  """
  def find_or_create_tag(name, creator_did \\ nil, description \\ nil) do
    case get_tag_by_name(name) do
      nil ->
        create_tag(%{
          name: name,
          author_did: creator_did,
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
    with {:ok, client} <- ElixirBlonk.ATProto.SimpleSession.get_client(),
         {:ok, %{uri: uri, cid: cid}} <- ElixirBlonk.ATProto.create_tag(client, tag) do
      
      # Update local record with ATProto URI and CID
      update_tag(tag, %{uri: uri, cid: cid})
      Logger.info("Created tag in ATProto: #{uri}")
    else
      {:error, reason} ->
        Logger.error("Failed to create tag in ATProto: #{inspect(reason)}")
    end
  end
end