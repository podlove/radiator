defmodule RadiatorWeb.Components.ScrollArea do
  @moduledoc """
  The `RadiatorWeb.Components.ScrollArea` module provides a customizable scroll area component for Phoenix LiveView
  applications. This component enables efficient content scrolling with enhanced user
  experience and control.

  **The ScrollArea component offers**:
  - Customizable viewport dimensions
  - Optional scrollbars styling
  - Responsive design support
  - Cross-browser compatibility

  **It's particularly useful for**:
  - Long content sections
  - Dynamic content containers
  - Fixed-height panels
  - Overflow management
  - Mobile-friendly interfaces

  **Documentation:** https://mishka.tools/chelekom/docs/scroll-area
  """

  use Phoenix.Component

  @doc type: :component
  attr :id, :string,
    required: true,
    doc: "A unique identifier is used to manage state and interaction"

  attr :type, :string, default: "auto", doc: "hover, auto, never"
  attr :horizontal, :boolean, default: false, doc: "Determines height of wrapper"
  attr :vertical, :boolean, default: true, doc: "Determines height of wrapper"
  attr :height, :string, default: "h-96", doc: "Determines height of wrapper"
  attr :width, :string, default: "w-full", doc: "Determines width of wrapper"
  attr :padding, :string, default: "extra_small", doc: "Add paddings to content"
  attr :class, :string, default: nil, doc: "Custom CSS class for additional styling"
  attr :content_class, :string, default: nil, doc: "Custom CSS class for additional styling"
  attr :scrollbar_width, :string, default: "w-2", doc: "Custom CSS class for width of scrollbar y"

  attr :scrollbar_height, :string,
    default: "h-2",
    doc: "Custom CSS class for height of scrollbar x"

  attr :rest, :global,
    doc:
      "Global attributes can define defaults which are merged with attributes provided by the caller"

  slot :inner_block, required: true, doc: "Inner block that renders HEEx content"

  def scroll_area(assigns) do
    ~H"""
    <div
      id={@id}
      phx-hook="ScrollArea"
      phx-update="replace"
      role="region"
      class={["scroll-area-wrapper relative overflow-hidden group h-fit", @width, @class]}
      {@rest}
    >
      <div
        class={[
          "w-full overflow-auto relative scroll-viewport focus:outline-none",
          "[scrollbar-width:none] [&::-webkit-scrollbar]:hidden",
          @height
        ]}
        tabindex="0"
      >
        <div class={["scroll-content", padding_size(@padding), @content_class]}>
          {render_slot(@inner_block)}
        </div>
      </div>

      <div
        class={[
          "absolute right-0 top-0 h-full bg-black/5 rounded-lg scrollbar-y transition-all duration-400",
          custom_scrollbars_visibility(@type, @vertical),
          @scrollbar_width
        ]}
        aria-hidden="true"
      >
        <div class="absolute w-full bg-black/40 h-[20%] rounded-lg thumb-y"></div>
      </div>

      <div
        class={[
          "absolute left-0 bottom-0 w-full bg-black/5 rounded-lg transition-all duration-400 scrollbar-x",
          custom_scrollbars_visibility(@type, @horizontal),
          @scrollbar_height
        ]}
        aria-hidden="true"
      >
        <div class="absolute h-full bg-black/40 w-[20%] rounded-lg thumb-x"></div>
      </div>
    </div>
    """
  end

  defp padding_size("extra_small"), do: "p-1"

  defp padding_size("small"), do: "p-2"

  defp padding_size("medium"), do: "p-3"

  defp padding_size("large"), do: "p-4"

  defp padding_size("extra_large"), do: "p-5"

  defp padding_size("none"), do: nil

  defp padding_size(params) when is_binary(params), do: params

  defp custom_scrollbars_visibility("hover", true),
    do: "opacity-0 group-hover:opacity-100 group-focus-within:opacity-100"

  defp custom_scrollbars_visibility("auto", true), do: "opacity-100"
  defp custom_scrollbars_visibility("never", true), do: "opacity-0 pointer-events-none"
  defp custom_scrollbars_visibility(_, false), do: "opacity-0 pointer-events-none"
end
