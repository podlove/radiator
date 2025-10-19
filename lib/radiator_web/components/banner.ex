defmodule RadiatorWeb.Components.Banner do
  @moduledoc """
  RadiatorWeb.Components.Banner module provides components for rendering customizable banners in your **Phoenix LiveView**
  application.

  ## Features

  - **Banner Component**: Create visually appealing banners with various styles, colors, and sizes.
  - **Dismissable Banners**: Add dismiss buttons to banners to allow users to hide them with a
  smooth transition.
  - **Positioning Options**: Control the positioning of the banners on the screen with flexible
  vertical and horizontal alignment options.
  - **Custom Styles**: Customize the look and feel of your banners using various attributes for size,
  border, padding, and more.
  - **Animation Transitions**: Use built-in JavaScript commands to show and hide banners with
  smooth animation transitions.

  > The main component for rendering a banner with optional inner content and dismiss functionality.

  ## JS Commands

  - `show_banner/2`: Displays the banner element with a smooth transition.
  - `hide_banner/2`: Hides the banner element with a smooth transition.

  Use this module to create interactive and aesthetically pleasing banner elements for
  your **LiveView** applications.

  **Documentation:** https://mishka.tools/chelekom/docs/banner
  """

  use Phoenix.Component
  alias Phoenix.LiveView.JS
  use Gettext, backend: RadiatorWeb.Gettext
  import RadiatorWeb.Components.Icon, only: [icon: 1]

  @positions ["top_left", "top_right", "bottom_left", "bottom_right", "center", "full"]

  @doc """
  The `banner` component is used to display fixed position banners with various customization
  options such as size, color, and position. It supports displaying content through an inner block,
  and attributes like `vertical_position` and `rounded_position` for flexible layout configuration.

  ## Examples

  ```elixir
  <.banner id="banner">
    <div>
      Lorem ipsum dolor sit amet consectetur adipisicing elit. Commodi ea
      atque soluta praesentium quidem dicta sapiente accusamus nihil.
    </div>
  </.banner>

  <.banner id="banner" color="primary" space="large" vertical_position="bottom">
    <div>
      Lorem ipsum dolor sit amet consectetur adipisicing elit. Commodi ea atque soluta
      praesentium quidem dicta sapiente accusamus nihil.
    </div>
    <div>
      Lorem ipsum dolor sit amet consectetur adipisicing elit. Commodi ea atque
      soluta praesentium quidem dicta sapiente accusamus nihil.
    </div>
  </.banner>

  <.banner id="banner" color="secondary" space="large" vertical_position="top" vertical_size="top-24">
    <div>
      Lorem ipsum dolor sit amet consectetur adipisicing elit. Commodi ea atque soluta praesentium quidem dicta sapiente accusamus nihil.
    </div>
    <div>
      Lorem ipsum dolor sit amet consectetur adipisicing elit. Commodi ea atque soluta praesentium quidem dicta sapiente accusamus nihil.
    </div>
  </.banner>
  ```
  """
  @doc type: :component
  attr :id, :string,
    required: true,
    doc: "A unique identifier is used to manage state and interaction"

  attr :size, :string,
    default: "large",
    doc:
      "Determines the overall size of the elements, including padding, font size, and other items"

  attr :variant, :string, default: "base", doc: "Determines the style"
  attr :color, :string, default: "natural", doc: "Determines color theme"
  attr :border, :string, default: "extra_small", doc: "Determines border style"

  attr :border_position, :string,
    values: ["top", "bottom", "full", "none"],
    default: "top",
    doc: ""

  attr :rounded, :string, default: "none", doc: "Determines the border radius"

  attr :rounded_position, :string,
    values: ["top", "bottom", "all", "none"],
    default: "none",
    doc: ""

  attr :space, :string, default: "extra_small", doc: "Space between items"

  attr :vertical_position, :string, values: ["top", "bottom"], default: "top", doc: ""
  attr :vertical_size, :string, default: "none", doc: "Specifies the vertical size of the element"

  attr :hide_dismiss, :boolean, default: false, doc: "Show or hide dismiss classes"

  attr :dismiss_size, :string,
    default: "small",
    doc: "Add custom classes to control dismiss sizes"

  attr :position, :string,
    values: @positions,
    default: "full",
    doc: "Determines the element position"

  attr :position_size, :string,
    default: "none",
    doc: "Determines the size for positioning the element"

  attr :font_weight, :string,
    default: "font-normal",
    doc: "Determines custom class for the font weight"

  attr :padding, :string, default: "extra_small", doc: "Determines padding for items"

  attr :class, :string, default: nil, doc: "Custom CSS class for additional styling"
  attr :dismiss_class, :string, default: nil, doc: "Custom CSS class for additional styling"

  attr :content_wrapper_class, :string,
    default: nil,
    doc: "Custom CSS class for additional styling"

  attr :params, :map,
    default: %{kind: "banner"},
    doc: "A map of additional parameters used for element configuration, such as type or kind"

  attr :rest, :global,
    include: ~w(right_dismiss left_dismiss),
    doc:
      "Global attributes can define defaults which are merged with attributes provided by the caller"

  slot :inner_block, required: false, doc: "Inner block that renders HEEx content"

  def banner(assigns) do
    ~H"""
    <div
      id={@id}
      role="status"
      aria-live="polite"
      aria-atomic="true"
      class={[
        "overflow-hidden fixed z-50",
        vertical_position(@vertical_size, @vertical_position),
        rounded_size(@rounded, @rounded_position),
        border_class(@border, @border_position, @variant),
        color_variant(@variant, @color),
        position_class(@position_size, @position),
        space_class(@space),
        padding_size(@padding),
        @font_weight,
        @class
      ]}
      {@rest}
    >
      <div class={["flex gap-2 items-center justify-between", @content_wrapper_class]}>
        {render_slot(@inner_block)}
        <.banner_dismiss
          :if={!@hide_dismiss}
          id={@id}
          dismiss_size={@dismiss_size}
          class={@dismiss_class}
          params={@params}
        />
      </div>
    </div>
    """
  end

  @doc type: :component
  attr :id, :string,
    required: true,
    doc: "A unique identifier is used to manage state and interaction"

  attr :class, :string, default: nil, doc: "Custom CSS class for additional styling"

  attr :dismiss_size, :string,
    default: "small",
    doc: "Add custom classes to control dismiss sizes"

  attr :params, :map,
    default: %{kind: "badge"},
    doc: "A map of additional parameters used for element configuration, such as type or kind"

  defp banner_dismiss(assigns) do
    ~H"""
    <button
      type="button"
      class="group shrink-0"
      aria-label={gettext("close")}
      phx-click={JS.push("dismiss", value: Map.merge(%{id: @id}, @params)) |> hide_banner("##{@id}")}
    >
      <.icon
        name="hero-x-mark-solid"
        class={[
          "banner-icon opacity-80 group-hover:opacity-70",
          dismiss_size(@dismiss_size),
          @class
        ]}
      />
    </button>
    """
  end

  defp dismiss_size("extra_small"), do: "size-3.5"

  defp dismiss_size("small"), do: "size-4"

  defp dismiss_size("medium"), do: "size-5"

  defp dismiss_size("large"), do: "size-6"

  defp dismiss_size("extra_large"), do: "size-7"

  defp dismiss_size(params) when is_binary(params), do: params

  defp padding_size("extra_small"), do: "p-2"

  defp padding_size("small"), do: "p-3"

  defp padding_size("medium"), do: "p-4"

  defp padding_size("large"), do: "p-5"

  defp padding_size("extra_large"), do: "p-6"

  defp padding_size("none"), do: "p-0"

  defp padding_size(params) when is_binary(params), do: params

  defp vertical_position("none", "top"), do: "top-0"
  defp vertical_position("extra_small", "top"), do: "top-1"
  defp vertical_position("small", "top"), do: "top-2"
  defp vertical_position("medium", "top"), do: "top-3"
  defp vertical_position("large", "top"), do: "top-4"
  defp vertical_position("extra_large", "top"), do: "top-5"

  defp vertical_position("none", "bottom"), do: "bottom-0"
  defp vertical_position("extra_small", "bottom"), do: "bottom-1"
  defp vertical_position("small", "bottom"), do: "bottom-2"
  defp vertical_position("medium", "bottom"), do: "bottom-3"
  defp vertical_position("large", "bottom"), do: "bottom-4"
  defp vertical_position("extra_large", "bottom"), do: "bottom-5"

  defp vertical_position(params, _) when is_binary(params), do: params

  defp position_class("none", "top_left"), do: "left-0 ml-0"
  defp position_class("extra_small", "top_left"), do: "left-1 ml-1"
  defp position_class("small", "top_left"), do: "left-2 ml-2"
  defp position_class("medium", "top_left"), do: "left-3 ml-3"
  defp position_class("large", "top_left"), do: "left-4 ml-4"
  defp position_class("extra_large", "top_left"), do: "left-5 ml-5"

  defp position_class("none", "top_right"), do: "right-0"
  defp position_class("extra_small", "top_right"), do: "right-1"
  defp position_class("small", "top_right"), do: "right-2"
  defp position_class("medium", "top_right"), do: "right-3"
  defp position_class("large", "top_right"), do: "right-4"
  defp position_class("extra_large", "top_right"), do: "right-5"

  defp position_class("none", "bottom_left"), do: "left-0 ml-0"
  defp position_class("extra_small", "bottom_left"), do: "left-1 ml-1"
  defp position_class("small", "bottom_left"), do: "left-2 ml-2"
  defp position_class("medium", "bottom_left"), do: "left-3 ml-3"
  defp position_class("large", "bottom_left"), do: "left-4 ml-4"
  defp position_class("extra_large", "bottom_left"), do: "left-5 ml-5"

  defp position_class("none", "bottom_right"), do: "right-0"
  defp position_class("extra_small", "bottom_right"), do: "right-1"
  defp position_class("small", "bottom_right"), do: "right-2"
  defp position_class("medium", "bottom_right"), do: "right-3"
  defp position_class("large", "bottom_right"), do: "right-4"
  defp position_class("extra_large", "bottom_right"), do: "right-5"

  defp position_class(_, "center"), do: "mx-auto"
  defp position_class(_, "full"), do: "inset-x-0"

  defp position_class(params, _) when is_binary(params), do: params

  defp rounded_size("extra_small", "top"), do: "rounded-b-sm"

  defp rounded_size("small", "top"), do: "rounded-b"

  defp rounded_size("medium", "top"), do: "rounded-b-md"

  defp rounded_size("large", "top"), do: "rounded-b-lg"

  defp rounded_size("extra_large", "top"), do: "rounded-b-xl"

  defp rounded_size("extra_small", "bottom"), do: "rounded-t-sm"

  defp rounded_size("small", "bottom"), do: "rounded-t"

  defp rounded_size("medium", "bottom"), do: "rounded-t-md"

  defp rounded_size("large", "bottom"), do: "rounded-t-lg"

  defp rounded_size("extra_large", "bottom"), do: "rounded-t-xl"

  defp rounded_size("extra_small", "all"), do: "rounded-sm"

  defp rounded_size("small", "all"), do: "rounded"

  defp rounded_size("medium", "all"), do: "rounded-md"

  defp rounded_size("large", "all"), do: "rounded-lg"

  defp rounded_size("extra_large", "all"), do: "rounded-xl"

  defp rounded_size("none", _), do: nil

  defp rounded_size(params, _) when is_binary(params), do: params

  defp space_class("none"), do: nil

  defp space_class("extra_small"), do: "space-y-2"

  defp space_class("small"), do: "space-y-3"

  defp space_class("medium"), do: "space-y-4"

  defp space_class("large"), do: "space-y-5"

  defp space_class("extra_large"), do: "space-y-6"

  defp space_class(params) when is_binary(params), do: params

  defp border_class(_, _, variant)
       when variant in ["default", "shadow", "transparent", "gradient"],
       do: nil

  defp border_class("none", _, _), do: nil
  defp border_class("extra_small", "top", _), do: "border-b"
  defp border_class("small", "top", _), do: "border-b-2"
  defp border_class("medium", "top", _), do: "border-b-[3px]"
  defp border_class("large", "top", _), do: "border-b-4"
  defp border_class("extra_large", "top", _), do: "border-b-[5px]"

  defp border_class("extra_small", "bottom", _), do: "border"
  defp border_class("small", "bottom", _), do: "border-b-2"
  defp border_class("medium", "bottom", _), do: "border-b-[3px]"
  defp border_class("large", "bottom", _), do: "border-b-4"
  defp border_class("extra_large", "bottom", _), do: "border-b-[5px]"

  defp border_class("extra_small", "full", _), do: "border"
  defp border_class("small", "full", _), do: "border-2"
  defp border_class("medium", "full", _), do: "border-[3px]"
  defp border_class("large", "full", _), do: "border-4"
  defp border_class("extra_large", "full", _), do: "border-[5px]"

  defp border_class(params, _, _) when is_binary(params), do: params

  defp color_variant("base", _) do
    [
      "bg-white text-base-text-light border-base-border-light shadow-sm",
      "dark:bg-base-bg-dark dark:text-base-text-dark dark:border-base-border-dark"
    ]
  end

  defp color_variant("default", "white") do
    ["bg-white text-black"]
  end

  defp color_variant("default", "dark") do
    ["bg-default-dark-bg text-white"]
  end

  defp color_variant("default", "natural") do
    ["bg-natural-light text-white dark:bg-natural-dark dark:text-black"]
  end

  defp color_variant("default", "primary") do
    ["bg-primary-light text-white dark:bg-primary-dark dark:text-black"]
  end

  defp color_variant("default", "secondary") do
    ["bg-secondary-light text-white dark:bg-secondary-dark dark:text-black"]
  end

  defp color_variant("default", "success") do
    ["bg-success-light text-white dark:bg-success-dark dark:text-black"]
  end

  defp color_variant("default", "warning") do
    ["bg-warning-light text-white dark:bg-warning-dark dark:text-black"]
  end

  defp color_variant("default", "danger") do
    ["bg-danger-light text-white dark:bg-danger-dark dark:text-black"]
  end

  defp color_variant("default", "info") do
    ["bg-info-light text-white dark:bg-info-dark dark:text-black"]
  end

  defp color_variant("default", "misc") do
    ["bg-misc-light text-white dark:bg-misc-dark dark:text-black"]
  end

  defp color_variant("default", "dawn") do
    ["bg-dawn-light text-white dark:bg-dawn-dark dark:text-black"]
  end

  defp color_variant("default", "silver") do
    ["bg-silver-light text-white dark:bg-silver-dark dark:text-black"]
  end

  defp color_variant("outline", "natural") do
    [
      "text-natural-light border-natural-light",
      "dark:text-natural-dark dark:border-natural-dark"
    ]
  end

  defp color_variant("outline", "primary") do
    [
      "text-primary-light border-primary-light",
      "dark:text-primary-dark dark:border-primary-dark"
    ]
  end

  defp color_variant("outline", "secondary") do
    [
      "text-secondary-light border-secondary-light",
      "dark:text-secondary-dark dark:border-secondary-dark"
    ]
  end

  defp color_variant("outline", "success") do
    [
      "text-success-light border-success-light",
      "dark:text-success-dark dark:border-success-dark"
    ]
  end

  defp color_variant("outline", "warning") do
    [
      "text-warning-light border-warning-light",
      "dark:text-warning-dark dark:border-warning-dark"
    ]
  end

  defp color_variant("outline", "danger") do
    [
      "text-danger-light border-danger-light",
      "dark:text-danger-dark dark:border-danger-dark"
    ]
  end

  defp color_variant("outline", "info") do
    [
      "text-info-light border-info-light",
      "dark:text-info-dark dark:border-info-dark"
    ]
  end

  defp color_variant("outline", "misc") do
    [
      "text-misc-light border-misc-light",
      "dark:text-misc-dark dark:border-misc-dark"
    ]
  end

  defp color_variant("outline", "dawn") do
    [
      "text-dawn-light border-dawn-light",
      "dark:text-dawn-dark dark:border-dawn-dark"
    ]
  end

  defp color_variant("outline", "silver") do
    [
      "text-silver-light border-silver-light",
      "dark:text-silver-dark dark:border-silver-dark"
    ]
  end

  defp color_variant("shadow", "natural") do
    [
      "bg-natural-light text-white dark:bg-natural-dark dark:text-black",
      "shadow-[0px_4px_6px_-4px_var(--color-shadow-natural)] shadow-[0px_10px_15px_-3px_var(--color-shadow-natural)] dark:shadow-none"
    ]
  end

  defp color_variant("shadow", "primary") do
    [
      "bg-primary-light text-white dark:bg-primary-dark dark:text-black",
      "shadow-[0px_4px_6px_-4px_var(--color-shadow-primary)] shadow-[0px_10px_15px_-3px_var(--color-shadow-primary)] dark:shadow-none"
    ]
  end

  defp color_variant("shadow", "secondary") do
    [
      "bg-secondary-light text-white dark:bg-secondary-dark dark:text-black",
      "shadow-[0px_4px_6px_-4px_var(--color-shadow-secondary)] shadow-[0px_10px_15px_-3px_var(--color-shadow-secondary)] dark:shadow-none"
    ]
  end

  defp color_variant("shadow", "success") do
    [
      "bg-success-light text-white dark:bg-success-dark dark:text-black",
      "shadow-[0px_4px_6px_-4px_var(--color-shadow-success)] shadow-[0px_10px_15px_-3px_var(--color-shadow-success)] dark:shadow-none"
    ]
  end

  defp color_variant("shadow", "warning") do
    [
      "bg-warning-light text-white dark:bg-warning-dark dark:text-black",
      "shadow-[0px_4px_6px_-4px_var(--color-shadow-warning)] shadow-[0px_10px_15px_-3px_var(--color-shadow-warning)] dark:shadow-none"
    ]
  end

  defp color_variant("shadow", "danger") do
    [
      "bg-danger-light text-white dark:bg-danger-dark dark:text-black",
      "shadow-[0px_4px_6px_-4px_var(--color-shadow-danger)] shadow-[0px_10px_15px_-3px_var(--color-shadow-danger)] dark:shadow-none"
    ]
  end

  defp color_variant("shadow", "info") do
    [
      "bg-info-light text-white dark:bg-info-dark dark:text-black",
      "shadow-[0px_4px_6px_-4px_var(--color-shadow-info)] shadow-[0px_10px_15px_-3px_var(--color-shadow-info)] dark:shadow-none"
    ]
  end

  defp color_variant("shadow", "misc") do
    [
      "bg-misc-light text-white dark:bg-misc-dark dark:text-black",
      "shadow-[0px_4px_6px_-4px_var(--color-shadow-misc)] shadow-[0px_10px_15px_-3px_var(--color-shadow-misc)] dark:shadow-none"
    ]
  end

  defp color_variant("shadow", "dawn") do
    [
      "bg-dawn-light text-white dark:bg-dawn-dark dark:text-black",
      "shadow-[0px_4px_6px_-4px_var(--color-shadow-dawn)] shadow-[0px_10px_15px_-3px_var(--color-shadow-dawn)] dark:shadow-none"
    ]
  end

  defp color_variant("shadow", "silver") do
    [
      "bg-silver-light text-white dark:bg-silver-dark dark:text-black",
      "shadow-[0px_4px_6px_-4px_var(--color-shadow-silver)] shadow-[0px_10px_15px_-3px_var(--color-shadow-silver)] dark:shadow-none"
    ]
  end

  defp color_variant("transparent", "natural") do
    ["text-natural-light dark:text-natural-dark"]
  end

  defp color_variant("transparent", "primary") do
    ["text-primary-light dark:text-primary-dark"]
  end

  defp color_variant("transparent", "secondary") do
    ["text-secondary-light dark:text-secondary-dark"]
  end

  defp color_variant("transparent", "success") do
    ["text-success-light dark:text-success-dark"]
  end

  defp color_variant("transparent", "warning") do
    ["text-warning-light dark:text-warning-dark"]
  end

  defp color_variant("transparent", "danger") do
    ["text-danger-light dark:text-danger-dark"]
  end

  defp color_variant("transparent", "info") do
    ["text-info-light dark:text-info-dark"]
  end

  defp color_variant("transparent", "misc") do
    ["text-misc-light dark:text-misc-dark"]
  end

  defp color_variant("transparent", "dawn") do
    ["text-dawn-light dark:text-dawn-dark"]
  end

  defp color_variant("transparent", "silver") do
    ["text-silver-light dark:text-silver-dark"]
  end

  defp color_variant("bordered", "white") do
    ["bg-white text-black border-bordered-white-border"]
  end

  defp color_variant("bordered", "dark") do
    ["bg-bordered-dark-bg text-white border-bordered-dark-border"]
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

  ## JS Commands
  @doc """
  Displays a banner element with a smooth transition effect.

  ## Parameters

    - `js` (optional): An existing `Phoenix.LiveView.JS` structure to apply transformations on.
    Defaults to a new `%JS{}`.
    - `selector`: A string representing the CSS selector of the banner element to be shown.

  ## Returns

    - A `Phoenix.LiveView.JS` structure with commands to show the banner element with a
    smooth transition effect.

  ## Transition Details

    - The element transitions from an initial state of reduced opacity and scale
    (`opacity-0 translate-y-4 sm:translate-y-0 sm:scale-95`) to full opacity and scale
    (`opacity-100 translate-y-0 sm:scale-100`) over a duration of 300 milliseconds.

  ## Example

    ```elixir
    show_banner(%JS{}, "#banner-element")
    ```

    This example will show the banner element with the ID banner-element using the defined transition effect.
  """
  def show_banner(js \\ %JS{}, selector) do
    JS.show(js,
      to: selector,
      time: 300,
      transition:
        {"transition-all transform ease-out duration-300",
         "opacity-0 translate-y-4 sm:translate-y-0 sm:scale-95",
         "opacity-100 translate-y-0 sm:scale-100"}
    )
  end

  @doc """
  Hides a banner element with a smooth transition effect.

  ## Parameters

    - `js` (optional): An existing `Phoenix.LiveView.JS` structure to apply transformations on.
    Defaults to a new `%JS{}`.
    - `selector`: A string representing the CSS selector of the banner element to be hidden.

  ## Returns

    - A `Phoenix.LiveView.JS` structure with commands to hide the banner element with a
    smooth transition effect.

  ## Transition Details

    - The element transitions from full opacity and scale (`opacity-100 translate-y-0 sm:scale-100`)
    to reduced opacity and scale (`opacity-0 translate-y-4 sm:translate-y-0 sm:scale-95`)
    over a duration of 200 milliseconds.

  ## Example

    ```elixir
    hide_banner(%JS{}, "#banner-element")
    ```

  This example will hide the banner element with the ID banner-element using the defined transition effect.
  """
  def hide_banner(js \\ %JS{}, selector) do
    JS.hide(js,
      to: selector,
      time: 200,
      transition:
        {"transition-all transform ease-in duration-200",
         "opacity-100 translate-y-0 sm:scale-100",
         "opacity-0 translate-y-4 sm:translate-y-0 sm:scale-95"}
    )
  end
end
