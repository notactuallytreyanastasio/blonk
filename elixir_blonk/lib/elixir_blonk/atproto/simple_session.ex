defmodule ElixirBlonk.ATProto.SimpleSession do
  @moduledoc """
  Simple session manager that maintains a single authenticated ATProto client.
  
  This replaces the complex SessionManager with a straightforward approach:
  - Authenticate once on startup
  - Store the client in GenServer state  
  - Provide the client for API calls
  - Fail fast if authentication fails
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