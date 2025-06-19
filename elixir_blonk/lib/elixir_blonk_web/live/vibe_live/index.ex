defmodule ElixirBlonkWeb.VibeLive.Index do
  use ElixirBlonkWeb, :live_view

  alias ElixirBlonk.Vibes

  @impl true
  def mount(_params, _session, socket) do
    if connected?(socket) do
      ElixirBlonkWeb.Endpoint.subscribe("vibes:emerged")
    end
    
    vibes = Vibes.list_vibes_by_pulse()
    emerging_vibes = Vibes.list_emerging_vibes()
    vibe_stats = Vibes.get_vibe_mention_stats()
    
    {:ok, 
     socket
     |> assign(:vibes, vibes)
     |> assign(:emerging_vibes, emerging_vibes)
     |> assign(:vibe_stats, vibe_stats)}
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :index, _params) do
    socket
    |> assign(:page_title, "Vibes")
  end

  defp apply_action(socket, :emerging, _params) do
    socket
    |> assign(:page_title, "Emerging Vibes")
  end

  @impl true
  def handle_event("join_vibe", %{"vibe-id" => vibe_id}, socket) do
    # Placeholder DID for now
    member_did = "did:plc:user123"
    vibe = Vibes.get_vibe!(vibe_id)
    
    case Vibes.join_vibe(member_did, vibe_id, %{
      "uri" => "at://blonk.app/vibe_member/#{Ecto.UUID.generate()}",
      "cid" => "bafyrei#{:crypto.strong_rand_bytes(32) |> Base.encode32(case: :lower, padding: false)}",
      "vibe_uri" => vibe.uri
    }) do
      {:ok, _} ->
        vibes = Vibes.list_vibes_by_pulse()
        {:noreply, 
         socket
         |> assign(:vibes, vibes)
         |> put_flash(:info, "Joined vibe successfully")}
      
      {:error, _} ->
        {:noreply, put_flash(socket, :error, "Could not join vibe")}
    end
  end

  @impl true
  def handle_info({:vibe_emerged, vibe}, socket) do
    vibes = Vibes.list_vibes_by_pulse()
    vibe_stats = Vibes.get_vibe_mention_stats()
    
    {:noreply, 
     socket
     |> assign(:vibes, vibes)
     |> assign(:vibe_stats, vibe_stats)
     |> put_flash(:info, "New vibe emerged: #{vibe.name}! 🎉")}
  end

  # Helper function for vibe border colors
  defp get_border_color(%{color: color}) when is_binary(color), do: "border-blue-400"
  defp get_border_color(%{name: name}) do
    case String.contains?(name, ["sunset", "orange"]) do
      true -> "border-orange-400"
      false -> case String.contains?(name, ["green", "nature"]) do
        true -> "border-green-400"
        false -> case String.contains?(name, ["pink", "sparkle"]) do
          true -> "border-pink-400"
          false -> case String.contains?(name, ["yellow", "sun"]) do
            true -> "border-yellow-400"
            false -> "border-blue-400"
          end
        end
      end
    end
  end
  defp get_border_color(_), do: "border-blue-400"
end