defmodule ElixirBlonkWeb.BlipLive.FormComponent do
  use ElixirBlonkWeb, :live_component

  alias ElixirBlonk.Blips
  alias ElixirBlonk.Vibes

  @impl true
  def render(assigns) do
    ~H"""
    <div class="max-w-2xl mx-auto">
      <div class="bg-white rounded-lg shadow-lg p-8">
        <h2 class="text-2xl text-gray-700 mb-8 text-center">transmit a new blip</h2>

        <.simple_form
          for={@form}
          id="blip-form"
          phx-target={@myself}
          phx-change="validate"
          phx-submit="save"
          class="space-y-6"
        >
        <div>
          <label class="block text-gray-700 text-sm font-medium mb-3">signal</label>
          <.input field={@form[:title]} type="text" placeholder="What's on the radar?" class="w-full border border-gray-300 rounded-lg px-4 py-3 focus:ring-2 focus:ring-blue-500 focus:border-transparent" />
        </div>
        
        <div>
          <label class="block text-gray-700 text-sm font-medium mb-3">frequency (optional)</label>
          <.input field={@form[:url]} type="url" placeholder="https://..." class="w-full border border-gray-300 rounded-lg px-4 py-3 focus:ring-2 focus:ring-blue-500 focus:border-transparent" />
          <div class="text-xs text-gray-500 mt-2">link to external content</div>
        </div>
        
        <div>
          <label class="block text-gray-700 text-sm font-medium mb-3">transmission details (optional)</label>
          <.input field={@form[:body]} type="textarea" placeholder="Additional context or thoughts..." rows="4" class="w-full border border-gray-300 rounded-lg px-4 py-3 focus:ring-2 focus:ring-blue-500 focus:border-transparent resize-none" />
        </div>
        
        <div>
          <label class="block text-gray-700 text-sm font-medium mb-3">vibe</label>
          <.input 
            field={@form[:vibe_id]} 
            type="select" 
            prompt="-- choose a vibe --"
            options={Enum.map(@vibes, &{"#{&1.emoji} #{&1.name} - #{&1.mood}", &1.id})}
            class="w-full border border-gray-300 rounded-lg px-4 py-3 focus:ring-2 focus:ring-blue-500 focus:border-transparent"
          />
          <div class="text-xs text-gray-500 mt-2">select the mood for your blip</div>
        </div>
        
        <div>
          <label class="block text-gray-700 text-sm font-medium mb-3">tags</label>
          <.input field={@form[:tags]} type="text" placeholder="space separated tags" class="w-full border border-gray-300 rounded-lg px-4 py-3 focus:ring-2 focus:ring-blue-500 focus:border-transparent" />
          <div class="text-xs text-gray-500 mt-2">e.g., programming atproto bluesky</div>
        </div>
        
        <:actions>
          <div class="flex justify-center pt-4">
            <.button phx-disable-with="transmitting..." class="bg-blue-600 text-white px-8 py-3 rounded-lg hover:bg-blue-700 font-medium">
              transmit blip
            </.button>
          </div>
        </:actions>
      </.simple_form>
      </div>
    </div>
    """
  end

  @impl true
  def update(%{blip: blip} = assigns, socket) do
    changeset = Blips.Blip.changeset(blip, %{})
    vibes = Vibes.list_vibes()

    {:ok,
     socket
     |> assign(assigns)
     |> assign(:vibes, vibes)
     |> assign_form(changeset)}
  end

  @impl true
  def handle_event("validate", %{"blip" => blip_params}, socket) do
    changeset =
      socket.assigns.blip
      |> Blips.Blip.changeset(blip_params)
      |> Map.put(:action, :validate)

    {:noreply, assign_form(socket, changeset)}
  end

  def handle_event("save", %{"blip" => blip_params}, socket) do
    save_blip(socket, socket.assigns.action, blip_params)
  end

  defp save_blip(socket, :new, blip_params) do
    # If vibe_id was preset in the blip, ensure it's included
    blip_params = if socket.assigns.blip.vibe_id && (blip_params["vibe_id"] == "" || is_nil(blip_params["vibe_id"])) do
      Map.put(blip_params, "vibe_id", to_string(socket.assigns.blip.vibe_id))
    else
      blip_params
    end
    
    # Process tags (convert space-separated string to list)
    blip_params = if blip_params["tags"] && is_binary(blip_params["tags"]) do
      tags = blip_params["tags"]
        |> String.split()
        |> Enum.map(&String.trim/1)
        |> Enum.reject(&(&1 == ""))
      Map.put(blip_params, "tags", tags)
    else
      blip_params
    end
    
    # Add ATProto-related fields - use current user's DID if available
    author_did = case socket.assigns[:current_user] do
      %{did: did} when is_binary(did) -> did
      _ -> "did:plc:user123" # Fallback for non-authenticated users
    end
    
    blip_params = Map.merge(blip_params, %{
      "uri" => "at://blonk.app/blip/#{Ecto.UUID.generate()}",
      "cid" => "bafyrei#{:crypto.strong_rand_bytes(32) |> Base.encode32(case: :lower, padding: false)}",
      "author_did" => author_did,
      "indexed_at" => DateTime.utc_now()
    })
    
    # Set vibe_uri if vibe_id is provided
    blip_params = if blip_params["vibe_id"] && blip_params["vibe_id"] != "" do
      vibe = Vibes.get_vibe!(blip_params["vibe_id"])
      Map.put(blip_params, "vibe_uri", vibe.uri)
    else
      blip_params
    end

    case Blips.create_blip(blip_params) do
      {:ok, blip} ->
        blip = ElixirBlonk.Repo.preload(blip, :vibe)
        
        # Try to create ATProto record if enabled
        if Application.get_env(:elixir_blonk, :atproto_enabled, false) do
          case ElixirBlonk.ATProto.SessionManager.get_client() do
            {:ok, client} ->
              case ElixirBlonk.ATProto.Client.create_blip(client, blip) do
                {:ok, %{uri: uri, cid: cid}} ->
                  # Update the blip with the real ATProto URI and CID
                  Blips.update_blip(blip, %{uri: uri, cid: cid})
                  
                {:error, reason} ->
                  require Logger
                  Logger.warning("Failed to create ATProto record for blip: #{inspect(reason)}")
              end
            
            {:error, reason} ->
              require Logger
              Logger.warning("No ATProto client available: #{inspect(reason)}")
          end
        end
        
        ElixirBlonkWeb.Endpoint.broadcast("blips", "blip_created", blip)
        
        {:noreply,
         socket
         |> put_flash(:info, "Blip transmitted successfully")
         |> push_patch(to: socket.assigns.patch)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign_form(socket, changeset)}
    end
  end

  defp assign_form(socket, %Ecto.Changeset{} = changeset) do
    assign(socket, :form, to_form(changeset))
  end
end