defmodule ElixirBlonk.Blips do
  @moduledoc """
  The Blips context for managing content submissions in the Blonk ecosystem.
  
  Blips are the fundamental content unit in Blonk - posts submitted to vibes that appear
  on the radar for community engagement. This context orchestrates blip creation, discovery,
  and the integration with Blonk's universal tag system and ATProto records.
  
  ## What Are Blips?
  
  **Blips are content submissions that create community engagement:**
  - Posts with title, optional body/URL, and tags
  - Submitted to specific vibes for topical organization
  - Appear on the radar for cross-vibe discovery
  - Receive grooves (looks_good/shit_rips) from community
  - Enable organic vibe creation through engagement patterns
  
  ## Blonk Ecosystem Integration
  
  - **Vibes**: Blips are submitted to topic-based communities
  - **Radar**: Popular blips surface on the frontpage across vibes
  - **Tags**: Universal labels enable cross-vibe content discovery
  - **Grooves**: Community engagement drives blip visibility
  - **ATProto**: Each blip becomes a `com.blonk.blip` record for portability
  
  ## Content Lifecycle
  
  1. **Submission**: User creates blip with title, body, tags for a vibe
  2. **Tag Extraction**: System automatically extracts #hashtags from content
  3. **ATProto Creation**: Blip becomes decentralized record with URI/CID
  4. **Community Discovery**: Appears in vibe feeds and radar trending
  5. **Engagement**: Users groove on content, driving popularity
  6. **Cross-Vibe Discovery**: Tags enable finding related content across vibes
  
  ## Community Engagement Model
  
  **Blips are designed to encourage quality content:**
  - Submission to relevant vibes ensures targeted audience
  - Tag system enables broader discovery beyond vibe boundaries  
  - Groove system (looks_good/shit_rips) provides clear feedback
  - Popular content surfaces on radar, attracting more engagement
  - External links in blips can become hot posts for community seeding
  
  ## Tag Integration
  
  **Universal tagging system** enhances content discovery:
  - Automatic extraction of #hashtags from blip text
  - Association with universal community-owned tag records
  - Cross-vibe discovery through shared tag vocabulary
  - Tag popularity tracking drives trending algorithms
  
  ## ATProto Integration
  
  **Decentralized content ownership** through ATProto records:
  - Each blip becomes a `com.blonk.blip` ATProto record
  - Content portability across ATProto applications
  - User ownership of content and engagement data
  - Cross-platform discoverability and interaction
  
  ## Examples
  
      # Create a blip for a vibe
      {:ok, blip} = Blips.create_blip(%{
        title: "Amazing New Framework Released",
        body: "This changes everything for developers...",
        url: "https://example.com/framework",
        vibe_uri: tech_vibe.uri,
        tags: ["framework", "productivity", "tools"],
        author_did: "did:plc:user123"
      })
      
      # Find blips by tag across all vibes
      framework_blips = Blips.list_blips_by_tag("framework")
      
      # Search blips by content
      search_results = Blips.search_blips("framework")
  """

  import Ecto.Query, warn: false
  require Logger
  alias ElixirBlonk.Repo

  alias ElixirBlonk.Blips.{Blip, Comment}
  alias ElixirBlonk.Vibes

  @doc """
  Returns the list of blips.
  """
  def list_blips do
    Blip
    |> order_by([b], desc: b.inserted_at)
    |> preload(:vibe)
    |> Repo.all()
  end

  @doc """
  Returns the list of blips for a specific vibe.
  """
  def list_blips_by_vibe(vibe_uri) do
    Blip
    |> where([b], b.vibe_uri == ^vibe_uri)
    |> order_by([b], desc: b.inserted_at)
    |> preload(:vibe)
    |> Repo.all()
  end

  @doc """
  Returns the list of blips by tag.
  """
  def list_blips_by_tag(tag) do
    Blip
    |> where([b], ^tag in b.tags)
    |> order_by([b], desc: b.inserted_at)
    |> preload(:vibe)
    |> Repo.all()
  end

  @doc """
  Returns the list of blips by author.
  """
  def list_blips_by_author(author_did) do
    Blip
    |> where([b], b.author_did == ^author_did)
    |> order_by([b], desc: b.inserted_at)
    |> preload(:vibe)
    |> Repo.all()
  end

  @doc """
  Gets a single blip.
  """
  def get_blip!(id) do
    Blip
    |> preload([:vibe, :comments])
    |> Repo.get!(id)
  end

  @doc """
  Gets a blip by URI.
  """
  def get_blip_by_uri(uri) do
    Blip
    |> preload([:vibe, :comments])
    |> Repo.get_by(uri: uri)
  end

  @doc """
  Creates a blip.
  """
  def create_blip(attrs \\ %{}) do
    # Extract tags from body if present
    attrs = extract_and_add_tags(attrs)
    
    # Set vibe_id if vibe_uri is provided
    attrs = if attrs[:vibe_uri] do
      case Vibes.get_vibe_by_uri(attrs[:vibe_uri]) do
        nil -> attrs
        vibe -> Map.put(attrs, :vibe_id, vibe.id)
      end
    else
      attrs
    end

    # First create in local database
    with {:ok, blip} <- %Blip{}
                        |> Blip.changeset(attrs)
                        |> Repo.insert() do
      
      # Then try to create in ATProto if enabled
      if Application.get_env(:elixir_blonk, :atproto_enabled, true) do
        Task.Supervisor.start_child(ElixirBlonk.TaskSupervisor, fn ->
          create_blip_in_atproto(blip)
        end)
      end
      
      {:ok, blip}
    end
  end

  defp create_blip_in_atproto(blip) do
    with {:ok, client} <- ElixirBlonk.ATProto.SimpleSession.get_client(),
         {:ok, %{uri: uri, cid: cid}} <- ElixirBlonk.ATProto.create_blip(client, blip) do
      
      # Update local record with ATProto URI and CID
      update_blip(blip, %{uri: uri, cid: cid})
      Logger.info("Created blip in ATProto: #{uri}")
    else
      {:error, reason} ->
        Logger.error("Failed to create blip in ATProto: #{inspect(reason)}")
    end
  end

  @doc """
  Updates a blip.
  """
  def update_blip(%Blip{} = blip, attrs) do
    attrs = extract_and_add_tags(attrs)
    
    blip
    |> Blip.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a blip.
  """
  def delete_blip(%Blip{} = blip) do
    Repo.delete(blip)
  end

  @doc """
  Creates a comment on a blip.
  """
  def create_comment(attrs \\ %{}) do
    # Find the blip by subject_uri if provided
    attrs = if attrs[:subject_uri] do
      case get_blip_by_uri(attrs[:subject_uri]) do
        nil -> attrs
        blip -> Map.put(attrs, :blip_id, blip.id)
      end
    else
      attrs
    end

    %Comment{}
    |> Comment.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Lists comments for a blip.
  """
  def list_comments_for_blip(blip_id) do
    Comment
    |> where([c], c.blip_id == ^blip_id)
    |> order_by([c], asc: c.inserted_at)
    |> Repo.all()
  end

  @doc """
  Updates groove counts for a blip.
  """
  def update_groove_counts(blip_id) do
    blip = get_blip!(blip_id)
    
    looks_good_count = ElixirBlonk.Grooves.count_grooves_by_type(blip_id, "looks_good")
    shit_rips_count = ElixirBlonk.Grooves.count_grooves_by_type(blip_id, "shit_rips")
    
    update_blip(blip, %{
      grooves_looks_good: looks_good_count,
      grooves_shit_rips: shit_rips_count
    })
  end

  @doc """
  Searches blips by text.
  """
  def search_blips(query) do
    search_term = "%#{query}%"
    
    Blip
    |> where([b], ilike(b.title, ^search_term) or ilike(b.body, ^search_term))
    |> order_by([b], desc: b.inserted_at)
    |> preload(:vibe)
    |> Repo.all()
  end

  @doc """
  Gets tag frequency data for a specific vibe.
  Returns a list of {tag, count} tuples sorted by frequency.
  """
  def get_vibe_tag_frequency(vibe_id) do
    blips = 
      Blip
      |> where([b], b.vibe_id == ^vibe_id)
      |> select([b], b.tags)
      |> Repo.all()
    
    blips
    |> List.flatten()
    |> Enum.frequencies()
    |> Enum.sort_by(&elem(&1, 1), :desc)
  end

  # Private functions

  defp extract_and_add_tags(attrs) do
    text = "#{attrs[:title] || ""} #{attrs[:body] || ""}"
    tags = extract_tags(text)
    
    if Enum.any?(tags) do
      existing_tags = attrs[:tags] || []
      Map.put(attrs, :tags, Enum.uniq(existing_tags ++ tags))
    else
      attrs
    end
  end

  defp extract_tags(text) do
    ~r/#\w+/
    |> Regex.scan(text)
    |> List.flatten()
    |> Enum.map(&String.trim(&1, "#"))
    |> Enum.uniq()
  end
end