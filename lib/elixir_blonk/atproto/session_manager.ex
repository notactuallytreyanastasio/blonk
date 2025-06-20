defmodule ElixirBlonk.ATProto.SessionManager do
  @moduledoc """
  Manages ATProto session lifecycle.
  Maintains a single authenticated session for the application.
  """

  use GenServer
  require Logger

  alias ElixirBlonk.ATProto.Client

  @refresh_interval :timer.hours(1)

  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @doc """
  Gets the current authenticated client.
  """
  def get_client do
    GenServer.call(__MODULE__, :get_client)
  end

  @doc """
  Forces a session refresh.
  """
  def refresh_session do
    GenServer.cast(__MODULE__, :refresh_session)
  end

  # GenServer callbacks

  @impl true
  def init(_opts) do
    # Check if ATProto is enabled
    if Application.get_env(:elixir_blonk, :atproto_enabled, true) do
      Logger.info("Starting ATProto session manager")
      # Initialize session on startup
      send(self(), :init_session)
      {:ok, %{client: nil, session: nil}}
    else
      Logger.info("ATProto is disabled")
      {:ok, %{client: nil, session: nil, disabled: true}}
    end
  end

  @impl true
  def handle_call(:get_client, _from, %{disabled: true} = state) do
    {:reply, {:error, :disabled}, state}
  end

  def handle_call(:get_client, _from, %{client: nil} = state) do
    # Try to create session if we don't have one
    case create_and_store_session(state) do
      {:ok, new_state} ->
        {:reply, {:ok, new_state.client}, new_state}
      
      {:error, reason} ->
        {:reply, {:error, reason}, state}
    end
  end

  def handle_call(:get_client, _from, %{client: client} = state) do
    {:reply, {:ok, client}, state}
  end

  @impl true
  def handle_cast(:refresh_session, state) do
    case create_and_store_session(state) do
      {:ok, new_state} ->
        {:noreply, new_state}
      
      {:error, _reason} ->
        # Keep current session if refresh fails
        {:noreply, state}
    end
  end

  @impl true
  def handle_info(:init_session, state) do
    case create_and_store_session(state) do
      {:ok, new_state} ->
        # Schedule periodic refresh
        schedule_refresh()
        {:noreply, new_state}
      
      {:error, reason} ->
        Logger.error("CRITICAL: Failed to initialize ATProto session: #{inspect(reason)}")
        # This is a critical failure - the system cannot function without Bluesky authentication
        {:stop, {:atproto_auth_failed, reason}, state}
    end
  end

  def handle_info(:refresh_session, state) do
    case create_and_store_session(state) do
      {:ok, new_state} ->
        schedule_refresh()
        {:noreply, new_state}
      
      {:error, reason} ->
        Logger.error("CRITICAL: Failed to refresh ATProto session: #{inspect(reason)}")
        # Session refresh failure is critical - stop the process
        {:stop, {:atproto_refresh_failed, reason}, state}
    end
  end

  # Private functions

  defp create_and_store_session(_state) do
    case Client.create_session() do
      {:ok, %{client: client, session: session}} ->
        Logger.info("ATProto session created/refreshed")
        {:ok, %{client: client, session: session}}
      
      {:error, reason} = error ->
        Logger.error("Failed to create ATProto session: #{inspect(reason)}")
        error
    end
  end

  defp schedule_refresh do
    Process.send_after(self(), :refresh_session, @refresh_interval)
  end
end