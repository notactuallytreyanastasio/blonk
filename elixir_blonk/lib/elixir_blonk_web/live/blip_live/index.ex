defmodule ElixirBlonkWeb.BlipLive.Index do
  use ElixirBlonkWeb, :live_view

  alias ElixirBlonk.Blips
  alias ElixirBlonk.Blips.Blip
  alias ElixirBlonk.Grooves

  @impl true
  def mount(_params, _session, socket) do
    if connected?(socket), do: ElixirBlonkWeb.Endpoint.subscribe("blips")
    
    {:ok, stream(socket, :blips, Blips.list_blips())}
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :index, _params) do
    socket
    |> assign(:page_title, "Blonk Radar")
    |> assign(:blip, nil)
  end

  defp apply_action(socket, :new, _params) do
    socket
    |> assign(:page_title, "New Blip")
    |> assign(:blip, %Blip{})
  end

  @impl true
  def handle_event("groove", %{"blip-id" => blip_id, "type" => groove_type}, socket) do
    # For now, using a placeholder DID
    author_did = "did:plc:user123"
    blip = Blips.get_blip!(blip_id)
    
    case Grooves.toggle_groove(author_did, blip.uri, groove_type, %{
      uri: "at://blonk.app/groove/#{Ecto.UUID.generate()}",
      cid: "bafyrei#{:crypto.strong_rand_bytes(32) |> Base.encode32(case: :lower, padding: false)}"
    }) do
      {:ok, _} ->
        updated_blip = Blips.get_blip!(blip_id)
        {:noreply, stream_insert(socket, :blips, updated_blip)}
      
      {:error, _} ->
        {:noreply, put_flash(socket, :error, "Could not groove blip")}
    end
  end

  @impl true
  def handle_info({:blip_created, blip}, socket) do
    {:noreply, stream_insert(socket, :blips, blip, at: 0)}
  end

  def handle_info({:blip_updated, blip}, socket) do
    {:noreply, stream_insert(socket, :blips, blip)}
  end

  # Helper function to get author handle from blip - public for template access
  def get_author_handle(blip) do
    case ElixirBlonk.Accounts.get_user_by_did(blip.author_did) do
      %{handle: handle} when is_binary(handle) -> handle
      _ -> "unknown"
    end
  end
end