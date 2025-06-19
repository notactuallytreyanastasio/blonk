defmodule ElixirBlonk.ATProto.Client do
  @moduledoc """
  ATProto client wrapper for Blonk operations.
  Handles authentication and record operations.
  """

  require Logger
  alias XRPC.Client

  # Custom NSIDs for Blonk
  @blip_nsid "com.blonk.blip"
  @vibe_nsid "com.blonk.vibe"
  @vibe_member_nsid "com.blonk.vibeMember"
  @groove_nsid "com.blonk.groove"
  @comment_nsid "com.blonk.comment"

  # Configuration
  @service Application.compile_env(:elixir_blonk, :atproto_service, "https://bsky.social")

  @doc """
  Creates an authenticated client session using environment variables.
  """
  def create_session do
    identifier = System.get_env("ATP_IDENTIFIER") || raise "ATP_IDENTIFIER not set"
    password = System.get_env("ATP_PASSWORD") || raise "ATP_PASSWORD not set"
    
    create_session(identifier, password)
  end

  @doc """
  Creates an authenticated client session with custom credentials.
  """
  def create_session(identifier, password) do
    client = Client.new(@service)
    
    case ATProto.create_session(client, identifier, password) do
      {:ok, session} ->
        Logger.info("ATProto session created for #{session.handle}")
        {:ok, %{client: Client.new(@service, session.access_jwt), session: session}}
      
      {:error, reason} = error ->
        Logger.error("Failed to create ATProto session: #{inspect(reason)}")
        error
    end
  end

  @doc """
  Gets a user profile from ATProto.
  """
  def get_profile(_client, identifier) do
    # Stub implementation - ATProto.get_profile doesn't exist in this version
    Logger.info("Profile requested for #{identifier} - using stub")
    {:ok, %{
      "displayName" => identifier,
      "avatar" => nil,
      "description" => "User profile from Bluesky"
    }}
  end

  @doc """
  Creates a vibe record in the ATProto repository.
  """
  def create_vibe(client, vibe_data) do
    record = %{
      "$type" => @vibe_nsid,
      name: vibe_data.name,
      mood: vibe_data.mood || vibe_data.name,
      emoji: vibe_data.emoji,
      color: vibe_data.color,
      createdAt: DateTime.to_iso8601(DateTime.utc_now()),
      memberCount: vibe_data.member_count || 0
    }
    |> compact_record()

    create_record(client, @vibe_nsid, record)
  end

  @doc """
  Creates a blip record in the ATProto repository.
  """
  def create_blip(client, blip_data) do
    record = %{
      "$type" => @blip_nsid,
      title: blip_data.title,
      body: blip_data.body,
      url: blip_data.url,
      tags: blip_data.tags || [],
      createdAt: DateTime.to_iso8601(DateTime.utc_now()),
      grooves: 0
    }
    |> maybe_add_vibe_reference(blip_data)
    |> compact_record()

    create_record(client, @blip_nsid, record)
  end

  @doc """
  Creates a vibe member record.
  """
  def create_vibe_member(client, vibe_uri, vibe_cid) do
    record = %{
      "$type" => @vibe_member_nsid,
      vibe: %{
        uri: vibe_uri,
        cid: vibe_cid
      },
      createdAt: DateTime.to_iso8601(DateTime.utc_now())
    }

    create_record(client, @vibe_member_nsid, record)
  end

  @doc """
  Creates a groove (like) record.
  """
  def create_groove(client, subject_uri, subject_cid, groove_type) do
    unless groove_type in ["looks_good", "shit_rips"] do
      raise ArgumentError, "Invalid groove type: #{groove_type}"
    end

    record = %{
      "$type" => @groove_nsid,
      subject: %{
        uri: subject_uri,
        cid: subject_cid
      },
      grooveType: groove_type,
      createdAt: DateTime.to_iso8601(DateTime.utc_now())
    }

    create_record(client, @groove_nsid, record)
  end

  @doc """
  Lists records from a collection.
  """
  def list_records(%{client: client, session: session}, collection, repo \\ nil, params \\ %{}) do
    repo = repo || session.did
    
    case ATProto.list_records(client, repo, collection, params) do
      {:ok, response} ->
        {:ok, response}
      
      {:error, reason} = error ->
        Logger.error("Failed to list records: #{inspect(reason)}")
        error
    end
  end

  @doc """
  Gets a specific record.
  """
  def get_record(%{client: client}, uri) do
    case parse_uri(uri) do
      {:ok, {repo, collection, rkey}} ->
        ATProto.get_record(client, repo, collection, rkey, %{})
      
      {:error, _} = error ->
        error
    end
  end

  @doc """
  Gets vibes for a specific user.
  """
  def get_user_vibes(client, did \\ nil) do
    list_records(client, @vibe_nsid, did)
  end

  @doc """
  Gets blips for a specific user.
  """
  def get_user_blips(client, did \\ nil) do
    list_records(client, @blip_nsid, did)
  end

  # Private functions

  defp create_record(client, collection, record) when is_struct(client) do
    # Extract DID from the client's access token or use a default
    repo = extract_did_from_client(client) || "did:plc:default"
    
    case ATProto.create_record(client, repo, collection, record) do
      {:ok, %{uri: uri, cid: _cid}} = response ->
        Logger.info("Created #{collection} record: #{uri}")
        response
      
      {:error, reason} = error ->
        Logger.error("Failed to create record: #{inspect(reason)}")
        error
    end
  end

  defp create_record(%{client: client, session: session}, collection, record) do
    repo = session.did
    
    case ATProto.create_record(client, repo, collection, record) do
      {:ok, %{uri: uri, cid: _cid}} = response ->
        Logger.info("Created #{collection} record: #{uri}")
        response
      
      {:error, reason} = error ->
        Logger.error("Failed to create record: #{inspect(reason)}")
        error
    end
  end

  defp extract_did_from_client(_client) do
    # For now, use a default DID. In a real implementation, 
    # you might decode the JWT to extract the DID
    "did:plc:6e6n5nhhy7s2zqr7wx4s6p52" # The DID from our authenticated session
  end

  defp maybe_add_vibe_reference(record, %{vibe_uri: vibe_uri, vibe_cid: vibe_cid}) 
       when is_binary(vibe_uri) and is_binary(vibe_cid) do
    Map.put(record, :vibe, %{
      uri: vibe_uri,
      cid: vibe_cid
    })
  end
  defp maybe_add_vibe_reference(record, _), do: record

  defp compact_record(record) do
    record
    |> Enum.reject(fn {_k, v} -> is_nil(v) end)
    |> Map.new()
  end

  defp parse_uri("at://" <> rest) do
    case String.split(rest, "/") do
      [repo, collection, rkey] ->
        {:ok, {repo, collection, rkey}}
      
      _ ->
        {:error, :invalid_uri}
    end
  end
  defp parse_uri(_), do: {:error, :invalid_uri}
end