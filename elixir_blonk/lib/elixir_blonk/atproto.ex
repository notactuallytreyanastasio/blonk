defmodule ElixirBlonk.ATProto do
  @moduledoc """
  Simple ATProto API client for Blonk operations.
  
  This module provides a straightforward interface to ATProto services,
  handling authentication and making direct HTTP requests using Req.
  
  ## Authentication
  
  Uses app passwords for authentication, storing the access token in
  process state for subsequent requests.
  
  ## Usage
  
      # Authenticate once
      {:ok, client} = ATProto.authenticate()
      
      # Make API calls
      {:ok, %{uri: uri, cid: cid}} = ATProto.create_record(client, "com.blonk.blip", record)
      {:ok, post} = ATProto.get_post(client, post_uri)
  """
  
  require Logger

  # ATProto service endpoint
  @service "https://bsky.social"
  
  # Custom NSIDs for Blonk
  @blip_nsid "com.blonk.blip"
  @vibe_nsid "com.blonk.vibe"
  @groove_nsid "com.blonk.groove"
  @tag_nsid "com.blonk.tag"
  @blip_tag_nsid "com.blonk.blipTag"

  defstruct [:access_token, :did, :handle]

  @doc """
  Authenticate with ATProto using environment credentials.
  Returns a client struct with access token for subsequent requests.
  """
  def authenticate do
    identifier = System.get_env("ATP_IDENTIFIER")
    password = System.get_env("ATP_PASSWORD")
    
    if !identifier || !password do
      {:error, :missing_credentials}
    else
      do_authenticate(identifier, password)
    end
  end

  @doc """
  Create a record in ATProto.
  """
  def create_record(%__MODULE__{} = client, collection, record) do
    body = %{
      repo: client.did,
      collection: collection,
      record: record
    }
    
    Req.post("#{@service}/xrpc/com.atproto.repo.createRecord",
      headers: auth_headers(client),
      json: body
    )
    |> handle_response()
  end

  @doc """
  Get a post by URI and check reply count.
  """
  def get_post_engagement(%__MODULE__{} = client, post_uri) do
    # Parse the AT URI to get repo and rkey
    case parse_at_uri(post_uri) do
      {:ok, {repo, _collection, rkey}} ->
        # Use getPostThread to get engagement data
        params = [uri: "at://#{repo}/app.bsky.feed.post/#{rkey}"]
        
        Req.get("#{@service}/xrpc/app.bsky.feed.getPostThread",
          headers: auth_headers(client),
          params: params
        )
        |> extract_engagement()
        
      {:error, reason} ->
        {:error, reason}
    end
  end

  # Helper functions

  defp do_authenticate(identifier, password) do
    body = %{
      identifier: identifier,
      password: password
    }
    
    case Req.post("#{@service}/xrpc/com.atproto.server.createSession", json: body) do
      {:ok, %{status: 200, body: %{"accessJwt" => token, "did" => did, "handle" => handle}}} ->
        client = %__MODULE__{
          access_token: token,
          did: did,
          handle: handle
        }
        {:ok, client}
        
      {:ok, %{status: status, body: body}} ->
        Logger.error("ATProto auth failed: #{status} - #{inspect(body)}")
        {:error, {:http_error, status, body}}
        
      {:error, reason} ->
        Logger.error("ATProto auth request failed: #{inspect(reason)}")
        {:error, reason}
    end
  end

  defp auth_headers(%__MODULE__{access_token: token}) do
    [{"Authorization", "Bearer #{token}"}]
  end

  defp handle_response({:ok, %{status: 200, body: %{"uri" => uri, "cid" => cid}}}) do
    {:ok, %{uri: uri, cid: cid}}
  end
  
  defp handle_response({:ok, %{status: status, body: body}}) do
    {:error, {:http_error, status, body}}
  end
  
  defp handle_response({:error, reason}) do
    {:error, reason}
  end

  defp extract_engagement({:ok, %{status: 200, body: %{"thread" => %{"post" => post}}}}) do
    reply_count = get_in(post, ["replyCount"]) || 0
    {:ok, %{reply_count: reply_count}}
  end
  
  defp extract_engagement({:ok, %{status: status, body: body}}) do
    {:error, {:http_error, status, body}}
  end
  
  defp extract_engagement({:error, reason}) do
    {:error, reason}
  end

  defp parse_at_uri("at://" <> rest) do
    case String.split(rest, "/", parts: 3) do
      [repo, collection, rkey] -> {:ok, {repo, collection, rkey}}
      _ -> {:error, :invalid_uri}
    end
  end
  defp parse_at_uri(_), do: {:error, :invalid_uri}

  # Convenience functions for Blonk record types

  @doc """
  Create a blip record.
  """
  def create_blip(%__MODULE__{} = client, blip) do
    record = %{
      "$type" => @blip_nsid,
      title: blip.title,
      body: blip.body,
      url: blip.url,
      vibe: blip.vibe_uri,
      createdAt: DateTime.to_iso8601(blip.indexed_at || DateTime.utc_now())
    }
    |> compact_record()

    create_record(client, @blip_nsid, record)
  end

  @doc """
  Create a tag record.
  """
  def create_tag(%__MODULE__{} = client, tag) do
    record = %{
      "$type" => @tag_nsid,
      name: tag.name,
      description: tag.description,
      creator: tag.author_did,
      createdAt: DateTime.to_iso8601(tag.indexed_at || DateTime.utc_now())
    }
    |> compact_record()

    create_record(client, @tag_nsid, record)
  end

  @doc """
  Create a blip-tag association record.
  """
  def create_blip_tag(%__MODULE__{} = client, blip_tag) do
    # Get the blip and tag records
    blip = ElixirBlonk.Blips.get_blip!(blip_tag.blip_id)
    tag = ElixirBlonk.Tags.get_tag!(blip_tag.tag_id)

    record = %{
      "$type" => @blip_tag_nsid,
      blip: %{uri: blip.uri, cid: blip.cid},
      tag: %{uri: tag.uri, cid: tag.cid},
      author: blip_tag.author_did,
      createdAt: DateTime.to_iso8601(DateTime.utc_now())
    }
    |> compact_record()

    create_record(client, @blip_tag_nsid, record)
  end

  defp compact_record(record) do
    record
    |> Enum.reject(fn {_k, v} -> is_nil(v) end)
    |> Map.new()
  end
end