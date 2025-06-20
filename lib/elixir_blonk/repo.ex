defmodule ElixirBlonk.Repo do
  use Ecto.Repo,
    otp_app: :elixir_blonk,
    adapter: Ecto.Adapters.Postgres
end
