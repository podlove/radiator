defmodule RadiatorWeb.Components.Dropdown do
  @moduledoc """
  The `RadiatorWeb.Components.Dropdown` module provides a customizable dropdown component
  built using Phoenix LiveView. It allows you to create dropdown menus with different styles,
  positions, and behaviors, supporting various customization options through attributes and slots.

  This module facilitates creating and managing dropdown components in a
  Phoenix LiveView application with flexible customization options.

  **Documentation:** https://mishka.tools/chelekom/docs/dropdown
  """

  use Phoenix.Component

  @doc """
  A `dropdown` component that displays a list of options or content when triggered.
  It can be activated by a click or hover, and positioned in various directions relative to its parent.

  ## Examples

  ```elixir
  <.dropdown relative="relative" position="right">
    <:trigger>
      <.button color="primary" icon="hero-chevron-down" right_icon>
        Dropdown Right
      </.button>
    </:trigger>

    <:content space="small" rounded="large" width="full" padding="extra_small">
      <.list size="small">
        <:item padding="extra_small" icon="hero-envelope">Dashboard</:item>
        <:item padding="extra_small" icon="hero-camera">Settings</:item>
        <:item padding="extra_small" icon="hero-camera">Earning</:item>
        <:item padding="extra_small" icon="hero-calendar">Sign out</:item>
      </.list>
    </:content>
  </.dropdown>

  <.dropdown relative="relative" clickable>
    <:trigger trigger_id="test-1">
      <.button color="primary" icon="hero-chevron-down" right_icon>
        Dropdown Button
      </.button>
    </:trigger>

    <:content id="test-1" space="small" rounded="large" width="full" padding="extra_small">
      <.list size="small">
        <:item padding="extra_small" icon="hero-envelope">Dashboard</:item>
        <:item padding="extra_small" icon="hero-camera">Settings</:item>
        <:item padding="extra_small" icon="hero-camera">Earning</:item>
        <:item padding="extra_small" icon="hero-calendar">Sign out</:item>
      </.list>
    </:content>
  </.dropdown>
  ```
  """
  @doc type: :component
  attr :id, :string,
    required: true,
    doc: "A unique identifier is used to manage state and interaction"

  attr :class, :string, default: nil, doc: "Custom CSS class for additional styling"
  attr :width, :string, default: "w-fit", doc: "Determines the element width"
  attr :position, :string, default: "bottom", doc: "Determines the element position"
  attr :relative, :string, default: nil, doc: "Custom relative position for the dropdown"

  attr :clickable, :boolean,
    default: true,
    doc: "Determines if the element can be activated on click"

  attr :smart_position, :boolean,
    default: false,
    doc: "Enables and disables smart position"

  attr :nomobile, :boolean,
    default: false,
    doc: "Controls whether the dropdown is disabled on mobile devices"

  attr :variant, :string, default: "base", doc: "Determines the style"
  attr :color, :string, default: "natural", doc: "Determines color theme"
  attr :rounded, :string, default: "", doc: "Determines the border radius"

  attr :size, :string,
    default: "",
    doc:
      "Determines the overall size of the elements, including padding, font size, and other items"

  attr :space, :string, default: "", doc: "Space between items"

  attr :font_weight, :string,
    default: "font-normal",
    doc: "Determines custom class for the font weight"

  attr :padding, :string, default: "none", doc: "Determines padding for items"
  attr :border, :string, default: "extra_small", doc: "Determines border style"

  attr :rest, :global,
    doc:
      "Global attributes can define defaults which are merged with attributes provided by the caller"

  slot :inner_block, required: false, doc: "Inner block that renders HEEx content"

  slot :trigger, required: false do
    attr :class, :string, doc: "Custom CSS class for additional styling"
  end

  slot :content, required: false do
    attr :class, :string, doc: "Custom CSS class for additional styling"
  end

  def dropdown(assigns) do
    ~H"""
    <div
      id={@id}
      data-position={@position || "bottom"}
      data-floating-type="dropdown"
      data-clickable={to_string(@clickable)}
      data-smart-position={to_string(@smart_position)}
      phx-hook="Floating"
      class={[
        "relative [&>.dropdown-content]:invisible [&>.dropdown-content]:opacity-0",
        "[&>.dropdown-content.show-dropdown]:visible [&>.dropdown-content.show-dropdown]:opacity-100",
        (!@nomobile && @position == "left") ||
          (@position == "right" && dropdown_mobile_position(@position)),
        @relative,
        @width,
        @class
      ]}
      {@rest}
    >
      <div
        :for={trigger <- @trigger}
        role="button"
        aria-haspopup="menu"
        aria-expanded="false"
        aria-controls={@id && "#{@id}-dropdown-content"}
        data-floating-trigger="true"
        class={["dropdown-trigger [&>*]:cursor-pointer", trigger[:class]]}
        {@rest}
      >
        {render_slot(trigger)}
      </div>

      <div
        :for={content <- @content}
        id={@id && "#{@id}-dropdown-content"}
        role="menu"
        tabindex="-1"
        aria-orientation="vertical"
        aria-labelledby={@id}
        aria-hidden="true"
        data-floating-content="true"
        hidden
        class={[
          "dropdown-content transition-all ease-in-out",
          space_class(@space),
          color_variant(@variant, @color),
          rounded_size(@rounded),
          size_class(@size),
          width_class(@width),
          border_class(@border, @variant),
          padding_size(@padding),
          @font_weight,
          @class
        ]}
        {@rest}
      >
        {render_slot(content)}
      </div>
      {render_slot(@inner_block)}
    </div>
    """
  end

  @doc """
  Defines a trigger for the dropdown component. When the element is clicked,
  it toggles the visibility of the associated dropdown content.

  ## Examples

  ```elixir
  <.dropdown_trigger>
    <.button color="primary" icon="hero-chevron-down" right_icon>Dropdown Right</.button>
  </.dropdown_trigger>
  ```
  """
  @doc type: :component
  attr :id, :string,
    default: nil,
    doc: "A unique identifier is used to manage state and interaction"

  attr :trigger_id, :string, default: nil, doc: "Identifies what is the triggered element id"
  attr :class, :string, default: nil, doc: "Custom CSS class for additional styling"
  slot :inner_block, required: false, doc: "Inner block that renders HEEx content"

  attr :rest, :global,
    doc:
      "Global attributes can define defaults which are merged with attributes provided by the caller"

  def dropdown_trigger(assigns) do
    ~H"""
    <div
      id={@id}
      role="button"
      aria-haspopup="menu"
      aria-expanded="false"
      aria-controls={@id && "#{@id}-dropdown-content"}
      data-floating-trigger="true"
      class={["cursor-pointer dropdown-trigger", @class]}
      {@rest}
    >
      {render_slot(@inner_block)}
    </div>
    """
  end

  @doc """
  Defines the content area of a dropdown component. The content appears when the dropdown trigger
  is activated and can be customized with various styles such as size, color, padding, and border.

  ## Examples

  ```elixir
  <.dropdown_content space="small" rounded="large" width="full" padding="extra_small">
    <.list size="small">
      <:item padding="extra_small" icon="hero-envelope">Dashboard</:item>
      <:item padding="extra_small" icon="hero-camera">Settings</:item>
      <:item padding="extra_small" icon="hero-camera">Earning</:item>
      <:item padding="extra_small" icon="hero-calendar">Sign out</:item>
    </.list>
  </.dropdown_content>
  ```
  """
  @doc type: :component
  attr :id, :string,
    default: nil,
    doc: "A unique identifier is used to manage state and interaction"

  attr :variant, :string, default: "base", doc: "Determines the style"
  attr :color, :string, default: "natural", doc: "Determines color theme"
  attr :rounded, :string, default: "", doc: "Determines the border radius"

  attr :size, :string,
    default: "",
    doc:
      "Determines the overall size of the elements, including padding, font size, and other items"

  attr :space, :string, default: "", doc: "Space between items"
  attr :width, :string, default: "extra_large", doc: "Determines the element width"

  attr :font_weight, :string,
    default: "font-normal",
    doc: "Determines custom class for the font weight"

  attr :padding, :string, default: "none", doc: "Determines padding for items"
  attr :border, :string, default: "extra_small", doc: "Determines border style"
  attr :class, :string, default: nil, doc: "Custom CSS class for additional styling"

  attr :rest, :global,
    doc:
      "Global attributes can define defaults which are merged with attributes provided by the caller"

  slot :inner_block, required: false, doc: "Inner block that renders HEEx content"

  def dropdown_content(assigns) do
    ~H"""
    <div
      id={@id && "#{@id}-dropdown-content"}
      role="menu"
      tabindex="-1"
      aria-orientation="vertical"
      aria-labelledby={@id}
      aria-hidden="true"
      data-floating-content="true"
      hidden
      class={[
        "dropdown-content transition-all ease-in-out",
        space_class(@space),
        color_variant(@variant, @color),
        rounded_size(@rounded),
        size_class(@size),
        width_class(@width),
        border_class(@border, @variant),
        padding_size(@padding),
        @font_weight,
        @class
      ]}
      {@rest}
    >
      {render_slot(@inner_block)}
    </div>
    """
  end

  defp dropdown_mobile_position("left") do
    [
      "md:[&>.dropdown-content]:right-full md:[&>.dropdown-content]:top-0",
      "md:[&>.dropdown-content]:-translate-x-[5%]",
      "[&>.dropdown-content]:top-full [&>.dropdown-content]:left-1/2",
      "[&>.dropdown-content]:translate-x-1/2 [&>.dropdown-content]:translate-y-[6px]"
    ]
  end

  defp dropdown_mobile_position("right") do
    [
      "md:[&>.dropdown-content]:left-full md:[&>.dropdown-content]:top-0",
      "md:[&>.dropdown-content]:translate-x-[5%]",
      "[&>.dropdown-content]:top-full [&>.dropdown-content]:left-1/2",
      "[&>.dropdown-content]:-translate-x-1/2 [&>.dropdown-content]:translate-y-[6px]"
    ]
  end

  defp border_class(_, variant) when variant in ["default", "shadow"], do: nil

  defp border_class("none", _), do: nil
  defp border_class("extra_small", _), do: "border"
  defp border_class("small", _), do: "border-2"
  defp border_class("medium", _), do: "border-[3px]"
  defp border_class("large", _), do: "border-4"
  defp border_class("extra_large", _), do: "border-[5px]"
  defp border_class(params, _) when is_binary(params), do: params

  defp rounded_size("extra_small"), do: "rounded-sm"

  defp rounded_size("small"), do: "rounded"

  defp rounded_size("medium"), do: "rounded-md"

  defp rounded_size("large"), do: "rounded-lg"

  defp rounded_size("extra_large"), do: "rounded-xl"

  defp rounded_size("none"), do: nil

  defp rounded_size(params) when is_binary(params), do: params

  defp size_class("extra_small"), do: "text-[12px]"

  defp size_class("small"), do: "text-[13px]"

  defp size_class("medium"), do: "text-[14px]"

  defp size_class("large"), do: "text-[15px]"

  defp size_class("extra_large"), do: "text-[16px]"

  defp size_class(params) when is_binary(params), do: params

  defp padding_size("extra_small"), do: "p-2"

  defp padding_size("small"), do: "p-3"

  defp padding_size("medium"), do: "p-4"

  defp padding_size("large"), do: "p-5"

  defp padding_size("extra_large"), do: "p-6"

  defp padding_size("none"), do: nil

  defp padding_size(params) when is_binary(params), do: params

  defp width_class("extra_small"), do: "lg:min-w-48"
  defp width_class("small"), do: "lg:min-w-52"
  defp width_class("medium"), do: "lg:min-w-56"
  defp width_class("large"), do: "lg:min-w-60"
  defp width_class("extra_large"), do: "lg:min-w-64"
  defp width_class("double_large"), do: "lg:min-w-72"
  defp width_class("triple_large"), do: "lg:min-w-80"
  defp width_class("quadruple_large"), do: "lg:min-w-96"
  defp width_class("full"), do: "w-full"
  defp width_class(params) when is_binary(params), do: params

  defp space_class("extra_small"), do: "space-y-2"

  defp space_class("small"), do: "space-y-3"

  defp space_class("medium"), do: "space-y-4"

  defp space_class("large"), do: "space-y-5"

  defp space_class("extra_large"), do: "space-y-6"

  defp space_class(params) when is_binary(params), do: params

  defp color_variant("base", _) do
    [
      "bg-white text-base-text-light border-base-border-light shadow-sm",
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

  defp color_variant("outline", "natural") do
    [
      "text-natural-light border-natural-light dark:text-natural-dark dark:border-natural-dark"
    ]
  end

  defp color_variant("outline", "primary") do
    [
      "text-primary-light border-primary-light dark:text-primary-dark dark:border-primary-dark"
    ]
  end

  defp color_variant("outline", "secondary") do
    [
      "text-secondary-light border-secondary-light dark:text-secondary-dark dark:border-secondary-dark"
    ]
  end

  defp color_variant("outline", "success") do
    [
      "text-success-light border-success-light dark:text-success-dark dark:border-success-dark"
    ]
  end

  defp color_variant("outline", "warning") do
    [
      "text-warning-light border-warning-light dark:text-warning-dark dark:border-warning-dark"
    ]
  end

  defp color_variant("outline", "danger") do
    [
      "text-danger-light border-danger-light dark:text-danger-dark dark:border-danger-dark"
    ]
  end

  defp color_variant("outline", "info") do
    [
      "text-info-light border-info-light dark:text-info-dark dark:border-info-dark"
    ]
  end

  defp color_variant("outline", "misc") do
    [
      "text-misc-light border-misc-light dark:text-misc-dark dark:border-misc-dark"
    ]
  end

  defp color_variant("outline", "dawn") do
    [
      "text-dawn-light border-dawn-light dark:text-dawn-dark dark:border-dawn-dark"
    ]
  end

  defp color_variant("outline", "silver") do
    [
      "text-silver-light border-silver-light dark:text-silver-dark dark:border-silver-dark"
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
