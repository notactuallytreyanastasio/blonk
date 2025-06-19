defmodule ElixirBlonk.ATProto.Sync do
  @moduledoc """
  Syncs records from ATProto repositories to local database.
  """

  require Logger
  
  alias ElixirBlonk.{Blips, Vibes, Grooves}
  alias ElixirBlonk.ATProto.{Client, SessionManager}

  @doc """
  Syncs vibes from a specific user's repository.
  """
  def sync_user_vibes(did) do
    with {:ok, client} <- SessionManager.get_client(),
         {:ok, response} <- Client.get_user_vibes(client, did) do
      
      Logger.info("Syncing #{length(response.records)} vibes from #{did}")
      
      Enum.each(response.records, fn record ->
        sync_vibe_record(record, did)
      end)
      
      {:ok, length(response.records)}
    end
  end

  @doc """
  Syncs blips from a specific user's repository.
  """
  def sync_user_blips(did) do
    with {:ok, client} <- SessionManager.get_client(),
         {:ok, response} <- Client.get_user_blips(client, did) do
      
      Logger.info("Syncing #{length(response.records)} blips from #{did}")
      
      Enum.each(response.records, fn record ->
        sync_blip_record(record, did)
      end)
      
      {:ok, length(response.records)}
    end
  end

  @doc """
  Syncs all records from multiple users.
  """
  def sync_multiple_users(dids) when is_list(dids) do
    results = Enum.map(dids, fn did ->
      Logger.info("Syncing records from #{did}")
      
      vibes_result = sync_user_vibes(did)
      blips_result = sync_user_blips(did)
      
      {did, %{vibes: vibes_result, blips: blips_result}}
    end)
    
    {:ok, Map.new(results)}
  end

  # Private functions

  defp sync_vibe_record(%{uri: uri, cid: cid, value: value}, creator_did) do
    # Check if we already have this vibe
    case Vibes.get_vibe_by_uri(uri) do
      nil ->
        # Create new vibe
        attrs = %{
          uri: uri,
          cid: cid,
          creator_did: creator_did,
          name: value["name"],
          mood: value["mood"] || value["name"],
          emoji: value["emoji"],
          color: value["color"],
          member_count: value["memberCount"] || 0,
          is_emerging: false
        }
        
        case Vibes.create_vibe(attrs) do
          {:ok, vibe} ->
            Logger.debug("Created vibe from sync: #{vibe.name}")
          
          {:error, reason} ->
            Logger.error("Failed to sync vibe: #{inspect(reason)}")
        end
      
      existing ->
        # Update if CID changed
        if existing.cid != cid do
          Vibes.update_vibe(existing, %{
            cid: cid,
            member_count: value["memberCount"] || existing.member_count
          })
        end
    end
  end

  defp sync_blip_record(%{uri: uri, cid: cid, value: value}, author_did) do
    # Check if we already have this blip
    case Blips.get_blip_by_uri(uri) do
      nil ->
        # Get vibe reference if present
        vibe_attrs = case value["vibe"] do
          %{"uri" => vibe_uri, "cid" => vibe_cid} ->
            %{vibe_uri: vibe_uri, vibe_cid: vibe_cid}
          _ ->
            %{}
        end
        
        # Create new blip
        attrs = Map.merge(%{
          uri: uri,
          cid: cid,
          author_did: author_did,
          title: value["title"],
          body: value["body"],
          url: value["url"],
          tags: value["tags"] || [],
          grooves_looks_good: 0,
          grooves_shit_rips: 0,
          indexed_at: parse_datetime(value["createdAt"])
        }, vibe_attrs)
        
        case Blips.create_blip(attrs) do
          {:ok, blip} ->
            Logger.debug("Created blip from sync: #{blip.title}")
          
          {:error, reason} ->
            Logger.error("Failed to sync blip: #{inspect(reason)}")
        end
      
      existing ->
        # Update if CID changed
        if existing.cid != cid do
          Blips.update_blip(existing, %{cid: cid})
        end
    end
  end

  defp parse_datetime(nil), do: DateTime.utc_now()
  defp parse_datetime(datetime_str) do
    case DateTime.from_iso8601(datetime_str) do
      {:ok, datetime, _} -> datetime
      _ -> DateTime.utc_now()
    end
  end
end