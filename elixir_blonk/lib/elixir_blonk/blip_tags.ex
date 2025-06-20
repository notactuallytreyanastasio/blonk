defmodule ElixirBlonk.BlipTags do
  @moduledoc """
  The BlipTags context for managing blip-tag associations.
  """

  import Ecto.Query, warn: false
  require Logger
  alias ElixirBlonk.Repo

  alias ElixirBlonk.BlipTags.BlipTag
  alias ElixirBlonk.{Blips, Tags}

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
      # Find or create the tag
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
    with {:ok, client} <- ElixirBlonk.ATProto.SessionManager.get_client(),
         {:ok, %{uri: uri, cid: cid}} <- ElixirBlonk.ATProto.Client.create_blip_tag(client, blip_tag) do
      
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