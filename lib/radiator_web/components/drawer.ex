defmodule RadiatorWeb.Components.Drawer do
  @moduledoc """
  The `RadiatorWeb.Components.Drawer` module provides a flexible and customizable drawer component
  for use in Phoenix LiveView applications.

  ## Features:
  - **Positioning:** Drawers can be positioned on the left, right, top, or bottom of the screen.
  - **Styling Variants:** Offers several styling options like `default`, `outline`,
  `transparent`, `shadow`, and `unbordered`.
  - **Color Themes:** Supports a variety of predefined color themes, including `primary`,
  `secondary`, `success`, `danger`, `info`, and more.
  - **Customizable:** Allows customization of border style, size, border radius,
  and padding to fit various design needs.
  - **Interactive:** Integrated with `Phoenix.LiveView.JS` for show/hide functionality and
  interaction management.
  - **Slots Support:** Includes slots for adding a custom header and inner content,
  with full HEEx support for dynamic rendering.

  **Documentation:** https://mishka.tools/chelekom/docs/drawer
  """
  use Phoenix.Component
  alias Phoenix.LiveView.JS
  use Gettext, backend: RadiatorWeb.Gettext
  import RadiatorWeb.Components.Icon, only: [icon: 1]

  @doc """
  A `drawer` component for displaying content in a sliding panel. It can be positioned on the left or
  right side of the viewport and controlled using custom JavaScript actions.

  ## Examples

  ```elixir
  <.drawer id="acc-left" show={true}>
    Lorem ipsum dolor sit amet consectetur adipisicing elit. Commodi ea atque soluta
    praesentium quidem dicta sapiente accusamus nihil.
  </.drawer>

  <.drawer id="acc-right" title_class="text-2xl font-light" position="right">
    <:header><p>Right Drawer</p></:header>
    Lorem ipsum dolor sit amet consectetur adipisicing elit. Commodi ea atque soluta praesentium
    quidem dicta sapiente accusamus nihil.
  </.drawer>
  ```
  """
  @doc type: :component
  attr :id, :string,
    required: true,
    doc: "A unique identifier is used to manage state and interaction"

  attr :title, :string, default: nil, doc: "Specifies the title of the element"
  attr :title_class, :string, default: nil, doc: "Determines custom class for the title"
  attr :variant, :string, default: "base", doc: "Determines the style"
  attr :color, :string, default: "natural", doc: "Determines color theme"

  attr :size, :string,
    default: "large",
    doc:
      "Determines the overall size of the elements, including padding, font size, and other items"

  attr :border, :string, default: "extra_small", doc: "Determines border style"
  attr :position, :string, default: "left", doc: "Determines the element position"

  attr :class, :string,
    default: nil,
    doc: "Custom CSS class for additional styling to drawer wrapper"

  attr :close_class, :string,
    default: nil,
    doc: "Custom CSS class for additional styling to close button"

  attr :content_class, :string,
    default: nil,
    doc: "Custom CSS class for additional styling to content"

  attr :wrapper_class, :string,
    default: nil,
    doc: "Custom CSS class for additional styling to wrapper"

  attr :overlay_class, :string,
    default: nil,
    doc: "Custom CSS class for additional styling to overlay"

  attr :on_hide, JS, default: %JS{}, doc: "Custom JS module for on_hide action"
  attr :on_show, JS, default: %JS{}, doc: "Custom JS module for on_show action"
  attr :on_hide_away, JS, default: %JS{}, doc: "Custom JS module for on_hide_away action"
  attr :show, :boolean, default: false, doc: "Show element"

  attr :rest, :global,
    doc:
      "Global attributes can define defaults which are merged with attributes provided by the caller"

  slot :header, required: false, doc: "Specifies element's header that accepts heex"
  slot :inner_block, required: false, doc: "Inner block that renders HEEx content"

  def drawer(assigns) do
    ~H"""
    <div
      id={@id}
      phx-mounted={@show && show_drawer(@on_show, @id, @position)}
      phx-remove={hide_drawer(@id, @position)}
      class={[
        "fixed z-50 transition-transform",
        "[&:not(.drawer-showed)_.drawer-overlay]:opacity-0 [&.drawer-showed_.drawer-overlay]:opacity-100",
        translate_position(@position),
        position_class(@position),
        @class
      ]}
      tabindex="-1"
      role="dialog"
      aria-modal="true"
      aria-labelledby={"#{@id}-#{@position}-title"}
      aria-describedby={"#{@id}-#{@position}-desc"}
      {@rest}
    >
      <div
        class={[
          "fixed bg-black/60 inset-0 -z-10 transition-all duration-[0.4s] delay-[0.1s] ease-in-out drawer-overlay",
          @overlay_class
        ]}
        role="presentation"
        aria-hidden="true"
      >
      </div>

      <div
        phx-click-away={hide_drawer(@on_hide_away, @id, @position)}
        phx-window-keydown={hide_drawer(@on_hide, @id, @position)}
        phx-key="escape"
        class={[
          "p-2 overflow-y-auto",
          @position in ["left", "right"] && "h-full",
          size_class(@size, @position),
          border_class(@border, @position, @variant),
          color_variant(@variant, @color),
          @wrapper_class
        ]}
        tabindex="0"
        role="document"
      >
        <div class="flex flex-row-reverse justify-between items-center gap-5 mb-2">
          <button
            type="button"
            phx-click={JS.exec(@on_hide, "phx-remove", to: "##{@id}")}
            aria-label={gettext("Close menu")}
            class={@close_class}
          >
            <.icon name="hero-x-mark" />
            <span class="sr-only">{gettext("Close menu")}</span>
          </button>

          <h5
            :if={title = @title || render_slot(@header)}
            id={"#{@id}-#{@position}-title"}
            class={[@title_class || "text-lg font-semibold"]}
          >
            {title}
          </h5>
        </div>

        <div id={"#{@id}-#{@position}-desc"} class="sr-only">
          {gettext("Drawer content")}
        </div>

        <div class={@content_class}>
          {render_slot(@inner_block)}
        </div>
      </div>
    </div>
    """
  end

  defp translate_position("left"), do: "-translate-x-full"
  defp translate_position("right"), do: "translate-x-full"
  defp translate_position("bottom"), do: "translate-y-full"
  defp translate_position("top"), do: "-translate-y-full"
  defp translate_position(params) when is_binary(params), do: params

  defp position_class("left"), do: "top-0 left-0 h-screen"
  defp position_class("right"), do: "top-0 right-0 h-screen"
  defp position_class("top"), do: "top-0 inset-x-0 w-full"
  defp position_class("bottom"), do: "bottom-0 inset-x-0 w-full"
  defp position_class(params) when is_binary(params), do: params

  defp border_class(_, _, variant)
       when variant in [
              "default",
              "shadow",
              "transparent",
              "gradient"
            ],
       do: nil

  defp border_class("extra_small", "left", _), do: "border-r"
  defp border_class("small", "left", _), do: "border-r-2"
  defp border_class("medium", "left", _), do: "border-r-[3px]"
  defp border_class("large", "left", _), do: "border-r-4"
  defp border_class("extra_large", "left", _), do: "border-r-[5px]"

  defp border_class("extra_small", "right", _), do: "border-l"
  defp border_class("small", "right", _), do: "border-l-2"
  defp border_class("medium", "right", _), do: "border-l-[3px]"
  defp border_class("large", "right", _), do: "border-l-4"
  defp border_class("extra_large", "right", _), do: "border-l-[5px]"

  defp border_class("extra_small", "top", _), do: "border-b"
  defp border_class("small", "top", _), do: "border-b-2"
  defp border_class("medium", "top", _), do: "border-b-[3px]"
  defp border_class("large", "top", _), do: "border-b-4"
  defp border_class("extra_large", "top", _), do: "border-b-[5px]"

  defp border_class("extra_small", "bottom", _), do: "border-t"
  defp border_class("small", "bottom", _), do: "border-t-2"
  defp border_class("medium", "bottom", _), do: "border-t-[3px]"
  defp border_class("large", "bottom", _), do: "border-t-4"
  defp border_class("extra_large", "bottom", _), do: "border-t-[5px]"

  defp border_class(params, _, _) when is_binary(params), do: params

  defp size_class("extra_small", "left"), do: "w-60"

  defp size_class("small", "left"), do: "w-64"

  defp size_class("medium", "left"), do: "w-72"

  defp size_class("large", "left"), do: "w-80"

  defp size_class("extra_large", "left"), do: "w-96"

  defp size_class("extra_small", "right"), do: "w-60"

  defp size_class("small", "right"), do: "w-64"

  defp size_class("medium", "right"), do: "w-72"

  defp size_class("large", "right"), do: "w-80"

  defp size_class("extra_large", "right"), do: "w-96"

  defp size_class("extra_small", "top"), do: "min-h-32"

  defp size_class("small", "top"), do: "min-h-36"

  defp size_class("medium", "top"), do: "min-h-40"

  defp size_class("large", "top"), do: "min-h-44"

  defp size_class("extra_large", "top"), do: "min-h-48"

  defp size_class("extra_small", "bottom"), do: "min-h-32"

  defp size_class("small", "bottom"), do: "min-h-36"

  defp size_class("medium", "bottom"), do: "min-h-40"

  defp size_class("large", "bottom"), do: "min-h-44"

  defp size_class("extra_large", "bottom"), do: "min-h-48"

  defp size_class(params, _) when is_binary(params), do: params

  defp color_variant("base", _) do
    [
      "bg-white text-base-text-light border-base-border-light",
      "dark:bg-base-bg-dark dark:text-base-text-dark dark:border-base-border-dark"
    ]
  end

  defp color_variant("default", "white") do
    [
      "bg-white text-black"
    ]
  end

  defp color_variant("default", "dark") do
    [
      "bg-default-dark-bg text-white"
    ]
  end

  defp color_variant("default", "natural") do
    [
      "bg-natural-bg-dark text-white",
      "dark:bg-natural-dark dark:text-black"
    ]
  end

  defp color_variant("default", "primary") do
    [
      "bg-primary-light text-white",
      "dark:bg-primary-dark dark:text-black"
    ]
  end

  defp color_variant("default", "secondary") do
    [
      "bg-secondary-light text-white",
      "dark:bg-secondary-dark dark:text-black"
    ]
  end

  defp color_variant("default", "success") do
    [
      "bg-success-light text-white",
      "dark:bg-success-dark dark:text-black"
    ]
  end

  defp color_variant("default", "warning") do
    [
      "bg-warning-light text-white",
      "dark:bg-warning-dark dark:text-black"
    ]
  end

  defp color_variant("default", "danger") do
    [
      "bg-danger-light text-white",
      "dark:bg-danger-dark dark:text-black"
    ]
  end

  defp color_variant("default", "info") do
    [
      "bg-info-light text-white",
      "dark:bg-info-dark dark:text-black"
    ]
  end

  defp color_variant("default", "misc") do
    [
      "bg-misc-light text-white",
      "dark:bg-misc-dark dark:text-black"
    ]
  end

  defp color_variant("default", "dawn") do
    [
      "bg-dawn-light text-white",
      "dark:bg-dawn-dark dark:text-black"
    ]
  end

  defp color_variant("default", "silver") do
    [
      "bg-silver-light text-white",
      "dark:bg-silver-dark dark:text-black"
    ]
  end

  defp color_variant("outline", "natural") do
    [
      "bg-transparent text-natural-light border-natural-light",
      "dark:text-natural-dark dark:border-natural-dark"
    ]
  end

  defp color_variant("outline", "primary") do
    [
      "bg-transparent text-primary-light border-primary-light",
      "dark:text-primary-dark dark:border-primary-dark"
    ]
  end

  defp color_variant("outline", "secondary") do
    [
      "bg-transparent text-secondary-light border-secondary-light",
      "dark:text-secondary-dark dark:border-secondary-dark"
    ]
  end

  defp color_variant("outline", "success") do
    [
      "bg-transparent text-success-light border-success-light",
      "dark:text-success-dark dark:border-success-dark"
    ]
  end

  defp color_variant("outline", "warning") do
    [
      "bg-transparent text-warning-light border-warning-light",
      "dark:text-warning-dark dark:border-warning-dark"
    ]
  end

  defp color_variant("outline", "danger") do
    [
      "bg-transparent text-danger-light border-danger-light",
      "dark:text-danger-dark dark:border-danger-dark"
    ]
  end

  defp color_variant("outline", "info") do
    [
      "bg-transparent text-info-light border-info-light",
      "dark:text-info-dark dark:border-info-dark"
    ]
  end

  defp color_variant("outline", "misc") do
    [
      "bg-transparent text-misc-light border-misc-light",
      "dark:text-misc-dark dark:border-misc-dark"
    ]
  end

  defp color_variant("outline", "dawn") do
    [
      "bg-transparent text-dawn-light border-dawn-light",
      "dark:text-dawn-dark dark:border-dawn-dark"
    ]
  end

  defp color_variant("outline", "silver") do
    [
      "bg-transparent text-silver-light border-silver-light",
      "dark:text-silver-dark dark:border-silver-dark"
    ]
  end

  defp color_variant("transparent", "natural") do
    [
      "bg-transparent text-natural-light",
      "dark:text-natural-dark border-transparent"
    ]
  end

  defp color_variant("transparent", "primary") do
    [
      "bg-transparent text-primary-light",
      "dark:text-primary-dark border-transparent"
    ]
  end

  defp color_variant("transparent", "secondary") do
    [
      "bg-transparent text-secondary-light",
      "dark:text-secondary-dark border-transparent"
    ]
  end

  defp color_variant("transparent", "success") do
    [
      "bg-transparent text-success-light",
      "dark:text-success-dark border-transparent"
    ]
  end

  defp color_variant("transparent", "warning") do
    [
      "bg-transparent text-warning-light",
      "dark:text-warning-dark border-transparent"
    ]
  end

  defp color_variant("transparent", "danger") do
    [
      "bg-transparent text-danger-light",
      "dark:text-danger-dark border-transparent"
    ]
  end

  defp color_variant("transparent", "info") do
    [
      "bg-transparent text-info-light",
      "dark:text-info-dark border-transparent"
    ]
  end

  defp color_variant("transparent", "misc") do
    [
      "bg-transparent text-misc-light",
      "dark:text-misc-dark border-transparent"
    ]
  end

  defp color_variant("transparent", "dawn") do
    [
      "bg-transparent text-dawn-light",
      "dark:text-dawn-dark border-transparent"
    ]
  end

  defp color_variant("transparent", "silver") do
    [
      "bg-transparent text-silver-light",
      "dark:text-silver-dark border-transparent"
    ]
  end

  defp color_variant("bordered", "white") do
    [
      "bg-white text-black border-bordered-white-border"
    ]
  end

  defp color_variant("bordered", "dark") do
    [
      "bg-bordered-dark-bg text-white border-bordered-dark-border"
    ]
  end

  defp color_variant("bordered", "natural") do
    [
      "text-natural-bordered-text-light border-natural-border-light bg-natural-bordered-bg-light",
      "dark:text-natural-bordered-text-dark dark:border-natural-border-dark dark:bg-natural-bordered-bg-dark"
    ]
  end

  defp color_variant("bordered", "primary") do
    [
      "text-primary-bordered-text-light border-primary-bordered-text-light bg-primary-bordered-bg-light",
      "dark:text-primary-bordered-text-dark dark:border-primary-bordered-text-dark dark:bg-primary-bordered-bg-dark"
    ]
  end

  defp color_variant("bordered", "secondary") do
    [
      "text-secondary-bordered-text-light border-secondary-bordered-text-light bg-secondary-bordered-bg-light",
      "dark:text-secondary-bordered-text-dark dark:border-secondary-bordered-text-dark dark:bg-secondary-bordered-bg-dark"
    ]
  end

  defp color_variant("bordered", "success") do
    [
      "text-success-bordered-text-light border-success-bordered-text-light bg-success-bordered-bg-light",
      "dark:text-success-bordered-text-dark dark:border-success-bordered-text-dark dark:bg-success-bordered-bg-dark"
    ]
  end

  defp color_variant("bordered", "warning") do
    [
      "text-warning-bordered-text-light border-warning-bordered-text-light bg-warning-bordered-bg-light",
      "dark:text-warning-bordered-text-dark dark:border-warning-bordered-text-dark dark:bg-warning-bordered-bg-dark"
    ]
  end

  defp color_variant("bordered", "danger") do
    [
      "text-danger-bordered-text-light border-danger-bordered-text-light bg-danger-bordered-bg-light",
      "dark:text-danger-bordered-text-dark dark:border-danger-bordered-text-dark dark:bg-danger-bordered-bg-dark"
    ]
  end

  defp color_variant("bordered", "info") do
    [
      "text-info-bordered-text-light border-info-bordered-text-light bg-info-bordered-bg-light",
      "dark:text-info-bordered-text-dark dark:border-info-bordered-text-dark dark:bg-info-bordered-bg-dark"
    ]
  end

  defp color_variant("bordered", "misc") do
    [
      "text-misc-bordered-text-light border-misc-bordered-text-light bg-misc-bordered-bg-light",
      "dark:text-misc-bordered-text-dark dark:border-misc-bordered-text-dark dark:bg-misc-bordered-bg-dark"
    ]
  end

  defp color_variant("bordered", "dawn") do
    [
      "text-dawn-bordered-text-light border-dawn-bordered-text-light bg-dawn-bordered-bg-light",
      "dark:text-dawn-bordered-text-dark dark:border-dawn-bordered-text-dark dark:bg-dawn-bordered-bg-dark"
    ]
  end

  defp color_variant("bordered", "silver") do
    [
      "text-silver-bordered-text-light border-silver-bordered-text-light bg-silver-bordered-bg-light",
      "dark:text-silver-bordered-text-dark dark:border-silver-bordered-text-dark dark:bg-silver-bordered-bg-dark"
    ]
  end

  defp color_variant("gradient", "natural") do
    [
      "bg-gradient-to-br from-gradient-natural-from-light to-gradient-natural-to-light text-white",
      "dark:from-gradient-natural-from-dark dark:to-white dark:text-black"
    ]
  end

  defp color_variant("gradient", "primary") do
    [
      "bg-gradient-to-br from-gradient-primary-from-light to-gradient-primary-to-light text-white",
      "dark:from-gradient-primary-from-dark dark:to-gradient-primary-to-dark dark:text-black"
    ]
  end

  defp color_variant("gradient", "secondary") do
    [
      "bg-gradient-to-br from-gradient-secondary-from-light to-gradient-secondary-to-light text-white",
      "dark:from-gradient-secondary-from-dark dark:to-gradient-secondary-to-dark dark:text-black"
    ]
  end

  defp color_variant("gradient", "success") do
    [
      "bg-gradient-to-br from-gradient-success-from-light to-gradient-success-to-light text-white",
      "dark:from-gradient-success-from-dark dark:to-gradient-success-to-dark dark:text-black"
    ]
  end

  defp color_variant("gradient", "warning") do
    [
      "bg-gradient-to-br from-gradient-warning-from-light to-gradient-warning-to-light text-white",
      "dark:from-gradient-warning-from-dark dark:to-gradient-warning-to-dark dark:text-black"
    ]
  end

  defp color_variant("gradient", "danger") do
    [
      "bg-gradient-to-br from-gradient-danger-from-light to-gradient-danger-to-light text-white",
      "dark:from-gradient-danger-from-dark dark:to-gradient-danger-to-dark dark:text-black"
    ]
  end

  defp color_variant("gradient", "info") do
    [
      "bg-gradient-to-br from-gradient-info-from-light to-gradient-info-to-light text-white",
      "dark:from-gradient-info-from-dark dark:to-gradient-info-to-dark dark:text-black"
    ]
  end

  defp color_variant("gradient", "misc") do
    [
      "bg-gradient-to-br from-gradient-misc-from-light to-gradient-misc-to-light text-white",
      "dark:from-gradient-misc-from-dark dark:to-gradient-misc-to-dark dark:text-black"
    ]
  end

  defp color_variant("gradient", "dawn") do
    [
      "bg-gradient-to-br from-gradient-dawn-from-light to-gradient-dawn-to-light text-white",
      "dark:from-gradient-dawn-from-dark dark:to-gradient-dawn-to-dark dark:text-black"
    ]
  end

  defp color_variant("gradient", "silver") do
    [
      "bg-gradient-to-br from-gradient-silver-from-light to-gradient-silver-to-light text-white",
      "dark:from-gradient-silver-from-dark dark:to-gradient-silver-to-dark dark:text-black"
    ]
  end

  defp color_variant(params, _) when is_binary(params), do: params

  @doc """
  Shows the drawer component by modifying its CSS classes to transition it into view.

  ## Parameters:
    - `js` (optional, `Phoenix.LiveView.JS`): The JS struct used to chain JavaScript commands.
    Defaults to an empty `%JS{}`.
    - `id` (string): The unique identifier of the drawer element to show.
    - `position` (string): The position of the drawer, such as "left", "right", "top", or "bottom".

  ## Behavior:
  Removes the CSS class that keeps the drawer off-screen and adds the class `"transform-none"`
  to bring the drawer into view.

  ## Examples:

  ```elixir
  show_drawer(%JS{}, "drawer-id", "left")
  ```

  This will show the drawer with ID `drawer-id` positioned on the left side of the screen.
  """
  def show_drawer(js \\ %JS{}, id, position) when is_binary(id) do
    JS.remove_class(js, translate_position(position), to: "##{id}")
    |> JS.add_class("transform-none", to: "##{id}")
    |> JS.add_class("drawer-showed", to: "##{id}")
  end

  @doc """
  Hides the drawer component by modifying its CSS classes to transition it out of view.

  ## Parameters:
    - `js` (optional, `Phoenix.LiveView.JS`): The JS struct used to chain JavaScript commands. Defaults to an empty `%JS{}`.
    - `id` (string): The unique identifier of the drawer element to hide.
    - `position` (string): The position of the drawer, such as "left", "right", "top", or "bottom".

  ## Behavior:
  Removes the `"transform-none"` CSS class that keeps the drawer visible and adds the class based on the drawer's position (e.g., `"-translate-x-full"` for a left-positioned drawer) to move the drawer off-screen.

  ## Examples:

  ```elixir
  hide_drawer(%JS{}, "drawer-id", "left")
  ```

  This will hide the drawer with ID "drawer-id" positioned on the left side of the screen.
  """
  def hide_drawer(js \\ %JS{}, id, position) do
    js
    |> JS.remove_class("drawer-showed", to: "##{id}")
    |> JS.remove_class("transform-none", to: "##{id}")
    |> JS.add_class(translate_position(position), to: "##{id}")
  end
end
