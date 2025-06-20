defmodule ElixirBlonk.ATProto do
  @moduledoc """
  Simple, direct ATProto API client for Blonk's decentralized social operations.
  
  This module provides a clean interface to ATProto services, handling authentication
  and making straightforward HTTP requests using Req. Designed to replace complex
  session management patterns with a simple, reliable approach.
  
  ## Philosophy: Keep It Simple
  
  **Why simple?** Because ATProto is just HTTP APIs with bearer tokens:
  - No complex session managers or client wrappers
  - Direct Req calls with proper Authorization headers
  - Fail fast on authentication issues (critical for Blonk)
  - Clean error handling without overengineering
  
  ## Blonk Integration
  
  **Powers Blonk's decentralized architecture** by:
  - Creating custom record types (blips, vibes, tags, grooves)
  - Enabling cross-platform content discovery via ATProto
  - Providing engagement analysis for hot post curation
  - Maintaining data portability and user ownership
  
  ## Authentication Strategy
  
  Uses **app passwords** for secure, long-lived authentication:
  - Authenticate once with user credentials
  - Receive access token for subsequent requests
  - Store token in client struct for reuse
  - System fails fast if authentication fails (no silent degradation)
  
  ## Custom Record Types
  
  Blonk defines several custom NSIDs for community features:
  - `com.blonk.blip` - Content submissions to vibes
  - `com.blonk.tag` - Universal community labels
  - `com.blonk.blipTag` - Content categorization associations
  - `com.blonk.groove` - Community engagement records (looks_good/shit_rips)
  - `com.blonk.vibe` - Topic-based community feeds (future)
  
  ## Error Handling
  
  **Fail fast and clear** approach:
  - Authentication failures crash the system (as intended)
  - API errors return structured `{:error, reason}` tuples
  - HTTP status codes properly mapped to error types
  - No silent failures that could confuse community features
  
  ## Examples
  
      # One-time authentication
      {:ok, client} = ATProto.authenticate()
      
      # Create Blonk records
      {:ok, %{uri: uri, cid: cid}} = ATProto.create_blip(client, blip)
      {:ok, %{uri: uri, cid: cid}} = ATProto.create_tag(client, tag)
      {:ok, %{uri: uri, cid: cid}} = ATProto.create_groove(client, groove)
      
      # Analyze engagement for hot posts
      {:ok, %{reply_count: count}} = ATProto.get_post_engagement(client, post_uri)
      
      # Direct record creation
      {:ok, %{uri: uri, cid: cid}} = ATProto.create_record(client, "com.blonk.blip", record)
  
  ## Performance Characteristics
  
  - **Lightweight**: Just HTTP calls with bearer token headers
  - **Concurrent**: Multiple requests can use the same client
  - **Resilient**: Network errors don't break authentication state
  - **Efficient**: No unnecessary abstraction layers or state management
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

  @doc """
  Create a groove (community engagement) record in ATProto.
  
  Grooves are Blonk's community feedback mechanism, enabling users to express
  their reaction to blips through binary engagement (looks_good/shit_rips).
  Each groove is tightly linked to a specific blip.
  
  ## Blip-Groove Relationship
  
  **Every groove references the blip it's responding to:**
  - Groove record includes blip URI/CID for cross-platform reference
  - Database foreign key ensures data integrity
  - Enables discovery of all grooves for a specific blip
  - Powers community-driven content curation algorithms
  
  ## ATProto Schema (`com.blonk.groove`)
  
  - `blip` - Reference to the grooved blip (uri/cid)
  - `grooveType` - Either "looks_good" or "shit_rips"  
  - `author` - DID of user creating the groove
  - `createdAt` - When this groove was created
  
  ## Community Impact
  
  Grooves create the engagement signals that drive Blonk's discovery:
  - High groove counts surface popular content on radar
  - Community consensus emerges through groove patterns
  - Cross-vibe content discovery powered by groove activity
  
  ## Examples
  
      # User grooves positively on a blip
      {:ok, %{uri: uri, cid: cid}} = ATProto.create_groove(client, groove)
      # Results in: at://did:plc:user/com.blonk.groove/rkey
      # Links to: at://did:plc:author/com.blonk.blip/tech-post
  """
  def create_groove(%__MODULE__{} = client, groove) do
    # Get the blip record that this groove is for
    blip = ElixirBlonk.Blips.get_blip!(groove.blip_id)

    record = %{
      "$type" => @groove_nsid,
      blip: %{uri: blip.uri, cid: blip.cid},
      grooveType: groove.groove_type,
      author: groove.author_did,
      createdAt: DateTime.to_iso8601(DateTime.utc_now())
    }
    |> compact_record()

    create_record(client, @groove_nsid, record)
  end

  defp compact_record(record) do
    record
    |> Enum.reject(fn {_k, v} -> is_nil(v) end)
    |> Map.new()
  end
end