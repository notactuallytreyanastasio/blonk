defmodule ElixirBlonk.Firehose.Consumer do
  @moduledoc """
  Real-time Bluesky firehose consumer that powers Blonk's community discovery and seeding.
  
  This WebSocket consumer connects to Bluesky's real-time firehose to capture posts as
  they're created, enabling two critical Blonk functions: organic vibe creation through
  #vibe-name mentions and AI-driven community seeding through hot post detection.
  
  ## Core Functions
  
  **1. Vibe Discovery** - Monitors for `#vibe-name` hashtags to create new communities
  **2. Hot Post Sampling** - Captures 1 in 10 posts with links for trending analysis
  
  ## Why the Firehose?
  
  **Real-time community formation** requires immediate detection of:
  - New vibe mentions that could spawn communities
  - Trending external content that could seed engagement
  - Community activity patterns across the ATProto network
  
  ## Blonk Integration Strategy
  
  - **Vibe Creation**: `#vibe-crypto` mentions accumulate until reaching critical mass
  - **Content Seeding**: Posts with links get sampled for potential trending analysis
  - **Community Bootstrap**: External content helps solve the "empty restaurant" problem
  - **Organic Growth**: Real community formation based on actual user interest
  
  ## Performance Characteristics
  
  **Designed for high-throughput, low-latency processing:**
  - WebSocket connection for real-time data stream
  - Async processing to prevent firehose backpressure
  - Smart sampling (1 in 10) to avoid overwhelming the system
  - Non-blocking operations that don't affect user experience
  
  ## Data Flow
  
  1. **Firehose Stream**: Receives real-time posts from Bluesky network
  2. **Vibe Detection**: Scans for #vibe-name patterns in post text
  3. **Link Sampling**: Identifies posts with external links for hot post analysis
  4. **Async Processing**: Hands off to appropriate handlers without blocking
  5. **Community Impact**: Powers both organic vibe creation and content seeding
  
  ## Error Handling
  
  **Resilient by design** to handle network issues and data anomalies:
  - Automatic reconnection after disconnects
  - Graceful handling of malformed messages
  - Continued operation even if individual posts fail processing
  - Comprehensive logging for debugging community growth patterns
  
  ## Community Growth Engine
  
  The firehose consumer is **Blonk's community growth engine** because it:
  - Detects organic community formation through vibe mentions
  - Seeds new communities with relevant trending content
  - Provides real-time responsiveness to user interests
  - Scales community discovery with network growth
  
  ## Sampling Strategy
  
  **1 in 10 posts with links** balances:
  - **Quality**: Enough samples to catch trending content
  - **Performance**: Doesn't overwhelm the hot post analysis system
  - **Freshness**: Regular sampling ensures recent trends are captured
  - **Diversity**: Broad coverage across different topics and communities
  
  ## Examples
  
      # Vibe mention detection
      "I love this new #vibe-art community!"
      → Records vibe mention for potential community creation
      
      # Hot post sampling
      "Check out this amazing new tool: https://cool-tool.com"
      → 10% chance of being saved for trending analysis
      
      # Community seeding result
      → Hot post with 8 replies becomes blip in bsky_hot vibe
      → Users groove on it, driving engagement
      → Topic tags inspire new organic vibes
  """
  
  use WebSockex
  require Logger

  alias ElixirBlonk.{Vibes, HotPosts}

  @firehose_url "wss://bsky-relay.c.theo.io/subscribe?wantedCollections=app.bsky.feed.post"
  @vibe_pattern ~r/#vibe-([a-z0-9_]+)/i

  def start_link(opts \\ []) do
    Logger.info("Starting Bluesky firehose consumer...")

    WebSockex.start_link(
      @firehose_url,
      __MODULE__,
      %{processed_count: 0, link_count: 0},
      opts
    )
  end

  def handle_connect(_conn, state) do
    Logger.info("Connected to Bluesky firehose")
    {:ok, state}
  end

  def handle_frame({:text, msg}, state) do
    case Jason.decode(msg) do
      {:ok, decoded} ->
        process_message(decoded, state)
      {:error, reason} ->
        Logger.error("Failed to decode message: #{inspect(reason)}")
        {:ok, state}
    end
  end

  def handle_frame(frame, state) do
    Logger.debug("Received non-text frame: #{inspect(frame)}")
    {:ok, state}
  end

  def handle_disconnect(%{reason: {:local, reason}}, state) do
    Logger.info("Local disconnect with reason: #{inspect(reason)}")
    {:ok, state}
  end

  def handle_disconnect(disconnect_map, state) do
    Logger.error("Disconnected from firehose: #{inspect(disconnect_map)}")
    # Attempt to reconnect after 5 seconds
    Process.sleep(5000)
    {:reconnect, state}
  end

  defp process_message(%{"commit" => %{"record" => %{"text" => text}}} = full_msg, state) do
    if String.contains?(text, "#vibe-") do
      # Process synchronously to ensure proper database connection handling
      process_vibe_post(full_msg, text)
    end

    # Check for embeds and sample for bsky_hot content
    new_state = maybe_process_hot_content(full_msg, state)

    new_state = %{new_state | processed_count: new_state.processed_count + 1}

    if rem(new_state.processed_count, 1000) == 0 do
      Logger.info("Processed #{new_state.processed_count} posts from firehose (#{new_state.link_count} with links)")
    end

    {:ok, new_state}
  end

  defp process_message(_msg, state) do
    {:ok, state}
  end

  defp process_vibe_post(full_msg, text) do
    # Extract vibe names from the text
    vibe_names = extract_vibe_names(text)

    # Get post metadata
    author_did = get_in(full_msg, ["did"])
    post_uri = build_post_uri(full_msg)
    timestamp = get_timestamp(full_msg)

    # Process each vibe mention
    Enum.each(vibe_names, fn vibe_name ->
      Logger.info("Detected vibe mention: #vibe-#{vibe_name} from #{author_did}")

      # Record the mention
      case Vibes.record_vibe_mention(%{
        vibe_name: vibe_name,
        author_did: author_did,
        post_uri: post_uri,
        mentioned_at: timestamp
      }) do
        {:ok, mention} ->
          Logger.debug("Recorded vibe mention: #{inspect(mention)}")
          # The record_vibe_mention function already checks for emergence

        {:error, reason} ->
          Logger.error("Failed to record vibe mention: #{inspect(reason)}")
      end
    end)
  end

  defp extract_vibe_names(text) do
    @vibe_pattern
    |> Regex.scan(text)
    |> Enum.map(fn [_full_match, vibe_name] -> String.downcase(vibe_name) end)
    |> Enum.uniq()
  end

  defp build_post_uri(%{"did" => did, "commit" => %{"rkey" => rkey}}) do
    "at://#{did}/app.bsky.feed.post/#{rkey}"
  end
  defp build_post_uri(_), do: nil

  defp get_timestamp(%{"commit" => %{"record" => %{"createdAt" => created_at}}}) do
    case DateTime.from_iso8601(created_at) do
      {:ok, datetime, _} -> datetime
      _ -> DateTime.utc_now()
    end
  end
  defp get_timestamp(_), do: DateTime.utc_now()

  defp maybe_process_hot_content(full_msg, state) do
    # Check if the post has embeds (links)
    embeds = get_in(full_msg, ["commit", "record", "embed"])

    if embeds && has_external_link?(embeds) do
      new_state = %{state | link_count: state.link_count + 1}

      # Sample 1 in 10 posts with links
      if rem(new_state.link_count, 10) == 0 do
        process_potential_hot_content(full_msg)
      end

      new_state
    else
      state
    end
  end

  defp has_external_link?(%{"$type" => "app.bsky.embed.external", "external" => _}), do: true
  defp has_external_link?(%{"$type" => "app.bsky.embed.recordWithMedia", "media" => media}), do: has_external_link?(media)
  defp has_external_link?(_), do: false

  defp process_potential_hot_content(full_msg) do
    try do
      author_did = get_in(full_msg, ["did"])
      post_uri = build_post_uri(full_msg)
      text = get_in(full_msg, ["commit", "record", "text"]) || ""
      embed = get_in(full_msg, ["commit", "record", "embed"])
      external_url = extract_external_url(embed)

      Logger.info("Saving potential hot content from #{author_did}")
      
      # Save the post for later processing instead of checking immediately
      hot_post_params = %{
        post_uri: post_uri,
        author_did: author_did,
        text: text,
        external_url: external_url,
        record_data: full_msg
      }
      
      case HotPosts.create_hot_post(hot_post_params) do
        {:ok, hot_post} ->
          Logger.debug("Saved hot post candidate: #{hot_post.post_uri}")
        
        {:error, %Ecto.Changeset{errors: [post_uri: {"has already been taken", _}]}} ->
          # Duplicate post URI - this is fine, ignore silently
          :ok
        
        {:error, reason} ->
          Logger.warning("Failed to save hot post: #{inspect(reason)}")
      end
    rescue
      error ->
        Logger.error("Error processing potential hot content: #{inspect(error)}")
        Logger.error("Full message: #{inspect(full_msg)}")
    end
  end


  defp extract_external_url(%{"$type" => "app.bsky.embed.external", "external" => %{"uri" => uri}}), do: uri
  defp extract_external_url(%{"$type" => "app.bsky.embed.recordWithMedia", "media" => media}), do: extract_external_url(media)
  defp extract_external_url(_), do: nil


end
