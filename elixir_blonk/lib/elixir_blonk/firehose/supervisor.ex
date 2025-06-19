defmodule ElixirBlonk.Firehose.Supervisor do
  use Supervisor
  require Logger

  def start_link(init_arg) do
    Supervisor.start_link(__MODULE__, init_arg, name: __MODULE__)
  end

  @impl true
  def init(_init_arg) do
    # Check if firehose is enabled in config
    if Application.get_env(:elixir_blonk, :firehose_enabled, true) do
      Logger.info("Starting Bluesky firehose supervisor")
      
      children = [
        {ElixirBlonk.Firehose.Consumer, name: ElixirBlonk.Firehose.Consumer}
      ]

      Supervisor.init(children, strategy: :one_for_one)
    else
      Logger.info("Bluesky firehose is disabled")
      Supervisor.init([], strategy: :one_for_one)
    end
  end
end