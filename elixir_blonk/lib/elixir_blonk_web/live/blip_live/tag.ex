defmodule ElixirBlonkWeb.BlipLive.Tag do
  use ElixirBlonkWeb, :live_view

  alias ElixirBlonk.Blips
  alias ElixirBlonk.Grooves

  @impl true
  def mount(%{"tag" => tag}, _session, socket) do
    if connected?(socket), do: ElixirBlonkWeb.Endpoint.subscribe("blips")
    
    blips = Blips.list_blips_by_tag(tag)
    
    {:ok, 
     socket
     |> assign(:tag, tag)
     |> stream(:blips, blips)}
  end

  @impl true
  def handle_params(_params, _url, socket) do
    {:noreply, 
     socket
     |> assign(:page_title, "##{socket.assigns.tag} - Blonk")}
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
    if socket.assigns.tag in blip.tags do
      {:noreply, stream_insert(socket, :blips, blip, at: 0)}
    else
      {:noreply, socket}
    end
  end

  def handle_info({:blip_updated, blip}, socket) do
    if socket.assigns.tag in blip.tags do
      {:noreply, stream_insert(socket, :blips, blip)}
    else
      {:noreply, socket}
    end
  end
end