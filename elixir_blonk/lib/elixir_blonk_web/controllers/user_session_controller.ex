defmodule ElixirBlonkWeb.UserSessionController do
  use ElixirBlonkWeb, :controller

  alias ElixirBlonk.Accounts
  alias ElixirBlonkWeb.UserAuth

  def new(conn, _params) do
    render(conn, :new, error_message: nil)
  end

  def create(conn, %{"user" => user_params}) do
    handle = user_params["handle"] || user_params["email"] 
    password = user_params["password"]

    case Accounts.authenticate_with_atproto(handle, password) do
      {:ok, user} ->
        conn
        |> put_flash(:info, "Welcome to Blonk, #{user.display_name || user.handle}! 🎉")
        |> UserAuth.log_in_user(user, user_params)
        
      {:error, :invalid_credentials} ->
        render(conn, :new, error_message: "Invalid Bluesky handle or password")
        
      {:error, :network_error} ->
        render(conn, :new, error_message: "Unable to connect to Bluesky. Please try again.")
        
      {:error, reason} ->
        require Logger
        Logger.warning("ATProto authentication failed: #{inspect(reason)}")
        render(conn, :new, error_message: "Authentication failed. Please check your credentials.")
    end
  end

  def delete(conn, _params) do
    conn
    |> put_flash(:info, "Logged out successfully.")
    |> UserAuth.log_out_user()
  end
end
