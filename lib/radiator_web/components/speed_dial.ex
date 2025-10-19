defmodule RadiatorWeb.Components.SpeedDial do
  @moduledoc """
  The `RadiatorWeb.Components.SpeedDial` module provides a versatile speed dial component for Phoenix
  LiveView applications. This component enhances user interactions by offering a dynamic
  menu of actions that can be triggered from a single button. The speed dial is
  especially useful for applications that need to offer quick access to multiple
  actions without cluttering the UI.

  ## Features

  - **Customizable Appearance:** Supports various size, color, and style options, including
  `default`, `outline`, `shadow`, and `unbordered` variants. Users can control the
  overall size, border radius, padding, and spacing between elements to fit different design requirements.
  - **Action Configuration:** The `SpeedDial` component can hold multiple action items,
  each with individual icons, colors, and navigation paths. Items can link to different parts
  of the application, trigger patches, or direct to external URLs.
  - **Interactive Control:** The speed dial can be toggled to show or hide the list of actions.
  This makes it easy to manage the visibility of the component based on user interactions.
  - **Flexible Positioning:** Allows placement at various positions on the screen, such as
  `top-start`, `top-end`, `bottom-start`, and `bottom-end`. The position can be adjusted
  based on the container's size and requirements.
  - **Animation and Icon Support:** Includes built-in animation options for icons and button
  states, creating an engaging user experience. Icons can be added or animated when hovering
  over the speed dial button.

  This component is perfect for implementing quick action menus in applications where users need
  to perform frequent operations from a single access point.

  **Documentation:** https://mishka.tools/chelekom/docs/speed-dial
  """

  use Phoenix.Component
  use Gettext, backend: RadiatorWeb.Gettext
  alias Phoenix.LiveView.JS
  import RadiatorWeb.Components.Icon, only: [icon: 1]

  @doc """
  Renders a customizable `speed_dial` component that provides quick access to multiple actions.
  The speed dial can be configured with various styles, sizes, and colors.

  It supports navigation, icons, and custom content in each item.

  ## Examples

  ```elixir
  <.speed_dial icon="hero-plus" space="large" icon_animated id="test-1" size="extra_small" clickable>
    <:item icon="hero-home" href="/examples/navbar" color="danger"></:item>
    <:item icon="hero-bars-3" href="/examples/navbar" variant="shadow" color="misc">11</:item>
    <:item icon="hero-chart-bar" href="/examples/navbar" variant="unbordered" color="warning">
    </:item>
  </.speed_dial>
  ```
  """
  @doc type: :component
  attr :id, :string,
    required: true,
    doc: "A unique identifier is used to manage state and interaction"

  attr :class, :string, default: nil, doc: "Custom CSS class for additional styling"

  attr :wrapper_content_class, :string,
    default: nil,
    doc: "Custom CSS class for additional styling to content"

  attr :trigger_class, :string,
    default: nil,
    doc: "Custom CSS class for additional styling to button"

  attr :action_position, :string,
    default: "bottom-end",
    doc: "Controls the position of the action items relative to the trigger button"

  attr :position_size, :string,
    default: "large",
    doc: "Controls the distance from the edge of the screen for positioning"

  attr :wrapper_position, :string,
    default: "top",
    doc: "Determines the position of the wrapper content (top, bottom, left, right)"

  attr :rounded, :string, default: "full", doc: "Determines the border radius"

  attr :size, :string,
    default: "medium",
    doc:
      "Determines the overall size of the elements, including padding, font size, and other items"

  attr :color, :string, default: "natural", doc: "Determines color theme"
  attr :variant, :string, default: "base", doc: "Determines the style"
  attr :space, :string, default: "extra_small", doc: "Space between items"
  attr :width, :string, default: "fit", doc: "Determines the element width"
  attr :border, :string, default: "extra_small", doc: "Determines border style"
  attr :padding, :string, default: "extra_small", doc: "Determines padding for items"

  attr :clickable, :boolean,
    default: false,
    doc: "Determines if the element can be activated on click"

  attr :icon, :string, default: nil, doc: "Icon displayed alongside of an item"

  attr :icon_animated, :boolean,
    default: false,
    doc: "Determines whether element's icon has animation"

  attr :rest, :global,
    doc:
      "Global attributes can define defaults which are merged with attributes provided by the caller"

  slot :item, required: false, doc: "Specifies item slot of a speed dial" do
    attr :icon, :string, doc: "Icon displayed alongside of an item"
    attr :class, :string, doc: "Custom CSS class for additional styling"

    attr :navigate, :string,
      doc: "Defines the path for navigation within the application using a `navigate` attribute."

    attr :patch, :string, doc: "Specifies the path for navigation using a LiveView patch."
    attr :href, :string, doc: "Sets the URL for an external link."
    attr :icon_class, :string, doc: "Determines custom class for the icon"
    attr :content_class, :string, doc: "Determines custom class for the content"
    attr :color, :string, doc: "Determines color theme"
    attr :variant, :string, doc: "Determines the style"
    attr :icon_position, :string, doc: "Determines icon position"
  end

  slot :trigger_content, required: false, doc: "Determines triggered content" do
    attr :class, :string, doc: "Custom CSS class for additional styling"
  end

  slot :inner_block, required: false, doc: "Inner block that renders HEEx content"

  def speed_dial(assigns) do
    ~H"""
    <div
      id={@id}
      class={[
        "fixed group",
        "[&_.speed-dial-content]:invisible [&_.speed-dial-content]:opacity-0",
        "[&_.speed-dial-content.show-speed-dial]:visible [&_.speed-dial-content.show-speed-dial]:opacity-100",
        "[&_.speed-dial-base]:flex [&_.speed-dial-base]:items-center [&_.speed-dial-base]:justify-center",
        !@clickable && trigger_dial(),
        action_position(@position_size, @action_position),
        space_class(@space, @wrapper_position),
        position_class(@wrapper_position),
        rounded_size(@rounded),
        border_class(@border, @variant),
        padding_class(@padding),
        width_class(@width),
        size_class(@size),
        @class
      ]}
      {@rest}
    >
      <div
        class={[
          "speed-dial-content flex items-center",
          "absolute z-10 w-full transition-all ease-in-out delay-100 duration-500",
          (@wrapper_position == "top" || @wrapper_position == "bottom") && "flex-col",
          @wrapper_content_class
        ]}
        id={@id && "#{@id}-speed-dial-content"}
        role="menu"
        phx-click-away={
          @id &&
            JS.remove_class("show-speed-dial",
              to: "##{@id}-speed-dial-content",
              transition: "duration-300"
            )
        }
      >
        <div
          :for={{item, index} <- Enum.with_index(@item, 1)}
          id={"#{@id}-item-#{index}"}
          class={[
            "speed-dial-item w-fit h-fit",
            item[:icon_position] == "end" && "flex-row-reverse",
            item[:class]
          ]}
        >
          <.speed_dial_content id={@id} index={index} {item}>
            {render_slot(item)}
          </.speed_dial_content>
        </div>
        {render_slot(@inner_block)}
      </div>

      <button
        type="button"
        aria-haspopup="menu"
        aria-controls={"#{@id}-speed-dial-content"}
        class={["speed-dial-base", color_variant(@variant, @color), @trigger_class]}
        phx-click={
          @id &&
            JS.toggle_class("show-speed-dial",
              to: "##{@id}-speed-dial-content",
              transition: "duration-100"
            )
        }
      >
        <.icon
          :if={!is_nil(@icon)}
          name={@icon}
          class={[
            "speed-dial-icon-base",
            @icon_animated && "transition-transform group-hover:rotate-45"
          ]}
        />
        <span :if={is_nil(@icon)} class={@trigger_content[:class]}>
          {render_slot(@trigger_content)}
        </span>
        <span class="sr-only">{gettext("Open actions menu")}</span>
      </button>
    </div>
    """
  end

  @doc type: :component
  attr :id, :string,
    required: true,
    doc: "A unique identifier is used to manage state and interaction"

  attr :navigate, :string,
    default: nil,
    doc: "Defines the path for navigation within the application using a `navigate` attribute."

  attr :patch, :string,
    default: nil,
    doc: "Specifies the path for navigation using a LiveView patch."

  attr :href, :string, default: nil, doc: "Sets the URL for an external link."
  attr :color, :string, default: "primary", doc: "Determines color theme"
  attr :variant, :string, default: "default", doc: "Determines the style"
  attr :icon, :string, default: nil, doc: "Icon displayed alongside of an item"
  attr :icon_class, :string, default: nil, doc: "Determines custom class for the icon"
  attr :content_class, :string, default: nil, doc: "Determines custom class for the content"
  attr :index, :integer, required: true, doc: "Determines item index"
  attr :icon_position, :string, doc: "Determines icon position"
  slot :inner_block, required: false, doc: "Inner block that renders HEEx content"

  defp speed_dial_content(%{navigate: nav, patch: pat, href: hrf} = assigns)
       when is_binary(nav) or is_binary(pat) or is_binary(hrf) do
    ~H"""
    <.link
      id={"#{@id}-speed-dial-item-#{@index}"}
      class={["block speed-dial-base flex flex-col", color_variant(@variant, @color)]}
      role="menuitem"
      tabindex="0"
      navigate={@navigate}
      patch={@patch}
      href={@href}
    >
      <.icon :if={@icon} name={@icon} class={["speed-dial-icon-base", @icon_class]} />
      <span :if={is_nil(@icon)} class={["block text-xs text-center", @content_class]}>
        {render_slot(@inner_block)}
      </span>
    </.link>
    """
  end

  defp speed_dial_content(assigns) do
    ~H"""
    <div
      id={"#{@id}-speed-dial-item-#{@index}"}
      class={["speed-dial-base flex flex-col", color_variant(@variant, @color)]}
    >
      <.icon :if={@icon} name={@icon} class={["speed-dial-icon-base", @icon_class]} />
      <span :if={is_nil(@icon)} class={["block text-xs text-center", @content_class]}>
        {render_slot(@inner_block)}
      </span>
    </div>
    """
  end

  defp trigger_dial(),
    do: "[&_.speed-dial-content]:hover:visible [&_.speed-dial-content]:hover:opacity-100"

  defp position_class("top") do
    [
      "[&_.speed-dial-content]:bottom-full [&_.speed-dial-content]:left-1/2",
      "[&_.speed-dial-content]:-translate-x-1/2 [&_.speed-dial-content]:-translate-y-[6px]"
    ]
  end

  defp position_class("bottom") do
    [
      "[&_.speed-dial-content]:top-full [&_.speed-dial-content]:left-1/2",
      "[&_.speed-dial-content]:-translate-x-1/2 [&_.speed-dial-content]:translate-y-[6px]"
    ]
  end

  defp position_class("left") do
    [
      "[&_.speed-dial-content]:right-full [&_.speed-dial-content]:top-1/2",
      "[&_.speed-dial-content]:-translate-y-1/2 [&_.speed-dial-content]:-translate-x-[6px]"
    ]
  end

  defp position_class("right") do
    [
      "[&_.speed-dial-content]:left-full [&_.speed-dial-content]:top-1/2",
      "[&_.speed-dial-content]:-translate-y-1/2 [&_.speed-dial-content]:translate-x-[6px]"
    ]
  end

  defp width_class("extra_small"), do: "[&_.speed-dial-content]:w-48"
  defp width_class("small"), do: "[&_.speed-dial-content]:w-52"
  defp width_class("medium"), do: "[&_.speed-dial-content]:w-56"
  defp width_class("large"), do: "[&_.speed-dial-content]:w-60"
  defp width_class("extra_large"), do: "[&_.speed-dial-content]:w-64"
  defp width_class("double_large"), do: "[&_.speed-dial-content]:w-72"
  defp width_class("triple_large"), do: "[&_.speed-dial-content]:w-80"
  defp width_class("quadruple_large"), do: "[&_.speed-dial-content]:w-96"
  defp width_class("fit"), do: "[&_.speed-dial-content]:w-fit"
  defp width_class(params) when is_binary(params), do: params

  defp space_class("extra_small", "top"), do: "[&_.speed-dial-content]:space-y-2"

  defp space_class("small", "top"), do: "[&_.speed-dial-content]:space-y-3"

  defp space_class("medium", "top"), do: "[&_.speed-dial-content]:space-y-4"

  defp space_class("large", "top"), do: "[&_.speed-dial-content]:space-y-5"

  defp space_class("extra_large", "top"), do: "[&_.speed-dial-content]:space-y-6"

  defp space_class("extra_small", "bottom"), do: "[&_.speed-dial-content]:space-y-2"

  defp space_class("small", "bottom"), do: "[&_.speed-dial-content]:space-y-3"

  defp space_class("medium", "bottom"), do: "[&_.speed-dial-content]:space-y-4"

  defp space_class("large", "bottom"), do: "[&_.speed-dial-content]:space-y-5"

  defp space_class("extra_large", "bottom"), do: "[&_.speed-dial-content]:space-y-6"

  defp space_class("extra_small", "left"), do: "[&_.speed-dial-content]:space-x-2"

  defp space_class("small", "left"), do: "[&_.speed-dial-content]:space-x-3"

  defp space_class("medium", "left"), do: "[&_.speed-dial-content]:space-x-4"

  defp space_class("large", "left"), do: "[&_.speed-dial-content]:space-x-5"

  defp space_class("extra_large", "left"), do: "[&_.speed-dial-content]:space-x-6"

  defp space_class("extra_small", "right"), do: "[&_.speed-dial-content]:space-x-2"

  defp space_class("small", "right"), do: "[&_.speed-dial-content]:space-x-3"

  defp space_class("medium", "right"), do: "[&_.speed-dial-content]:space-x-4"

  defp space_class("large", "right"), do: "[&_.speed-dial-content]:space-x-5"

  defp space_class("extra_large", "right"), do: "[&_.speed-dial-content]:space-x-6"

  defp space_class(params, _) when is_binary(params), do: params

  defp padding_class("none"), do: "[&_.speed-dial-content]:p-0"

  defp padding_class("extra_small"), do: "[&_.speed-dial-content]:p-1"

  defp padding_class("small"), do: "[&_.speed-dial-content]:p-1.5"

  defp padding_class("medium"), do: "[&_.speed-dial-content]:p-2"

  defp padding_class("large"), do: "[&_.speed-dial-content]:p-2.5"

  defp padding_class("extra_large"), do: "[&_.speed-dial-content]:p-3"

  defp padding_class(params) when is_binary(params), do: params

  defp rounded_size("none"), do: nil

  defp rounded_size("extra_small"), do: "[&_.speed-dial-base]:rounded-sm"

  defp rounded_size("small"), do: "[&_.speed-dial-base]:rounded"

  defp rounded_size("medium"), do: "[&_.speed-dial-base]:rounded-md"

  defp rounded_size("large"), do: "[&_.speed-dial-base]:rounded-lg"

  defp rounded_size("extra_large"), do: "[&_.speed-dial-base]:rounded-xl"

  defp rounded_size("full"), do: "[&_.speed-dial-base]:rounded-full"

  defp rounded_size(params) when is_binary(params), do: params

  defp size_class("extra_small") do
    [
      "[&_.speed-dial-content]:max-w-60 [&_.speed-dial-icon-base]:size-2.5 [&_.speed-dial-base]:size-7"
    ]
  end

  defp size_class("small") do
    [
      "[&_.speed-dial-content]:max-w-64 [&_.speed-dial-icon-base]:size-3 [&_.speed-dial-base]:size-8"
    ]
  end

  defp size_class("medium") do
    [
      "[&_.speed-dial-content]:max-w-72 [&_.speed-dial-icon-base]:size-3.5 [&_.speed-dial-base]:size-9"
    ]
  end

  defp size_class("large") do
    [
      "[&_.speed-dial-content]:max-w-80 [&_.speed-dial-icon-base]:size-4 [&_.speed-dial-base]:size-10"
    ]
  end

  defp size_class("extra_large") do
    [
      "[&_.speed-dial-content]:max-w-96 [&_.speed-dial-icon-base]:size-5 [&_.speed-dial-base]:size-11"
    ]
  end

  defp size_class("double_large") do
    [
      "[&_.speed-dial-content]:max-w-96 [&_.speed-dial-icon-base]:size-6 [&_.speed-dial-base]:size-12"
    ]
  end

  defp size_class("triple_large") do
    [
      "[&_.speed-dial-content]:max-w-96 [&_.speed-dial-icon-base]:size-7 [&_.speed-dial-base]:size-14"
    ]
  end

  defp size_class("quadruple_large") do
    [
      "[&_.speed-dial-content]:max-w-96 [&_.speed-dial-icon-base]:size-8 [&_.speed-dial-base]:size-16"
    ]
  end

  defp size_class(params) when is_binary(params), do: params

  defp border_class(_, variant) when variant in ["default", "shadow", "gradient"],
    do: nil

  defp border_class("none", _), do: "[&_.speed-dial-base]:border-0"
  defp border_class("extra_small", _), do: "[&_.speed-dial-base]:border"
  defp border_class("small", _), do: "[&_.speed-dial-base]:border-2"
  defp border_class("medium", _), do: "[&_.speed-dial-base]:border-[3px]"
  defp border_class("large", _), do: "[&_.speed-dial-base]:border-4"
  defp border_class("extra_large", _), do: "[&_.speed-dial-base]:border-[5px]"
  defp border_class(params, _) when is_binary(params), do: params

  defp action_position("none", "top-start"), do: "top-0 start-0"
  defp action_position("extra_small", "top-start"), do: "top-1 start-4"
  defp action_position("small", "top-start"), do: "top-2 start-5"
  defp action_position("medium", "top-start"), do: "top-3 start-6"
  defp action_position("large", "top-start"), do: "top-4 start-7"
  defp action_position("extra_large", "top-start"), do: "top-8 start-8"

  defp action_position("none", "top-end"), do: "top-0 end-0"
  defp action_position("extra_small", "top-end"), do: "top-4 end-4"
  defp action_position("small", "top-end"), do: "top-5 end-5"
  defp action_position("medium", "top-end"), do: "top-6 end-6"
  defp action_position("large", "top-end"), do: "top-7 end-7"
  defp action_position("extra_large", "top-end"), do: "top-8 end-8"

  defp action_position("none", "bottom-start"), do: "bottom-0 start-0"
  defp action_position("extra_small", "bottom-start"), do: "bottom-4 start-4"
  defp action_position("small", "bottom-start"), do: "bottom-5 start-5"
  defp action_position("medium", "bottom-start"), do: "bottom-6 start-6"
  defp action_position("large", "bottom-start"), do: "bottom-8 start-8"
  defp action_position("extra_large", "bottom-start"), do: "bottom-9 start-9"

  defp action_position("none", "bottom-end"), do: "bottom-0 end-0"
  defp action_position("extra_small", "bottom-end"), do: "bottom-4 end-4"
  defp action_position("small", "bottom-end"), do: "bottom-5 end-5"
  defp action_position("medium", "bottom-end"), do: "bottom-6 end-6"
  defp action_position("large", "bottom-end"), do: "bottom-8 end-8"
  defp action_position("extra_large", "bottom-end"), do: "bottom-9 end-9"
  defp action_position(params, _) when is_binary(params), do: params

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
    [
      "bg-natural-light text-white dark:bg-natural-dark dark:text-black"
    ]
  end

  defp color_variant("default", "primary") do
    [
      "bg-primary-light text-white dark:bg-primary-dark dark:text-black"
    ]
  end

  defp color_variant("default", "secondary") do
    [
      "bg-secondary-light text-white dark:bg-secondary-dark dark:text-black"
    ]
  end

  defp color_variant("default", "success") do
    [
      "bg-success-light text-white dark:bg-success-dark dark:text-black"
    ]
  end

  defp color_variant("default", "warning") do
    [
      "bg-warning-light text-white dark:bg-warning-dark dark:text-black"
    ]
  end

  defp color_variant("default", "danger") do
    [
      "bg-danger-light text-white dark:bg-danger-dark dark:text-black"
    ]
  end

  defp color_variant("default", "info") do
    [
      "bg-info-light text-white dark:bg-info-dark dark:text-black"
    ]
  end

  defp color_variant("default", "misc") do
    [
      "bg-misc-light text-white dark:bg-misc-dark dark:text-black"
    ]
  end

  defp color_variant("default", "dawn") do
    [
      "bg-dawn-light text-white dark:bg-dawn-dark dark:text-black"
    ]
  end

  defp color_variant("default", "silver") do
    [
      "bg-silver-light text-white dark:bg-silver-dark dark:text-black"
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
      "text-natural-bordered-text-light border-natural-bordered-text-light bg-natural-bordered-bg-light",
      "dark:text-natural-bordered-text-dark dark:border-natural-bordered-text-dark dark:bg-natural-bordered-bg-dark"
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
end
