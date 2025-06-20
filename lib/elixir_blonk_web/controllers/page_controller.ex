defmodule ElixirBlonkWeb.PageController do
  use ElixirBlonkWeb, :controller

  def home(conn, _params) do
    redirect(conn, to: ~p"/blips")
  end
end
