defmodule ElixirBlonk.ATProto.SimpleSession do
  @moduledoc """
  Minimal session manager for Blonk's ATProto authentication needs.
  
  This GenServer maintains a single authenticated ATProto client for the entire
  application, replacing complex session management with a simple, reliable pattern
  that aligns with Blonk's "fail fast" philosophy.
  
  ## Why Simple?
  
  **Complex session management was causing authentication headaches:**
  - Over-engineered refresh token logic
  - Unnecessary client wrapper abstractions  
  - Silent failures that broke community features
  - Debugging nightmares with nested state management
  
  ## New Approach: One Client, Clear Failures
  
  - **Authenticate once** on startup with app password
  - **Store client** in GenServer for all requests to use
  - **Fail immediately** if authentication fails (no retries)
  - **Crash the system** rather than silently degrade
  
  ## Blonk Integration
  
  **Critical for community features** that depend on ATProto:
  - HotPostSweeper needs authenticated calls to check reply counts
  - Blip creation requires valid sessions to store records
  - Tag system depends on reliable ATProto record creation
  - Firehose processing must authenticate to analyze engagement
  
  ## Failure Philosophy
  
  **Better to crash than confuse users:**
  - Authentication failure = system shutdown (as intended)
  - No degraded mode where some features silently break
  - Clear error messages in logs for debugging
  - Forces ops teams to fix auth issues immediately
  
  ## Usage Pattern
  
      # System startup
      {:ok, client} = SimpleSession.get_client()
      
      # All services use the same authenticated client
      ATProto.create_blip(client, blip)
      ATProto.get_post_engagement(client, post_uri)
      ATProto.create_tag(client, tag)
  
  ## Performance Benefits
  
  - **No per-request auth overhead** - client reused across all calls
  - **No session refresh logic** - app passwords are long-lived
  - **No complex state synchronization** - single source of truth
  - **Predictable memory usage** - one client struct for entire app
  
  ## Error Recovery
  
  **Intentionally minimal** - authentication should "just work":
  - No automatic retries (app passwords rarely fail)
  - No graceful degradation (would confuse community features)
  - System restart required for auth failures (clear resolution path)
  """
  
  use GenServer
  require Logger

  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @doc """
  Get the authenticated ATProto client.
  """
  def get_client do
    GenServer.call(__MODULE__, :get_client)
  end

  # GenServer callbacks

  @impl true
  def init(_opts) do
    Logger.info("Authenticating with ATProto...")
    
    case ElixirBlonk.ATProto.authenticate() do
      {:ok, client} ->
        Logger.info("ATProto authentication successful")
        {:ok, %{client: client}}
        
      {:error, reason} ->
        Logger.error("CRITICAL: ATProto authentication failed: #{inspect(reason)}")
        {:stop, {:atproto_auth_failed, reason}}
    end
  end

  @impl true
  def handle_call(:get_client, _from, %{client: client} = state) do
    {:reply, {:ok, client}, state}
  end
end