defmodule RadiatorWeb.Components.List do
  @moduledoc """
  The `RadiatorWeb.Components.List` module provides a versatile and customizable list
  component for building both ordered and unordered lists, as well as a list
  group component for more structured content. This module is designed to cater to
  various styles and use cases, such as navigation menus, data presentations, or simple item listings.

  ### Features

  - **Styling Variants:** The component offers multiple variants like `default`,
  `bordered`, `outline`, `outline_separated`, `bordered_separated`, and `transparent` to meet diverse design requirements.
  - **Color Customization:** Choose from a variety of colors to style the list according to
  your application's theme.
  - **Flexible Layouts:** Control the size, spacing, and appearance of list items with extensive
  customization options.
  - **Nested Structure:** Easily nest lists and group items together with the list group
  component for more complex layouts.

  This module is ideal for creating well-structured and visually appealing lists in
  your Phoenix LiveView applications.

  **Documentation:** https://mishka.tools/chelekom/docs/list
  """

  use Phoenix.Component
  import RadiatorWeb.Components.Icon, only: [icon: 1]

  @doc """
  Renders a `list` component that supports both ordered and unordered lists with customizable styles,
  sizes, and colors.

  ## Examples

  ```elixir
  <.list font_weight="font-bold" color="silver" size="small">
    <:item padding="small" count={1}>list count small</:item>
    <:item padding="small" count={2}>list count small</:item>
    <:item padding="small" count={3}>list count small</:item>
    <:item padding="small" count={23658}>list count small</:item>
  </.list>
  ```
  """
  @doc type: :component
  attr :id, :string,
    default: nil,
    doc: "A unique identifier is used to manage state and interaction"

  attr :class, :string, default: nil, doc: "Custom CSS class for additional styling"

  attr :font_weight, :string,
    default: "font-normal",
    doc: "Determines custom class for the font weight"

  attr :size, :string,
    default: "large",
    doc:
      "Determines the overall size of the elements, including padding, font size, and other items"

  attr :space, :string, default: "", doc: "Space between items"
  attr :border, :string, default: "extra_small", doc: "Border size"
  attr :color, :string, default: "natural", doc: "Determines color theme"
  attr :variant, :string, default: "transparent", doc: "Determines the style"
  attr :rounded, :string, default: "small", doc: "Determines the border radius"
  attr :hoverable, :boolean, default: false, doc: "active hover style"
  attr :style, :string, default: "list-none", doc: ""

  slot :item, validate_attrs: false do
    attr :id, :string, doc: "A unique identifier is used to manage state and interaction"
    attr :class, :string, doc: "Custom CSS class for additional styling"
    attr :count, :integer, doc: "Li counter"
    attr :count_separator, :string, doc: "Li counter separator"
    attr :icon, :string, doc: "Icon displayed alongside of an item"
    attr :icon_class, :string, doc: "Determines custom class for the icon"
    attr :content_class, :string, doc: "Determines custom class for the content"
    attr :padding, :string, doc: "Determines padding for items"
    attr :position, :string, doc: "Determines the element position"
    attr :title, :string, required: false
  end

  attr :rest, :global,
    include: ~w(ordered unordered),
    doc:
      "Global attributes can define defaults which are merged with attributes provided by the caller"

  slot :inner_block, doc: "Inner block that renders HEEx content"

  def list(%{rest: %{ordered: true}} = assigns) do
    ~H"""
    <.ol {assigns}>
      <.li :for={item <- @item} {item}>
        {render_slot(item)}
      </.li>
      {render_slot(@inner_block)}
    </.ol>
    """
  end

  def list(assigns) do
    ~H"""
    <.ul {assigns}>
      <.li
        :for={item <- @item}
        class={
          Enum.join(["[&_.list-content]:flex [&_.list-content]:items-center", item[:class]], " ")
        }
        {item}
      >
        <div :if={!is_nil(Map.get(item, :title))} class="font-semibold me-2">
          {item.title}
        </div>
        {render_slot(item)}
      </.li>
      {render_slot(@inner_block)}
    </.ul>
    """
  end

  @doc """
  Renders a list item (`li`) component with optional count, icon, and custom styles.
  This component is versatile and can be used within a list to display content with specific alignment,
  padding, and style.

  ## Examples

  ```elixir
  <.li>LI 1</.li>

  <.li>L2</.li>
  ```
  """
  @doc type: :component
  attr :id, :string,
    default: nil,
    doc: "A unique identifier is used to manage state and interaction"

  attr :class, :string, default: nil, doc: "Custom CSS class for additional styling"
  attr :count, :integer, default: nil, doc: "Li counter"
  attr :count_separator, :string, default: ". ", doc: "Li counter separator"
  attr :icon, :string, default: nil, doc: "Icon displayed alongside of an item"

  attr :icon_class, :string,
    default: "list-item-icon",
    doc: "Determines custom class for the icon"

  attr :content_class, :string, default: nil, doc: "Determines custom class for the content"
  attr :padding, :string, default: "", doc: "Determines padding for items"

  attr :position, :string,
    values: ["start", "end", "center"],
    default: "start",
    doc: "Determines the element position"

  attr :rest, :global,
    doc:
      "Global attributes can define defaults which are merged with attributes provided by the caller"

  slot :inner_block, required: true, doc: "Inner block that renders HEEx content"

  @spec li(map()) :: Phoenix.LiveView.Rendered.t()
  def li(assigns) do
    ~H"""
    <li
      id={@id}
      class={[
        padding_size(@padding),
        @class
      ]}
      {@rest}
    >
      <div class={[
        "flex items-center gap-2 w-full",
        content_position(@position)
      ]}>
        <.icon :if={!is_nil(@icon)} name={@icon} class={@icon_class} />
        <span :if={is_integer(@count)}>{@count}{@count_separator}</span>
        <div class={["w-full list-content", @content_class]}>
          {render_slot(@inner_block)}
        </div>
      </div>
    </li>
    """
  end

  @doc """
  Renders an unordered list (`ul`) component with customizable styles and attributes.
  You can define the appearance of the list using options for color, variant, size, width, and more.

  It supports a variety of styles including `list-disc` for bulleted lists.

  ## Examples

  ```elixir
  <.ul style="list-disc">
    <li>Default background ul list disc</li>
    <li>Default background ul list disc</li>
    <li>Default background ul list disc</li>
  </.ul>
  ```
  """
  @doc type: :component
  attr :id, :string,
    default: nil,
    doc: "A unique identifier is used to manage state and interaction"

  attr :color, :string, default: "natural", doc: "Determines color theme"
  attr :variant, :string, default: "transparent", doc: "Determines the style"

  attr :size, :string,
    default: "medium",
    doc:
      "Determines the overall size of the elements, including padding, font size, and other items"

  attr :width, :string, default: "full", doc: "Determines the element width"
  attr :border, :string, default: "extra_small", doc: "Border size"
  attr :style, :string, default: "list-none", doc: "Determines the element style"
  attr :rounded, :string, default: "small", doc: "Determines the border radius"
  attr :class, :string, default: nil, doc: "Custom CSS class for additional styling"
  attr :hoverable, :boolean, default: false, doc: "active hover style"

  attr :space, :string, default: "", doc: "Space between items"

  attr :font_weight, :string,
    default: "font-normal",
    doc: "Determines custom class for the font weight"

  attr :rest, :global,
    doc:
      "Global attributes can define defaults which are merged with attributes provided by the caller"

  slot :inner_block, required: true, doc: "Inner block that renders HEEx content"

  def ul(assigns) do
    ~H"""
    <ul
      id={@id}
      class={[
        "[&.list-decimal]:ps-5 [&.list-disc]:ps-5",
        color_variant(@variant, @color, @hoverable),
        border_class(@border, @variant),
        rounded_size(@rounded),
        size_class(@size),
        width_class(@width),
        variant_space(@space, @variant),
        @style,
        @font_weight,
        @class
      ]}
      {@rest}
    >
      {render_slot(@inner_block)}
    </ul>
    """
  end

  @doc """
  Renders an ordered list (`ol`) component with customizable styles and attributes.
  The list can be styled with different colors, variants, sizes, widths, and spacing to
  fit various design needs.

  ## Examples

  ```elixir
  <.ol style="list-decimal">
    <li>Ordered list item 1</li>
    <li>Ordered list item 2</li>
    <li>Ordered list item 3</li>
  </.ol>
  ```
  """
  @doc type: :component
  attr :id, :string,
    default: nil,
    doc: "A unique identifier is used to manage state and interaction"

  attr :color, :string, default: "natural", doc: "Determines color theme"
  attr :variant, :string, default: "transparent", doc: "Determines the style"

  attr :size, :string,
    default: "medium",
    doc:
      "Determines the overall size of the elements, including padding, font size, and other items"

  attr :width, :string, default: "full", doc: "Determines the element width"
  attr :border, :string, default: "extra_small", doc: "Border size"
  attr :rounded, :string, default: "small", doc: "Determines the border radius"
  attr :class, :string, default: nil, doc: "Custom CSS class for additional styling"
  attr :space, :string, default: "", doc: "Space between items"
  attr :hoverable, :boolean, default: false, doc: "active hover style"

  attr :font_weight, :string,
    default: "font-normal",
    doc: "Determines custom class for the font weight"

  attr :rest, :global,
    doc:
      "Global attributes can define defaults which are merged with attributes provided by the caller"

  slot :inner_block, required: true, doc: "Inner block that renders HEEx content"

  def ol(assigns) do
    ~H"""
    <ol
      id={@id}
      class={[
        "list-decimal [&.list-decimal]:ps-5 [&.list-disc]:ps-5",
        color_variant(@variant, @color, @hoverable),
        border_class(@border, @variant),
        size_class(@size),
        rounded_size(@rounded),
        width_class(@width),
        variant_space(@space, @variant),
        @font_weight,
        @class
      ]}
      {@rest}
    >
      {render_slot(@inner_block)}
    </ol>
    """
  end

  @doc """
  Renders a list group component with customizable styles, borders, and padding. It can be used to group list items with different variants, colors, and sizes.

  ## Examples

  ```elixir
  <.list_group variant="separated" rounded="extra_small" color="dawn">
    <.li position="end" icon="hero-chat-bubble-left-ellipsis">HBase</.li>
    <.li>SQL</.li>
    <.li>Sqlight</.li>
  </.list_group>
  ```
  """
  @doc type: :component
  attr :id, :string,
    default: nil,
    doc: "A unique identifier is used to manage state and interaction"

  attr :variant, :string, default: "transparent", doc: "Determines the style"
  attr :color, :string, default: "natural", doc: "Determines color theme"

  attr :size, :string,
    default: "medium",
    doc:
      "Determines the overall size of the elements, including padding, font size, and other items"

  attr :width, :string, default: "full", doc: "Determines the element width"
  attr :space, :string, default: "small", doc: "Space between items"
  attr :hoverable, :boolean, default: false, doc: "active hover style"
  attr :rounded, :string, default: "small", doc: "Determines the border radius"
  attr :border, :string, default: "extra_small", doc: "Determines border style"

  attr :font_weight, :string,
    default: "font-normal",
    doc: "Determines custom class for the font weight"

  attr :padding, :string, default: "", doc: "Determines padding for items"

  attr :class, :string, default: nil, doc: "Custom CSS class for additional styling"

  attr :rest, :global,
    doc:
      "Global attributes can define defaults which are merged with attributes provided by the caller"

  slot :inner_block, required: true, doc: "Inner block that renders HEEx content"

  def list_group(assigns) do
    ~H"""
    <ul
      id={@id}
      class={[
        "overflow-hidden",
        rounded_size(@rounded),
        variant_space(@space, @variant),
        padding_size(@padding),
        width_class(@width),
        border_class(@border, @variant),
        size_class(@size),
        color_variant(@variant, @color, @hoverable),
        @font_weight,
        @class
      ]}
      {@rest}
    >
      {render_slot(@inner_block)}
    </ul>
    """
  end

  defp content_position("start") do
    "justify-start"
  end

  defp content_position("end") do
    "justify-end"
  end

  defp content_position("center") do
    "justify-center"
  end

  defp content_position(params) when is_binary(params), do: params

  defp rounded_size("extra_small"),
    do: "[&:not(.list-items-gap)]:rounded-sm [&.list-items-gap>li]:rounded-sm"

  defp rounded_size("small"), do: "[&:not(.list-items-gap)]:rounded [&.list-items-gap>li]:rounded"

  defp rounded_size("medium"),
    do: "[&:not(.list-items-gap)]:rounded-md [&.list-items-gap>li]:rounded-md"

  defp rounded_size("large"),
    do: "[&:not(.list-items-gap)]:rounded-lg [&.list-items-gap>li]:rounded-lg"

  defp rounded_size("extra_large"),
    do: "[&:not(.list-items-gap)]:rounded-xl [&.list-items-gap>li]:rounded-xl"

  defp rounded_size("full"),
    do: "[&:not(.list-items-gap)]:rounded-full [&.list-items-gap>li]:rounded-full"

  defp rounded_size("none"),
    do: "[&:not(.list-items-gap)]:rounded-none [&.list-items-gap>li]:rounded-none"

  defp variant_space(_, variant)
       when variant not in ["outline_separated", "bordered_separated", "base_separated"],
       do: nil

  defp variant_space("extra_small", _), do: "list-items-gap space-y-2"

  defp variant_space("small", _), do: "list-items-gap space-y-3"

  defp variant_space("medium", _), do: "list-items-gap space-y-4"

  defp variant_space("large", _), do: "list-items-gap space-y-5"

  defp variant_space("extra_large", _), do: "list-items-gap space-y-6"

  defp variant_space(params, _) when is_binary(params), do: params

  defp width_class("extra_small"), do: "w-60"
  defp width_class("small"), do: "w-64"
  defp width_class("medium"), do: "w-72"
  defp width_class("large"), do: "w-80"
  defp width_class("extra_large"), do: "w-96"
  defp width_class("full"), do: "w-full"
  defp width_class(params) when is_binary(params), do: params

  defp size_class("extra_small"), do: "text-xs [&_.list-item-icon]:size-4"

  defp size_class("small"), do: "text-sm [&_.list-item-icon]:size-5"

  defp size_class("medium"), do: "text-base [&_.list-item-icon]:size-6"

  defp size_class("large"), do: "text-lg [&_.list-item-icon]:size-7"

  defp size_class("extra_large"), do: "text-xl [&_.list-item-icon]:size-8"

  defp size_class(params) when is_binary(params), do: params

  defp padding_size("extra_small"), do: "p-1"

  defp padding_size("small"), do: "p-2"

  defp padding_size("medium"), do: "p-3"

  defp padding_size("large"), do: "p-4"

  defp padding_size("extra_large"), do: "p-5"

  defp padding_size(params) when is_binary(params), do: params

  defp border_class(_, variant) when variant in ["default", "shadow", "transparent", "gradient"],
    do: nil

  defp border_class("none", "outline"), do: "border-0 [&>li:not(:last-child)]:border-b-0"

  defp border_class("extra_small", "outline"), do: "border [&>li:not(:last-child)]:border-b"

  defp border_class("small", "outline"), do: "border-2 [&>li:not(:last-child)]:border-b-2"

  defp border_class("medium", "outline"),
    do: "border-[3px] [&>li:not(:last-child)]:border-b-[3px]"

  defp border_class("large", "outline"), do: "border-4 [&>li:not(:last-child)]:border-b-4"

  defp border_class("extra_large", "outline"),
    do: "border-[5px] [&>li:not(:last-child)]:border-b-[5px]"

  defp border_class("none", "bordered"), do: "border-0 [&>li:not(:last-child)]:border-b-0"

  defp border_class("extra_small", "bordered"), do: "border [&>li:not(:last-child)]:border-b"

  defp border_class("small", "bordered"), do: "border-2 [&>li:not(:last-child)]:border-b-2"

  defp border_class("medium", "bordered"),
    do: "border-[3px] [&>li:not(:last-child)]:border-b-[3px]"

  defp border_class("large", "bordered"), do: "border-4 [&>li:not(:last-child)]:border-b-4"

  defp border_class("extra_large", "bordered"),
    do: "border-[5px] [&>li:not(:last-child)]:border-b-[5px]"

  defp border_class("none", "bordered_separated"), do: "[&>li]:border-0"

  defp border_class("extra_small", "bordered_separated"), do: "[&>li]:border"

  defp border_class("small", "bordered_separated"), do: "[&>li]:border-2"

  defp border_class("medium", "bordered_separated"), do: "[&>li]:border-[3px]"

  defp border_class("large", "bordered_separated"), do: "[&>li]:border-4"

  defp border_class("extra_large", "bordered_separated"), do: "[&>li]:border-[5px]"

  defp border_class("none", "outline_separated"), do: "[&>li]:border-0"

  defp border_class("extra_small", "outline_separated"), do: "[&>li]:border"

  defp border_class("small", "outline_separated"), do: "[&>li]:border-2"

  defp border_class("medium", "outline_separated"), do: "[&>li]:border-[3px]"

  defp border_class("large", "outline_separated"), do: "[&>li]:border-4"

  defp border_class("extra_large", "outline_separated"), do: "[&>li]:border-[5px]"

  defp border_class("none", "base"), do: "border-0 [&>li:not(:last-child)]:border-b-0"

  defp border_class("extra_small", "base"), do: "border [&>li:not(:last-child)]:border-b"

  defp border_class("small", "base"), do: "border-2 [&>li:not(:last-child)]:border-b-2"

  defp border_class("medium", "base"),
    do: "border-[3px] [&>li:not(:last-child)]:border-b-[3px]"

  defp border_class("large", "base"), do: "border-4 [&>li:not(:last-child)]:border-b-4"

  defp border_class("extra_large", "base"),
    do: "border-[5px] [&>li:not(:last-child)]:border-b-[5px]"

  defp border_class("none", "base_separated"), do: "[&>li]:border-0"

  defp border_class("extra_small", "base_separated"), do: "[&>li]:border"

  defp border_class("small", "base_separated"), do: "[&>li]:border-2"

  defp border_class("medium", "base_separated"), do: "[&>li]:border-[3px]"

  defp border_class("large", "base_separated"), do: "[&>li]:border-4"

  defp border_class("extra_large", "base_separated"), do: "[&>li]:border-[5px]"

  defp border_class(params, _) when is_binary(params), do: params

  defp color_variant("base", _, hoverable) do
    [
      "bg-white text-base-text-light border-base-border-light shadow-sm",
      "dark:bg-base-bg-dark dark:text-base-text-dark dark:border-base-border-dark",
      "[&>li:not(:last-child)]:border-base-border-light dark:[&>li:not(:last-child)]:border-base-border-dark",
      hoverable && "[&_li]:hover:bg-base-hover-light dark:[&_li]:hover:bg-base-hover-dark"
    ]
  end

  defp color_variant("base_separated", _, hoverable) do
    [
      "[&>li]:text-base-text-light [&>li]:border-base-border-light [&>li]:bg-white",
      "dark:[&>li]:text-base-text-dark dark:[&>li]:border-base-border-dark dark:[&>li]:bg-base-bg-dark",
      hoverable && "[&_li]:hover:bg-base-hover-light dark:[&_li]:hover:bg-base-hover-dark"
    ]
  end

  defp color_variant("default", "white", hoverable) do
    [
      "bg-white text-black",
      hoverable && "[&_li]:hover:bg-base-disabled-bg-light"
    ]
  end

  defp color_variant("default", "dark", hoverable) do
    [
      "bg-default-dark-bg text-white",
      hoverable && "[&_li]:hover:bg-natural-bg-dark"
    ]
  end

  defp color_variant("default", "natural", hoverable) do
    [
      "bg-natural-light text-white dark:bg-natural-dark dark:text-black",
      hoverable && "[&_li]:hover:bg-black dark:[&_li]:hover:bg-white"
    ]
  end

  defp color_variant("default", "primary", hoverable) do
    [
      "bg-primary-light text-white dark:bg-primary-dark dark:text-black",
      hoverable &&
        "[&_li]:hover:bg-primary-indicator-light dark:[&_li]:hover:bg-primary-indicator-dark"
    ]
  end

  defp color_variant("default", "secondary", hoverable) do
    [
      "bg-secondary-light text-white dark:bg-secondary-dark dark:text-black",
      hoverable &&
        "[&_li]:hover:bg-secondary-indicator-light dark:[&_li]:hover:bg-secondary-indicator-dark"
    ]
  end

  defp color_variant("default", "success", hoverable) do
    [
      "bg-success-light text-white dark:bg-success-dark dark:text-black",
      hoverable &&
        "[&_li]:hover:bg-success-indicator-alt-light dark:[&_li]:hover:bg-success-indicator-dark"
    ]
  end

  defp color_variant("default", "warning", hoverable) do
    [
      "bg-warning-light text-white dark:bg-warning-dark dark:text-black",
      hoverable &&
        "[&_li]:hover:bg-warning-indicator-alt-light dark:[&_li]:hover:bg-warning-indicator-dark"
    ]
  end

  defp color_variant("default", "danger", hoverable) do
    [
      "bg-danger-light text-white dark:bg-danger-dark dark:text-black",
      hoverable &&
        "[&_li]:hover:bg-danger-indicator-alt-light dark:[&_li]:hover:bg-danger-indicator-dark"
    ]
  end

  defp color_variant("default", "info", hoverable) do
    [
      "bg-info-light text-white dark:bg-info-dark dark:text-black",
      hoverable &&
        "[&_li]:hover:bg-info-indicator-alt-light dark:[&_li]:hover:bg-info-indicator-dark"
    ]
  end

  defp color_variant("default", "misc", hoverable) do
    [
      "bg-misc-light text-white dark:bg-misc-dark dark:text-black",
      hoverable &&
        "[&_li]:hover:bg-misc-indicator-alt-light dark:[&_li]:hover:bg-misc-indicator-dark"
    ]
  end

  defp color_variant("default", "dawn", hoverable) do
    [
      "bg-dawn-light text-white dark:bg-dawn-dark dark:text-black",
      hoverable &&
        "[&_li]:hover:bg-dawn-indicator-alt-light dark:[&_li]:hover:bg-dawn-indicator-dark"
    ]
  end

  defp color_variant("default", "silver", hoverable) do
    [
      "bg-silver-light text-white dark:bg-silver-dark dark:text-black",
      hoverable &&
        "[&_li]:hover:bg-silver-indicator-alt-light dark:[&_li]:hover:bg-silver-indicator-dark"
    ]
  end

  defp color_variant("outline", "natural", hoverable) do
    [
      "text-natural-light border-natural-light dark:text-natural-dark dark:border-natural-dark",
      "[&>li:not(:last-child)]:border-natural-light dark:[&>li:not(:last-child)]:border-natural-dark",
      hoverable &&
        "[&_li]:hover:text-white dark:[&_li]:hover:text-black [&_li]:hover:bg-black dark:[&_li]:hover:bg-white"
    ]
  end

  defp color_variant("outline", "primary", hoverable) do
    [
      "text-primary-light border-primary-light dark:text-primary-dark dark:border-primary-dark",
      "[&>li:not(:last-child)]:border-primary-light dark:[&>li:not(:last-child)]:border-primary-dark",
      hoverable &&
        "[&_li]:hover:text-white dark:[&_li]:hover:text-black [&_li]:hover:bg-primary-indicator-light dark:[&_li]:hover:bg-primary-indicator-dark"
    ]
  end

  defp color_variant("outline", "secondary", hoverable) do
    [
      "text-secondary-light border-secondary-light dark:text-secondary-dark dark:border-secondary-dark",
      "[&>li:not(:last-child)]:border-secondary-light dark:[&>li:not(:last-child)]:border-secondary-dark",
      hoverable &&
        "[&_li]:hover:text-white dark:[&_li]:hover:text-black [&_li]:hover:bg-secondary-indicator-light dark:[&_li]:hover:bg-secondary-indicator-dark"
    ]
  end

  defp color_variant("outline", "success", hoverable) do
    [
      "text-success-light border-success-light dark:text-success-dark dark:border-success-dark",
      "[&>li:not(:last-child)]:border-success-light dark:[&>li:not(:last-child)]:border-success-dark",
      hoverable &&
        "[&_li]:hover:text-white dark:[&_li]:hover:text-black [&_li]:hover:bg-success-indicator-alt-light dark:[&_li]:hover:bg-success-indicator-dark"
    ]
  end

  defp color_variant("outline", "warning", hoverable) do
    [
      "text-warning-light border-warning-light dark:text-warning-dark dark:border-warning-dark",
      "[&>li:not(:last-child)]:border-warning-light dark:[&>li:not(:last-child)]:border-warning-dark",
      hoverable &&
        "[&_li]:hover:text-white dark:[&_li]:hover:text-black [&_li]:hover:bg-warning-indicator-alt-light dark:[&_li]:hover:bg-warning-indicator-dark"
    ]
  end

  defp color_variant("outline", "danger", hoverable) do
    [
      "text-danger-light border-danger-light dark:text-danger-dark dark:border-danger-dark",
      "[&>li:not(:last-child)]:border-danger-light dark:[&>li:not(:last-child)]:border-danger-dark",
      hoverable &&
        "[&_li]:hover:text-white dark:[&_li]:hover:text-black [&_li]:hover:bg-danger-indicator-alt-light dark:[&_li]:hover:bg-danger-indicator-dark"
    ]
  end

  defp color_variant("outline", "info", hoverable) do
    [
      "text-info-light border-info-light dark:text-info-dark dark:border-info-dark",
      "[&>li:not(:last-child)]:border-info-light dark:[&>li:not(:last-child)]:border-info-dark",
      hoverable &&
        "[&_li]:hover:text-white dark:[&_li]:hover:text-black [&_li]:hover:bg-info-indicator-alt-light dark:[&_li]:hover:bg-info-indicator-dark"
    ]
  end

  defp color_variant("outline", "misc", hoverable) do
    [
      "text-misc-light border-misc-light dark:text-misc-dark dark:border-misc-dark",
      "[&>li:not(:last-child)]:border-misc-light dark:[&>li:not(:last-child)]:border-misc-dark",
      hoverable &&
        "[&_li]:hover:text-white dark:[&_li]:hover:text-black [&_li]:hover:bg-misc-indicator-alt-light dark:[&_li]:hover:bg-misc-indicator-dark"
    ]
  end

  defp color_variant("outline", "dawn", hoverable) do
    [
      "text-dawn-light border-dawn-light dark:text-dawn-dark dark:border-dawn-dark",
      "[&>li:not(:last-child)]:border-dawn-light dark:[&>li:not(:last-child)]:border-dawn-dark",
      hoverable &&
        "[&_li]:hover:text-white dark:[&_li]:hover:text-black [&_li]:hover:bg-dawn-indicator-alt-light dark:[&_li]:hover:bg-dawn-indicator-dark"
    ]
  end

  defp color_variant("outline", "silver", hoverable) do
    [
      "text-silver-light border-silver-light dark:text-silver-dark dark:border-silver-dark",
      "[&>li:not(:last-child)]:border-silver-light dark:[&>li:not(:last-child)]:border-silver-dark",
      hoverable &&
        "[&_li]:hover:text-white dark:[&_li]:hover:text-black [&_li]:hover:bg-silver-indicator-alt-light dark:[&_li]:hover:bg-silver-indicator-dark"
    ]
  end

  defp color_variant("shadow", "natural", hoverable) do
    [
      "bg-natural-light text-white dark:bg-natural-dark dark:text-black",
      "shadow-[0px_4px_6px_-4px_var(--color-shadow-natural)] shadow-[0px_10px_15px_-3px_var(--color-shadow-natural)] dark:shadow-none",
      hoverable && "[&_li]:hover:bg-black dark:[&_li]:hover:bg-white"
    ]
  end

  defp color_variant("shadow", "primary", hoverable) do
    [
      "bg-primary-light text-white dark:bg-primary-dark dark:text-black",
      "shadow-[0px_4px_6px_-4px_var(--color-shadow-primary)] shadow-[0px_10px_15px_-3px_var(--color-shadow-primary)] dark:shadow-none",
      hoverable &&
        "[&_li]:hover:bg-primary-indicator-light dark:[&_li]:hover:bg-primary-indicator-dark"
    ]
  end

  defp color_variant("shadow", "secondary", hoverable) do
    [
      "bg-secondary-light text-white dark:bg-secondary-dark dark:text-black",
      "shadow-[0px_4px_6px_-4px_var(--color-shadow-secondary)] shadow-[0px_10px_15px_-3px_var(--color-shadow-secondary)] dark:shadow-none",
      hoverable &&
        "[&_li]:hover:bg-secondary-indicator-light dark:[&_li]:hover:bg-secondary-indicator-dark"
    ]
  end

  defp color_variant("shadow", "success", hoverable) do
    [
      "bg-success-light text-white dark:bg-success-dark dark:text-black",
      "shadow-[0px_4px_6px_-4px_var(--color-shadow-success)] shadow-[0px_10px_15px_-3px_var(--color-shadow-success)] dark:shadow-none",
      hoverable &&
        "[&_li]:hover:bg-success-indicator-alt-light dark:[&_li]:hover:bg-success-indicator-dark"
    ]
  end

  defp color_variant("shadow", "warning", hoverable) do
    [
      "bg-warning-light text-white dark:bg-warning-dark dark:text-black",
      "shadow-[0px_4px_6px_-4px_var(--color-shadow-warning)] shadow-[0px_10px_15px_-3px_var(--color-shadow-warning)] dark:shadow-none",
      hoverable &&
        "[&_li]:hover:bg-warning-indicator-alt-light dark:[&_li]:hover:bg-warning-indicator-dark"
    ]
  end

  defp color_variant("shadow", "danger", hoverable) do
    [
      "bg-danger-light text-white dark:bg-danger-dark dark:text-black",
      "shadow-[0px_4px_6px_-4px_var(--color-shadow-danger)] shadow-[0px_10px_15px_-3px_var(--color-shadow-danger)] dark:shadow-none",
      hoverable &&
        "[&_li]:hover:bg-danger-indicator-alt-light dark:[&_li]:hover:bg-danger-indicator-dark"
    ]
  end

  defp color_variant("shadow", "info", hoverable) do
    [
      "bg-info-light text-white dark:bg-info-dark dark:text-black",
      "shadow-[0px_4px_6px_-4px_var(--color-shadow-info)] shadow-[0px_10px_15px_-3px_var(--color-shadow-info)] dark:shadow-none",
      hoverable &&
        "[&_li]:hover:bg-info-indicator-alt-light dark:[&_li]:hover:bg-info-indicator-dark"
    ]
  end

  defp color_variant("shadow", "misc", hoverable) do
    [
      "bg-misc-light text-white dark:bg-misc-dark dark:text-black",
      "shadow-[0px_4px_6px_-4px_var(--color-shadow-misc)] shadow-[0px_10px_15px_-3px_var(--color-shadow-misc)] dark:shadow-none",
      hoverable &&
        "[&_li]:hover:bg-misc-indicator-alt-light dark:[&_li]:hover:bg-misc-indicator-dark"
    ]
  end

  defp color_variant("shadow", "dawn", hoverable) do
    [
      "bg-dawn-light text-white dark:bg-dawn-dark dark:text-black",
      "shadow-[0px_4px_6px_-4px_var(--color-shadow-dawn)] shadow-[0px_10px_15px_-3px_var(--color-shadow-dawn)] dark:shadow-none",
      hoverable &&
        "[&_li]:hover:bg-dawn-indicator-alt-light dark:[&_li]:hover:bg-dawn-indicator-dark"
    ]
  end

  defp color_variant("shadow", "silver", hoverable) do
    [
      "bg-silver-light text-white dark:bg-silver-dark dark:text-black",
      "shadow-[0px_4px_6px_-4px_var(--color-shadow-silver)] shadow-[0px_10px_15px_-3px_var(--color-shadow-silver)] dark:shadow-none",
      hoverable &&
        "[&_li]:hover:bg-silver-indicator-alt-light dark:[&_li]:hover:bg-silver-indicator-dark"
    ]
  end

  defp color_variant("bordered", "white", hoverable) do
    [
      "bg-white text-black border-bordered-white-border",
      "[&>li:not(:last-child)]:border-bordered-white-border",
      hoverable && "[&_li]:hover:text-black [&_li]:hover:bg-natural-bg-dark"
    ]
  end

  defp color_variant("bordered", "dark", hoverable) do
    [
      "bg-bordered-dark-bg text-white border-bordered-dark-border",
      "[&>li:not(:last-child)]:border-bordered-dark-border",
      hoverable && "[&_li]:hover:text-white [&_li]:hover:bg-natural-bg-dark"
    ]
  end

  defp color_variant("bordered", "natural", hoverable) do
    [
      "text-natural-bordered-text-light border-natural-bordered-text-light bg-natural-bordered-bg-light",
      "dark:text-natural-bordered-text-dark dark:border-natural-bordered-text-dark dark:bg-natural-bordered-bg-dark",
      "[&>li:not(:last-child)]:border-natural-bordered-text-light dark:[&>li:not(:last-child)]:border-natural-bordered-text-dark",
      hoverable &&
        "[&_li]:hover:text-white dark:[&_li]:hover:text-black [&_li]:hover:bg-black dark:[&_li]:hover:bg-white"
    ]
  end

  defp color_variant("bordered", "primary", hoverable) do
    [
      "text-primary-bordered-text-light border-primary-bordered-text-light bg-primary-bordered-bg-light",
      "dark:text-primary-bordered-text-dark dark:border-primary-bordered-text-dark dark:bg-primary-bordered-bg-dark",
      "[&>li:not(:last-child)]:border-primary-bordered-text-light dark:[&>li:not(:last-child)]:border-primary-bordered-text-dark",
      hoverable &&
        "[&_li]:hover:text-white dark:[&_li]:hover:text-black [&_li]:hover:bg-primary-indicator-light dark:[&_li]:hover:bg-primary-indicator-dark"
    ]
  end

  defp color_variant("bordered", "secondary", hoverable) do
    [
      "text-secondary-bordered-text-light border-secondary-bordered-text-light bg-secondary-bordered-bg-light",
      "dark:text-secondary-bordered-text-dark dark:border-secondary-bordered-text-dark dark:bg-secondary-bordered-bg-dark",
      "[&>li:not(:last-child)]:border-secondary-bordered-text-light dark:[&>li:not(:last-child)]:border-secondary-bordered-text-dark",
      hoverable &&
        "[&_li]:hover:text-white dark:[&_li]:hover:text-black [&_li]:hover:bg-secondary-indicator-light dark:[&_li]:hover:bg-secondary-indicator-dark"
    ]
  end

  defp color_variant("bordered", "success", hoverable) do
    [
      "text-success-bordered-text-light border-success-bordered-text-light bg-success-bordered-bg-light",
      "dark:text-success-bordered-text-dark dark:border-success-bordered-text-dark dark:bg-success-bordered-bg-dark",
      "[&>li:not(:last-child)]:border-success-bordered-text-light dark:[&>li:not(:last-child)]:border-success-bordered-text-dark",
      hoverable &&
        "[&_li]:hover:text-white dark:[&_li]:hover:text-black [&_li]:hover:bg-success-indicator-alt-light dark:[&_li]:hover:bg-success-indicator-dark"
    ]
  end

  defp color_variant("bordered", "warning", hoverable) do
    [
      "text-warning-bordered-text-light border-warning-bordered-text-light bg-warning-bordered-bg-light",
      "dark:text-warning-bordered-text-dark dark:border-warning-bordered-text-dark dark:bg-warning-bordered-bg-dark",
      "[&>li:not(:last-child)]:border-warning-bordered-text-light dark:[&>li:not(:last-child)]:border-warning-bordered-text-dark",
      hoverable &&
        "[&_li]:hover:text-white dark:[&_li]:hover:text-black [&_li]:hover:bg-warning-indicator-alt-light dark:[&_li]:hover:bg-warning-indicator-dark"
    ]
  end

  defp color_variant("bordered", "danger", hoverable) do
    [
      "text-danger-bordered-text-light border-danger-bordered-text-light bg-danger-bordered-bg-light",
      "dark:text-danger-bordered-text-dark dark:border-danger-bordered-text-dark dark:bg-danger-bordered-bg-dark",
      "[&>li:not(:last-child)]:border-danger-bordered-text-light dark:[&>li:not(:last-child)]:border-danger-bordered-text-dark",
      hoverable &&
        "[&_li]:hover:text-white dark:[&_li]:hover:text-black [&_li]:hover:bg-danger-indicator-alt-light dark:[&_li]:hover:bg-danger-indicator-dark"
    ]
  end

  defp color_variant("bordered", "info", hoverable) do
    [
      "text-info-bordered-text-light border-info-bordered-text-light bg-info-bordered-bg-light",
      "dark:text-info-bordered-text-dark dark:border-info-bordered-text-dark dark:bg-info-bordered-bg-dark",
      "[&>li:not(:last-child)]:border-info-bordered-text-light dark:[&>li:not(:last-child)]:border-info-bordered-text-dark",
      hoverable &&
        "[&_li]:hover:text-white dark:[&_li]:hover:text-black [&_li]:hover:bg-info-indicator-alt-light dark:[&_li]:hover:bg-info-indicator-dark"
    ]
  end

  defp color_variant("bordered", "misc", hoverable) do
    [
      "text-misc-bordered-text-light border-misc-bordered-text-light bg-misc-bordered-bg-light",
      "dark:text-misc-bordered-text-dark dark:border-misc-bordered-text-dark dark:bg-misc-bordered-bg-dark",
      "[&>li:not(:last-child)]:border-misc-bordered-text-light dark:[&>li:not(:last-child)]:border-misc-bordered-text-dark",
      hoverable &&
        "[&_li]:hover:text-white dark:[&_li]:hover:text-black [&_li]:hover:bg-misc-indicator-alt-light dark:[&_li]:hover:bg-misc-indicator-dark"
    ]
  end

  defp color_variant("bordered", "dawn", hoverable) do
    [
      "text-dawn-bordered-text-light border-dawn-bordered-text-light bg-dawn-bordered-bg-light",
      "dark:text-dawn-bordered-text-dark dark:border-dawn-bordered-text-dark dark:bg-dawn-bordered-bg-dark",
      "[&>li:not(:last-child)]:border-dawn-bordered-text-light dark:[&>li:not(:last-child)]:border-dawn-bordered-text-dark",
      hoverable &&
        "[&_li]:hover:text-white dark:[&_li]:hover:text-black [&_li]:hover:bg-dawn-indicator-alt-light dark:[&_li]:hover:bg-dawn-indicator-dark"
    ]
  end

  defp color_variant("bordered", "silver", hoverable) do
    [
      "text-silver-bordered-text-light border-silver-bordered-text-light bg-silver-bordered-bg-light",
      "dark:text-silver-bordered-text-dark dark:border-silver-bordered-text-dark dark:bg-silver-bordered-bg-dark",
      "[&>li:not(:last-child)]:border-silver-bordered-text-light dark:[&>li:not(:last-child)]:border-silver-bordered-text-dark",
      hoverable &&
        "[&_li]:hover:text-white dark:[&_li]:hover:text-black [&_li]:hover:bg-silver-indicator-alt-light dark:[&_li]:hover:bg-silver-indicator-dark"
    ]
  end

  defp color_variant("transparent", "natural", hoverable) do
    [
      "text-natural-light dark:text-natural-dark",
      hoverable &&
        "[&_li]:hover:text-white dark:[&_li]:hover:text-black [&_li]:hover:bg-black dark:[&_li]:hover:bg-white"
    ]
  end

  defp color_variant("transparent", "primary", hoverable) do
    [
      "text-primary-light dark:text-primary-dark",
      hoverable &&
        "[&_li]:hover:text-white dark:[&_li]:hover:text-black [&_li]:hover:bg-primary-indicator-light dark:[&_li]:hover:bg-primary-indicator-dark"
    ]
  end

  defp color_variant("transparent", "secondary", hoverable) do
    [
      "text-secondary-light dark:text-secondary-dark",
      hoverable &&
        "[&_li]:hover:text-white dark:[&_li]:hover:text-black [&_li]:hover:bg-secondary-indicator-light dark:[&_li]:hover:bg-secondary-indicator-dark"
    ]
  end

  defp color_variant("transparent", "success", hoverable) do
    [
      "text-success-light dark:text-success-dark",
      hoverable &&
        "[&_li]:hover:text-white dark:[&_li]:hover:text-black [&_li]:hover:bg-success-indicator-alt-light dark:[&_li]:hover:bg-success-indicator-dark"
    ]
  end

  defp color_variant("transparent", "warning", hoverable) do
    [
      "text-warning-light dark:text-warning-dark",
      hoverable &&
        "[&_li]:hover:text-white dark:[&_li]:hover:text-black [&_li]:hover:bg-warning-indicator-alt-light dark:[&_li]:hover:bg-warning-indicator-dark"
    ]
  end

  defp color_variant("transparent", "danger", hoverable) do
    [
      "text-danger-light dark:text-danger-dark",
      hoverable &&
        "[&_li]:hover:text-white dark:[&_li]:hover:text-black [&_li]:hover:bg-danger-indicator-alt-light dark:[&_li]:hover:bg-danger-indicator-dark"
    ]
  end

  defp color_variant("transparent", "info", hoverable) do
    [
      "text-info-light dark:text-info-dark",
      hoverable &&
        "[&_li]:hover:text-white dark:[&_li]:hover:text-black [&_li]:hover:bg-info-indicator-alt-light dark:[&_li]:hover:bg-info-indicator-dark"
    ]
  end

  defp color_variant("transparent", "misc", hoverable) do
    [
      "text-misc-light dark:text-misc-dark",
      hoverable &&
        "[&_li]:hover:text-white dark:[&_li]:hover:text-black [&_li]:hover:bg-misc-indicator-alt-light dark:[&_li]:hover:bg-misc-indicator-dark"
    ]
  end

  defp color_variant("transparent", "dawn", hoverable) do
    [
      "text-dawn-light dark:text-dawn-dark",
      hoverable &&
        "[&_li]:hover:text-white dark:[&_li]:hover:text-black [&_li]:hover:bg-dawn-indicator-alt-light dark:[&_li]:hover:bg-dawn-indicator-dark"
    ]
  end

  defp color_variant("transparent", "silver", hoverable) do
    [
      "text-silver-light dark:text-silver-dark",
      hoverable &&
        "[&_li]:hover:text-white dark:[&_li]:hover:text-black [&_li]:hover:bg-silver-indicator-alt-light dark:[&_li]:hover:bg-silver-indicator-dark"
    ]
  end

  defp color_variant("gradient", "natural", hoverable) do
    [
      "bg-gradient-to-br from-gradient-natural-from-light to-gradient-natural-to-light text-white",
      "dark:from-gradient-natural-from-dark dark:to-white dark:text-black",
      hoverable && "[&_li]:hover:bg-black dark:[&_li]:hover:bg-white"
    ]
  end

  defp color_variant("gradient", "primary", hoverable) do
    [
      "bg-gradient-to-br from-gradient-primary-from-light to-gradient-primary-to-light text-white",
      "dark:from-gradient-primary-from-dark dark:to-gradient-primary-to-dark dark:text-black",
      hoverable &&
        "[&_li]:hover:bg-primary-indicator-light dark:[&_li]:hover:bg-primary-indicator-dark"
    ]
  end

  defp color_variant("gradient", "secondary", hoverable) do
    [
      "bg-gradient-to-br from-gradient-secondary-from-light to-gradient-secondary-to-light text-white",
      "dark:from-gradient-secondary-from-dark dark:to-gradient-secondary-to-dark dark:text-black",
      hoverable &&
        "[&_li]:hover:bg-secondary-indicator-light dark:[&_li]:hover:bg-secondary-indicator-dark"
    ]
  end

  defp color_variant("gradient", "success", hoverable) do
    [
      "bg-gradient-to-br from-gradient-success-from-light to-gradient-success-to-light text-white",
      "dark:from-gradient-success-from-dark dark:to-gradient-success-to-dark dark:text-black",
      hoverable &&
        "[&_li]:hover:bg-success-indicator-alt-light dark:[&_li]:hover:bg-success-indicator-dark"
    ]
  end

  defp color_variant("gradient", "warning", hoverable) do
    [
      "bg-gradient-to-br from-gradient-warning-from-light to-gradient-warning-to-light text-white",
      "dark:from-gradient-warning-from-dark dark:to-gradient-warning-to-dark dark:text-black",
      hoverable &&
        "[&_li]:hover:bg-warning-indicator-alt-light dark:[&_li]:hover:bg-warning-indicator-dark"
    ]
  end

  defp color_variant("gradient", "danger", hoverable) do
    [
      "bg-gradient-to-br from-gradient-danger-from-light to-gradient-danger-to-light text-white",
      "dark:from-gradient-danger-from-dark dark:to-gradient-danger-to-dark dark:text-black",
      hoverable &&
        "[&_li]:hover:bg-danger-indicator-alt-light dark:[&_li]:hover:bg-danger-indicator-dark"
    ]
  end

  defp color_variant("gradient", "info", hoverable) do
    [
      "bg-gradient-to-br from-gradient-info-from-light to-gradient-info-to-light text-white",
      "dark:from-gradient-info-from-dark dark:to-gradient-info-to-dark dark:text-black",
      hoverable &&
        "[&_li]:hover:bg-info-indicator-alt-light dark:[&_li]:hover:bg-info-indicator-dark"
    ]
  end

  defp color_variant("gradient", "misc", hoverable) do
    [
      "bg-gradient-to-br from-gradient-misc-from-light to-gradient-misc-to-light text-white",
      "dark:from-gradient-misc-from-dark dark:to-gradient-misc-to-dark dark:text-black",
      hoverable &&
        "[&_li]:hover:bg-misc-indicator-alt-light dark:[&_li]:hover:bg-misc-indicator-dark"
    ]
  end

  defp color_variant("gradient", "dawn", hoverable) do
    [
      "bg-gradient-to-br from-gradient-dawn-from-light to-gradient-dawn-to-light text-white",
      "dark:from-gradient-dawn-from-dark dark:to-gradient-dawn-to-dark dark:text-black",
      hoverable &&
        "[&_li]:hover:bg-dawn-indicator-alt-light dark:[&_li]:hover:bg-dawn-indicator-dark"
    ]
  end

  defp color_variant("gradient", "silver", hoverable) do
    [
      "bg-gradient-to-br from-gradient-silver-from-light to-gradient-silver-to-light text-white",
      "dark:from-gradient-silver-from-dark dark:to-gradient-silver-to-dark dark:text-black",
      hoverable &&
        "[&_li]:hover:bg-silver-indicator-alt-light dark:[&_li]:hover:bg-silver-indicator-dark"
    ]
  end

  defp color_variant("bordered_separated", "natural", hoverable) do
    [
      "[&>li]:text-natural-bordered-text-light [&>li]:border-natural-border-light [&>li]:bg-natural-bordered-bg-light",
      "dark:[&>li]:text-natural-bordered-text-dark dark:[&>li]:border-natural-border-dark dark:[&>li]:bg-natural-bordered-bg-dark",
      hoverable &&
        "[&_li]:hover:text-white dark:[&_li]:hover:text-black [&_li]:hover:bg-black dark:[&_li]:hover:bg-white"
    ]
  end

  defp color_variant("bordered_separated", "primary", hoverable) do
    [
      "[&>li]:text-primary-bordered-text-light [&>li]:border-primary-bordered-text-light [&>li]:bg-primary-bordered-bg-light",
      "dark:[&>li]:text-primary-bordered-text-dark dark:[&>li]:border-primary-bordered-text-dark dark:[&>li]:bg-primary-bordered-bg-dark",
      hoverable &&
        "[&_li]:hover:text-white dark:[&_li]:hover:text-black [&_li]:hover:bg-primary-indicator-light dark:[&_li]:hover:bg-primary-indicator-dark"
    ]
  end

  defp color_variant("bordered_separated", "secondary", hoverable) do
    [
      "[&>li]:text-secondary-bordered-text-light [&>li]:border-secondary-bordered-text-light [&>li]:bg-secondary-bordered-bg-light",
      "dark:[&>li]:text-secondary-bordered-text-dark dark:[&>li]:border-secondary-bordered-text-dark dark:[&>li]:bg-secondary-bordered-bg-dark",
      hoverable &&
        "[&_li]:hover:text-white dark:[&_li]:hover:text-black [&_li]:hover:bg-secondary-indicator-light dark:[&_li]:hover:bg-secondary-indicator-dark"
    ]
  end

  defp color_variant("bordered_separated", "success", hoverable) do
    [
      "[&>li]:text-success-bordered-text-light [&>li]:border-success-bordered-text-light [&>li]:bg-success-bordered-bg-light",
      "dark:[&>li]:text-success-bordered-text-dark dark:[&>li]:border-success-bordered-text-dark dark:[&>li]:bg-success-bordered-bg-dark",
      hoverable &&
        "[&_li]:hover:text-white dark:[&_li]:hover:text-black [&_li]:hover:bg-success-indicator-alt-light dark:[&_li]:hover:bg-success-indicator-dark"
    ]
  end

  defp color_variant("bordered_separated", "warning", hoverable) do
    [
      "[&>li]:text-warning-bordered-text-light [&>li]:border-warning-bordered-text-light [&>li]:bg-warning-bordered-bg-light",
      "dark:[&>li]:text-warning-bordered-text-dark dark:[&>li]:border-warning-bordered-text-dark dark:[&>li]:bg-warning-bordered-bg-dark",
      hoverable &&
        "[&_li]:hover:text-white dark:[&_li]:hover:text-black [&_li]:hover:bg-warning-indicator-alt-light dark:[&_li]:hover:bg-warning-indicator-dark"
    ]
  end

  defp color_variant("bordered_separated", "danger", hoverable) do
    [
      "[&>li]:text-danger-bordered-text-light [&>li]:border-danger-bordered-text-light [&>li]:bg-danger-bordered-bg-light",
      "dark:[&>li]:text-danger-bordered-text-dark dark:[&>li]:border-danger-bordered-text-dark dark:[&>li]:bg-danger-bordered-bg-dark",
      hoverable &&
        "[&_li]:hover:text-white dark:[&_li]:hover:text-black [&_li]:hover:bg-danger-indicator-alt-light dark:[&_li]:hover:bg-danger-indicator-dark"
    ]
  end

  defp color_variant("bordered_separated", "info", hoverable) do
    [
      "[&>li]:text-info-bordered-text-light [&>li]:border-info-bordered-text-light [&>li]:bg-info-bordered-bg-light",
      "dark:[&>li]:text-info-bordered-text-dark dark:[&>li]:border-info-bordered-text-dark dark:[&>li]:bg-info-bordered-bg-dark",
      hoverable &&
        "[&_li]:hover:text-white dark:[&_li]:hover:text-black [&_li]:hover:bg-info-indicator-alt-light dark:[&_li]:hover:bg-info-indicator-dark"
    ]
  end

  defp color_variant("bordered_separated", "misc", hoverable) do
    [
      "[&>li]:text-misc-bordered-text-light [&>li]:border-misc-bordered-text-light [&>li]:bg-misc-bordered-bg-light",
      "dark:[&>li]:text-misc-bordered-text-dark dark:[&>li]:border-misc-bordered-text-dark dark:[&>li]:bg-misc-bordered-bg-dark",
      hoverable &&
        "[&_li]:hover:text-white dark:[&_li]:hover:text-black [&_li]:hover:bg-misc-indicator-alt-light dark:[&_li]:hover:bg-misc-indicator-dark"
    ]
  end

  defp color_variant("bordered_separated", "dawn", hoverable) do
    [
      "[&>li]:text-dawn-bordered-text-light [&>li]:border-dawn-bordered-text-light [&>li]:bg-dawn-bordered-bg-light",
      "dark:[&>li]:text-dawn-bordered-text-dark dark:[&>li]:border-dawn-bordered-text-dark dark:[&>li]:bg-dawn-bordered-bg-dark",
      hoverable &&
        "[&_li]:hover:text-white dark:[&_li]:hover:text-black [&_li]:hover:bg-dawn-indicator-alt-light dark:[&_li]:hover:bg-dawn-indicator-dark"
    ]
  end

  defp color_variant("bordered_separated", "silver", hoverable) do
    [
      "[&>li]:text-silver-bordered-text-light [&>li]:border-silver-bordered-text-light [&>li]:bg-silver-bordered-bg-light",
      "dark:[&>li]:text-silver-bordered-text-dark dark:[&>li]:border-silver-bordered-text-dark dark:[&>li]:bg-silver-bordered-bg-dark",
      hoverable &&
        "[&_li]:hover:text-white dark:[&_li]:hover:text-black [&_li]:hover:bg-silver-indicator-alt-light dark:[&_li]:hover:bg-silver-indicator-dark"
    ]
  end

  defp color_variant("outline_separated", "natural", hoverable) do
    [
      "[&>li]:text-natural-light [&>li]:border-natural-light dark:[&>li]:text-natural-dark dark:[&>li]:border-natural-dark",
      hoverable &&
        "[&_li]:hover:text-white dark:[&_li]:hover:text-black [&_li]:hover:bg-black dark:[&_li]:hover:bg-white"
    ]
  end

  defp color_variant("outline_separated", "primary", hoverable) do
    [
      "[&>li]:text-primary-light [&>li]:border-primary-light dark:[&>li]:text-primary-dark dark:[&>li]:border-primary-dark",
      hoverable &&
        "[&_li]:hover:text-white dark:[&_li]:hover:text-black [&_li]:hover:bg-primary-indicator-light dark:[&_li]:hover:bg-primary-indicator-dark"
    ]
  end

  defp color_variant("outline_separated", "secondary", hoverable) do
    [
      "[&>li]:text-secondary-light [&>li]:border-secondary-light dark:[&>li]:text-secondary-dark dark:[&>li]:border-secondary-dark",
      hoverable &&
        "[&_li]:hover:text-white dark:[&_li]:hover:text-black [&_li]:hover:bg-secondary-indicator-light dark:[&_li]:hover:bg-secondary-indicator-dark"
    ]
  end

  defp color_variant("outline_separated", "success", hoverable) do
    [
      "[&>li]:text-success-light [&>li]:border-success-light dark:[&>li]:text-success-dark dark:[&>li]:border-success-dark",
      hoverable &&
        "[&_li]:hover:text-white dark:[&_li]:hover:text-black [&_li]:hover:bg-success-indicator-alt-light dark:[&_li]:hover:bg-success-indicator-dark"
    ]
  end

  defp color_variant("outline_separated", "warning", hoverable) do
    [
      "[&>li]:text-warning-light [&>li]:border-warning-light dark:[&>li]:text-warning-dark dark:[&>li]:border-warning-dark",
      hoverable &&
        "[&_li]:hover:text-white dark:[&_li]:hover:text-black [&_li]:hover:bg-warning-indicator-alt-light dark:[&_li]:hover:bg-warning-indicator-dark"
    ]
  end

  defp color_variant("outline_separated", "danger", hoverable) do
    [
      "[&>li]:text-danger-light [&>li]:border-danger-light dark:[&>li]:text-danger-dark dark:[&>li]:border-danger-dark",
      hoverable &&
        "[&_li]:hover:text-white dark:[&_li]:hover:text-black [&_li]:hover:bg-danger-indicator-alt-light dark:[&_li]:hover:bg-danger-indicator-dark"
    ]
  end

  defp color_variant("outline_separated", "info", hoverable) do
    [
      "[&>li]:text-info-light [&>li]:border-info-light dark:[&>li]:text-info-dark dark:[&>li]:border-info-dark",
      hoverable &&
        "[&_li]:hover:text-white dark:[&_li]:hover:text-black [&_li]:hover:bg-info-indicator-alt-light dark:[&_li]:hover:bg-info-indicator-dark"
    ]
  end

  defp color_variant("outline_separated", "misc", hoverable) do
    [
      "[&>li]:text-misc-light [&>li]:border-misc-light dark:[&>li]:text-misc-dark dark:[&>li]:border-misc-dark",
      hoverable &&
        "[&_li]:hover:text-white dark:[&_li]:hover:text-black [&_li]:hover:bg-misc-indicator-alt-light dark:[&_li]:hover:bg-misc-indicator-dark"
    ]
  end

  defp color_variant("outline_separated", "dawn", hoverable) do
    [
      "[&>li]:text-dawn-light [&>li]:border-dawn-light dark:[&>li]:text-dawn-dark dark:[&>li]:border-dawn-dark",
      hoverable &&
        "[&_li]:hover:text-white dark:[&_li]:hover:text-black [&_li]:hover:bg-dawn-indicator-alt-light dark:[&_li]:hover:bg-dawn-indicator-dark"
    ]
  end

  defp color_variant("outline_separated", "silver", hoverable) do
    [
      "[&>li]:text-silver-light [&>li]:border-silver-light dark:[&>li]:text-silver-dark dark:[&>li]:border-silver-dark",
      hoverable &&
        "[&_li]:hover:text-white dark:[&_li]:hover:text-black [&_li]:hover:bg-silver-indicator-alt-light dark:[&_li]:hover:bg-silver-indicator-dark"
    ]
  end

  defp color_variant(params, _, _) when is_binary(params), do: params
end
