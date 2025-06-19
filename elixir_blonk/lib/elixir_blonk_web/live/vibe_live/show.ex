defmodule ElixirBlonkWeb.VibeLive.Show do
  use ElixirBlonkWeb, :live_view

  alias ElixirBlonk.Vibes
  alias ElixirBlonk.Blips
  alias ElixirBlonk.Grooves

  @impl true
  def mount(%{"id" => id}, _session, socket) do
    if connected?(socket), do: ElixirBlonkWeb.Endpoint.subscribe("blips")
    
    vibe = Vibes.get_vibe!(id)
    blips = Blips.list_blips_by_vibe(vibe.uri)
    
    {:ok, 
     socket
     |> assign(:vibe, vibe)
     |> stream(:blips, blips)}
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :show, _params) do
    socket
    |> assign(:page_title, "#{socket.assigns.vibe.name} - Vibes")
    |> assign(:blip, nil)
  end

  defp apply_action(socket, :new, _params) do
    socket
    |> assign(:page_title, "New Blip - #{socket.assigns.vibe.name}")
    |> assign(:blip, %ElixirBlonk.Blips.Blip{vibe_id: socket.assigns.vibe.id})
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
  def handle_event("join_vibe", %{"vibe-id" => vibe_id}, socket) do
    # Placeholder DID for now
    member_did = "did:plc:user123"
    vibe = socket.assigns.vibe
    
    case Vibes.join_vibe(member_did, vibe_id, %{
      "uri" => "at://blonk.app/vibe_member/#{Ecto.UUID.generate()}",
      "cid" => "bafyrei#{:crypto.strong_rand_bytes(32) |> Base.encode32(case: :lower, padding: false)}",
      "vibe_uri" => vibe.uri
    }) do
      {:ok, _} ->
        updated_vibe = Vibes.get_vibe!(vibe_id)
        {:noreply, 
         socket
         |> assign(:vibe, updated_vibe)
         |> put_flash(:info, "Joined vibe successfully")}
      
      {:error, _} ->
        {:noreply, put_flash(socket, :error, "Could not join vibe")}
    end
  end

  @impl true
  def handle_info({:blip_created, blip}, socket) do
    if blip.vibe_uri == socket.assigns.vibe.uri do
      {:noreply, stream_insert(socket, :blips, blip, at: 0)}
    else
      {:noreply, socket}
    end
  end

  def handle_info({:blip_updated, blip}, socket) do
    if blip.vibe_uri == socket.assigns.vibe.uri do
      {:noreply, stream_insert(socket, :blips, blip)}
    else
      {:noreply, socket}
    end
  end
end