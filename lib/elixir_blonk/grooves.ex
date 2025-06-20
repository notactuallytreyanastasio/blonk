defmodule ElixirBlonk.Grooves do
  @moduledoc """
  The Grooves context for managing community engagement in the Blonk ecosystem.
  
  Grooves are Blonk's community feedback mechanism - the way users express their
  reaction to blips through "looks_good" (positive) or "shit_rips" (critical)
  responses. This context orchestrates the engagement that drives content visibility
  and community curation.
  
  ## What Are Grooves?
  
  **Grooves are binary community feedback on blips:**
  - **looks_good** (👍) - Positive community endorsement
  - **shit_rips** - Critical community feedback
  - Each user can groove once per blip with either reaction
  - Groove counts drive content visibility and trending algorithms
  - Community-driven curation without complex scoring systems
  
  ## Philosophy: Simple, Clear Feedback
  
  **Why binary grooves instead of complex voting?**
  - Clear, unambiguous community sentiment
  - Prevents gaming through vote manipulation
  - Encourages authentic engagement over optimization
  - Simple UI that promotes quick, honest reactions
  - Community consensus emerges naturally through patterns
  
  ## Blonk Ecosystem Integration
  
  - **Blips**: Content receives grooves from community members
  - **Vibes**: Groove activity indicates vibe health and engagement
  - **Radar**: Popular (well-grooved) content surfaces on frontpage
  - **Tags**: Grooves on tagged content influence tag popularity
  - **Community**: Groove patterns reveal quality content and active members
  
  ## Community Engagement Mechanics
  
  **Grooves drive organic content curation:**
  - High "looks_good" count signals quality content worth surfacing
  - "shit_rips" provides critical feedback for content improvement
  - Groove ratios help identify controversial vs consensus content
  - Activity patterns reveal engaged community members
  - Aggregated data drives radar trending algorithms
  
  ## Content Visibility Impact
  
  **Grooves determine what the community sees:**
  1. **Vibe Ordering**: Well-grooved blips rise in vibe feeds
  2. **Radar Prominence**: Popular content appears on frontpage
  3. **Tag Trending**: Grooved tagged content influences tag popularity
  4. **Community Health**: Active grooving indicates vibrant community
  5. **Quality Signal**: Consistent groove patterns identify good content
  
  ## Anti-Gaming Design
  
  **Simple system resists manipulation:**
  - One groove per user per blip (no vote stacking)
  - Binary choice prevents complex optimization strategies
  - Community patterns harder to fake than individual metrics
  - Real engagement required - no anonymous or bulk actions
  - ATProto attribution provides accountability
  
  ## Social Dynamics
  
  **Grooves create healthy community interaction:**
  - Positive reinforcement for quality contributions
  - Critical feedback mechanism for improvement
  - Community consensus building through collective action
  - Recognition for active, thoughtful community members
  - Natural moderation through peer feedback
  
  ## Examples
  
      # User grooves positively on a blip
      {:ok, groove} = Grooves.toggle_groove(
        "did:plc:user123",
        "at://did:plc:author/com.blonk.blip/rkey", 
        "looks_good"
      )
      
      # Check community sentiment on content
      %{looks_good: 42, shit_rips: 3} = Grooves.get_groove_counts(blip_id)
      
      # Find most grooved content in vibe
      trending_blips = Blips.list_blips_by_vibe(vibe_uri) 
      |> Enum.sort_by(&(&1.grooves_looks_good), :desc)
  """

  import Ecto.Query, warn: false
  require Logger
  alias ElixirBlonk.Repo

  alias ElixirBlonk.Grooves.Groove
  alias ElixirBlonk.Blips

  @doc """
  Creates a groove (reaction) for a blip.
  """
  def create_groove(attrs \\ %{}) do
    # Find the blip by subject_uri if provided
    attrs = if attrs[:subject_uri] do
      case Blips.get_blip_by_uri(attrs[:subject_uri]) do
        nil -> attrs
        blip -> Map.put(attrs, :blip_id, blip.id)
      end
    else
      attrs
    end

    # First create in local database
    with {:ok, groove} <- %Groove{}
                          |> Groove.changeset(attrs)
                          |> Repo.insert() do
      
      # Update groove counts on the blip
      if groove.blip_id do
        Blips.update_groove_counts(groove.blip_id)
      end
      
      # Then try to create in ATProto if enabled
      if Application.get_env(:elixir_blonk, :atproto_enabled, true) do
        Task.Supervisor.start_child(ElixirBlonk.TaskSupervisor, fn ->
          create_groove_in_atproto(groove)
        end)
      end
      
      {:ok, groove}
    end
  end

  @doc """
  Deletes a groove.
  """
  def delete_groove(%Groove{} = groove) do
    result = Repo.delete(groove)
    
    # Update groove counts on the blip
    if groove.blip_id do
      Blips.update_groove_counts(groove.blip_id)
    end
    
    result
  end

  @doc """
  Gets a groove by author and subject.
  """
  def get_groove_by_author_and_subject(author_did, subject_uri) do
    Groove
    |> where([g], g.author_did == ^author_did and g.subject_uri == ^subject_uri)
    |> Repo.one()
  end

  @doc """
  Toggles a groove - creates if doesn't exist, changes type if different, deletes if same.
  """
  def toggle_groove(author_did, subject_uri, groove_type, attrs \\ %{}) do
    case get_groove_by_author_and_subject(author_did, subject_uri) do
      nil ->
        # Create new groove
        attrs = Map.merge(attrs, %{
          author_did: author_did,
          subject_uri: subject_uri,
          groove_type: groove_type
        })
        create_groove(attrs)
        
      %Groove{groove_type: ^groove_type} = groove ->
        # Same type, so remove it
        delete_groove(groove)
        {:ok, nil}
        
      groove ->
        # Different type, update it
        groove
        |> Groove.changeset(%{groove_type: groove_type})
        |> Repo.update()
        |> case do
          {:ok, updated_groove} ->
            # Update counts
            if updated_groove.blip_id do
              Blips.update_groove_counts(updated_groove.blip_id)
            end
            {:ok, updated_groove}
          error -> error
        end
    end
  end

  @doc """
  Lists all grooves for a blip.
  """
  def list_grooves_for_blip(blip_id) do
    Groove
    |> where([g], g.blip_id == ^blip_id)
    |> Repo.all()
  end

  @doc """
  Lists all grooves by a specific author.
  """
  def list_grooves_by_author(author_did) do
    Groove
    |> where([g], g.author_did == ^author_did)
    |> preload(:blip)
    |> Repo.all()
  end

  @doc """
  Counts grooves by type for a blip.
  """
  def count_grooves_by_type(blip_id, groove_type) do
    Groove
    |> where([g], g.blip_id == ^blip_id and g.groove_type == ^groove_type)
    |> Repo.aggregate(:count)
  end

  @doc """
  Checks if an author has grooved a specific blip.
  """
  def has_grooved?(author_did, subject_uri) do
    Groove
    |> where([g], g.author_did == ^author_did and g.subject_uri == ^subject_uri)
    |> Repo.exists?()
  end

  @doc """
  Gets the groove type for an author on a specific blip.
  """
  def get_groove_type(author_did, subject_uri) do
    Groove
    |> where([g], g.author_did == ^author_did and g.subject_uri == ^subject_uri)
    |> select([g], g.groove_type)
    |> Repo.one()
  end

  # Private functions

  defp create_groove_in_atproto(groove) do
    with {:ok, client} <- ElixirBlonk.ATProto.SimpleSession.get_client(),
         {:ok, %{uri: uri, cid: cid}} <- ElixirBlonk.ATProto.create_groove(client, groove) do
      
      # Update local record with ATProto URI and CID
      groove
      |> Groove.changeset(%{uri: uri, cid: cid})
      |> Repo.update()
      
      Logger.info("Created groove in ATProto: #{uri}")
    else
      {:error, reason} ->
        Logger.error("Failed to create groove in ATProto: #{inspect(reason)}")
    end
  end
end