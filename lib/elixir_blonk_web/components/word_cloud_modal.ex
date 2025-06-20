defmodule ElixirBlonkWeb.Components.WordCloudModal do
  use Phoenix.Component
  import ElixirBlonkWeb.CoreComponents

  attr :show, :boolean, required: true
  attr :vibe, :map, default: nil
  attr :tag_frequency, :list, default: []
  attr :on_close, :string, required: true

  def word_cloud_modal(assigns) do
    assigns = assign(assigns, :top_tags, Enum.take(assigns.tag_frequency, 10))

    ~H"""
    <div :if={@show} class="fixed inset-0 bg-gray-600 bg-opacity-50 overflow-y-auto h-full w-full z-50" phx-click={@on_close}>
      <div class="relative top-20 mx-auto p-5 border w-11/12 md:w-3/4 lg:w-1/2 shadow-lg rounded-md bg-white" phx-click="prevent_close">
        <div class="mt-3 text-center">
          <!-- Modal Header -->
          <div class="flex justify-between items-center mb-6">
            <h3 class="text-lg font-medium text-gray-900">
              <span class="text-2xl mr-2">{@vibe && @vibe.emoji || "🌊"}</span>
              {@vibe && @vibe.name} Word Cloud
            </h3>
            <button phx-click={@on_close} class="text-gray-400 hover:text-gray-600">
              <span class="sr-only">Close</span>
              <.icon name="hero-x-mark" class="h-6 w-6" />
            </button>
          </div>

          <!-- Word Cloud Content -->
          <div class="mb-6">
            <div :if={@tag_frequency != []} class="space-y-6">
              <!-- Visual Word Cloud -->
              <div class="flex flex-wrap justify-center items-center gap-2 p-6 bg-gray-50 rounded-lg min-h-[200px]">
                <span
                  :for={{tag, count} <- @top_tags}
                  class={"font-semibold #{get_font_size(@top_tags, count)} #{get_color(@top_tags, count)} hover:text-blue-700 cursor-pointer transition-colors"}
                  title={"#{count} mentions"}
                >
                  {tag}
                </span>
              </div>
              
              <!-- Tag Statistics -->
              <div class="text-left">
                <h4 class="font-medium text-gray-700 mb-2">Top 10 Tag Frequencies:</h4>
                <div class="grid grid-cols-2 md:grid-cols-3 gap-2 text-sm">
                  <div :for={{tag, count} <- @top_tags} class="flex justify-between bg-gray-100 px-2 py-1 rounded">
                    <span class="text-gray-700">{tag}</span>
                    <span class="text-gray-500 font-medium">{count}</span>
                  </div>
                </div>
                <p :if={length(@tag_frequency) > 10} class="text-xs text-gray-500 mt-2">
                  ... and {length(@tag_frequency) - 10} more tags
                </p>
              </div>
            </div>
            
            <div :if={@tag_frequency == []} class="p-8 text-gray-500">
              <.icon name="hero-tag" class="mx-auto h-12 w-12 text-gray-400" />
              <p class="mt-2">No tags found for this vibe yet.</p>
              <p class="text-sm">Tags will appear here as blips are posted.</p>
            </div>
          </div>

          <!-- Modal Footer -->
          <div class="flex justify-end space-x-3">
            <button phx-click={@on_close} class="px-4 py-2 bg-gray-300 text-gray-700 rounded-md hover:bg-gray-400 transition-colors">
              Close
            </button>
          </div>
        </div>
      </div>
    </div>
    """
  end

  defp get_font_size(top_tags, count) do
    max_count = top_tags |> List.first() |> elem(1)
    relative_size = max(1, div(count * 5, max_count))
    
    case relative_size do
      5 -> "text-4xl"
      4 -> "text-3xl"
      3 -> "text-2xl"
      2 -> "text-xl"
      _ -> "text-lg"
    end
  end

  defp get_color(top_tags, count) do
    max_count = top_tags |> List.first() |> elem(1)
    relative_size = max(1, div(count * 5, max_count))
    
    case relative_size do
      5 -> "text-blue-600"
      4 -> "text-blue-500"
      3 -> "text-blue-400"
      2 -> "text-gray-600"
      _ -> "text-gray-500"
    end
  end
end