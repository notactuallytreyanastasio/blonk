defmodule ElixirBlonk.BlipTags do
  @moduledoc """
  The BlipTags context for managing blip-tag associations in the Blonk ecosystem.
  
  This context orchestrates the many-to-many relationships between blips and
  universal tags, enabling community-driven content categorization and 
  cross-vibe discovery on the radar.
  
  ## Core Purpose in Blonk
  
  **BlipTags power content discovery** by connecting blips across vibes through
  shared community vocabulary. When users tag their blips, they're contributing
  to a decentralized knowledge graph that helps surface trending content and
  enables organic community formation around topics.
  
  ## Integration with Blonk Ecosystem
  
  - **Vibes**: Tags categorize blips within vibes for better organization
  - **Radar**: Popular tagged content surfaces on the frontpage across vibes  
  - **Grooves**: Community engagement on tagged blips increases tag visibility
  - **Hot Posts**: Firehose content gets auto-tagged to seed community activity
  - **Discovery**: Users find new vibes and blips through tag exploration
  
  ## Community Engagement Flow
  
  1. **Content Creation**: User submits blip with #hashtags to a vibe
  2. **Tag Association**: System extracts tags and creates BlipTag records
  3. **Community Discovery**: Other users find content through tag searches
  4. **Groove Engagement**: Community grooves (looks_good/shit_rips) on tagged content
  5. **Trending**: Popular tagged blips surface on radar frontpage
  6. **Vibe Growth**: Successful tags attract more users to related vibes
  
  ## ATProto Integration
  
  Each BlipTag association is stored as a `com.blonk.blipTag` ATProto record,
  enabling decentralized content discovery and cross-platform compatibility.
  This means tagged content can be discovered outside of Blonk while maintaining
  attribution and community context.
  
  ## Examples
  
      # Tag a new blip submission
      BlipTags.associate_tags_with_blip(blip_id, ["art", "design"], user_did)
      
      # Find trending art content across all vibes  
      art_tag = Tags.get_tag_by_name("art")
      trending_art = BlipTags.get_blips_for_tag(art_tag.id)
      
      # Clean up tags when content is removed
      BlipTags.remove_all_tags_from_blip(blip_id)
  """

  import Ecto.Query, warn: false
  require Logger
  alias ElixirBlonk.Repo

  alias ElixirBlonk.BlipTags.BlipTag
  alias ElixirBlonk.Tags

  @doc """
  Associates a tag with a blip.
  """
  def create_blip_tag(blip_id, tag_id, author_did) do
    attrs = %{
      blip_id: blip_id,
      tag_id: tag_id,
      author_did: author_did
    }

    # First create in local database
    with {:ok, blip_tag} <- %BlipTag{}
                            |> BlipTag.changeset(attrs)
                            |> Repo.insert() do
      
      # Increment tag usage count
      tag = Tags.get_tag!(tag_id)
      Tags.increment_usage_count(tag)
      
      # Then try to create in ATProto if enabled
      if Application.get_env(:elixir_blonk, :atproto_enabled, true) do
        Task.Supervisor.start_child(ElixirBlonk.TaskSupervisor, fn ->
          create_blip_tag_in_atproto(blip_tag)
        end)
      end
      
      {:ok, blip_tag}
    end
  end

  @doc """
  Removes a tag association from a blip.
  """
  def delete_blip_tag(blip_id, tag_id) do
    blip_tag = 
      BlipTag
      |> where([bt], bt.blip_id == ^blip_id and bt.tag_id == ^tag_id)
      |> Repo.one()

    if blip_tag do
      # Decrement tag usage count
      tag = Tags.get_tag!(tag_id)
      if tag.usage_count > 0 do
        Tags.update_tag(tag, %{usage_count: tag.usage_count - 1})
      end
      
      Repo.delete(blip_tag)
    else
      {:error, :not_found}
    end
  end

  @doc """
  Gets all tags for a blip.
  """
  def get_tags_for_blip(blip_id) do
    BlipTag
    |> where([bt], bt.blip_id == ^blip_id)
    |> join(:inner, [bt], t in assoc(bt, :tag))
    |> select([bt, t], t)
    |> Repo.all()
  end

  @doc """
  Gets all blips for a tag.
  """
  def get_blips_for_tag(tag_id) do
    BlipTag
    |> where([bt], bt.tag_id == ^tag_id)
    |> join(:inner, [bt], b in assoc(bt, :blip))
    |> select([bt, b], b)
    |> preload([bt, b], b: :vibe)
    |> Repo.all()
  end

  @doc """
  Associates multiple tags with a blip by tag names.
  Creates tags if they don't exist.
  """
  def associate_tags_with_blip(blip_id, tag_names, author_did) when is_list(tag_names) do
    Enum.each(tag_names, fn tag_name ->
      # Find or create the universal tag
      {:ok, tag} = Tags.find_or_create_tag(tag_name, author_did)
      
      # Associate with blip (ignore if already exists)
      case create_blip_tag(blip_id, tag.id, author_did) do
        {:ok, _} -> :ok
        {:error, _} -> :ok  # Likely already exists
      end
    end)
  end

  @doc """
  Removes all tag associations for a blip.
  """
  def remove_all_tags_from_blip(blip_id) do
    blip_tags = 
      BlipTag
      |> where([bt], bt.blip_id == ^blip_id)
      |> Repo.all()

    # Decrement usage counts for all associated tags
    Enum.each(blip_tags, fn blip_tag ->
      tag = Tags.get_tag!(blip_tag.tag_id)
      if tag.usage_count > 0 do
        Tags.update_tag(tag, %{usage_count: tag.usage_count - 1})
      end
    end)

    # Delete all associations
    BlipTag
    |> where([bt], bt.blip_id == ^blip_id)
    |> Repo.delete_all()
  end

  # Private functions

  defp create_blip_tag_in_atproto(blip_tag) do
    with {:ok, client} <- ElixirBlonk.ATProto.SimpleSession.get_client(),
         {:ok, %{uri: uri, cid: cid}} <- ElixirBlonk.ATProto.create_blip_tag(client, blip_tag) do
      
      # Update local record with ATProto URI and CID
      blip_tag
      |> BlipTag.changeset(%{uri: uri, cid: cid})
      |> Repo.update()
      
      Logger.info("Created blip-tag association in ATProto: #{uri}")
    else
      {:error, reason} ->
        Logger.error("Failed to create blip-tag association in ATProto: #{inspect(reason)}")
    end
  end
end