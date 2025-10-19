defmodule RadiatorWeb.Components.Divider do
  @moduledoc """
  The `RadiatorWeb.Components.Divider` module provides a versatile and customizable divider
  component for creating horizontal and vertical dividers with various styling options
  in a Phoenix LiveView application.

  ## Features:
  - Supports different divider types: `solid`, `dashed`, and `dotted`.
  - Flexible color themes with predefined options such as `primary`, `secondary`,
  `success`, `danger`, and more.
  - Allows for horizontal and vertical orientation.
  - Customizable size, width, height, and margin for precise control over the appearance.
  - Includes slots for adding text or icons with individual styling and positioning options.
  - Global attributes and custom CSS classes can be applied for additional customization.

  **Documentation:** https://mishka.tools/chelekom/docs/divider
  """
  use Phoenix.Component
  import RadiatorWeb.Components.Icon, only: [icon: 1]

  @doc """
  The `divider` component is used to visually separate content with either a horizontal or
  vertical line. It supports different line styles (like dashed, dotted, or solid) and can
  be customized with various attributes like `size`, `width`, `height`, and `color`.

  ### Examples

  ```elixir
  <.divider type="dashed" position="right" size="small" color="primary">
    <:text>Or</:text>
  </.divider>

  <.divider type="dotted" size="extra_large">
    <:icon name="hero-circle-stack" class="p-10 bg-white text-yellow-600" />
  </.divider>
  ```

  This component is ideal for creating visual separations in your layout, whether it’s for breaking
  up text, sections, or other elements in your design.
  """
  @doc type: :component
  attr :id, :string,
    default: nil,
    doc: "A unique identifier is used to manage state and interaction"

  attr :type, :string,
    values: ["dashed", "dotted", "solid"],
    default: "solid",
    doc: "Determines type of element"

  attr :color, :string, default: "base", doc: "Determines color theme"

  attr :size, :string,
    default: "extra_small",
    doc:
      "Determines the overall size of the elements, including padding, font size, and other items"

  attr :width, :string, default: "full", doc: "Determines the element width"
  attr :height, :string, default: "auto", doc: "Determines the element width"
  attr :margin, :string, default: "none", doc: "Determines the element margin"
  attr :position, :string, default: "middle", doc: "Determines the text and icons position"

  attr :variation, :string,
    values: ["horizontal", "vertical"],
    default: "horizontal",
    doc: "Defines the layout orientation of the component"

  slot :text, required: false do
    attr :class, :string, doc: "Custom CSS class for additional styling"
    attr :color, :string, doc: "Determines color theme"

    attr :size, :string,
      doc:
        "Determines the overall size of the elements, including padding, font size, and other items"
  end

  slot :icon, required: false do
    attr :name, :string, required: true, doc: "Specifies the name of the element"
    attr :class, :string, doc: "Custom CSS class for additional styling"
    attr :icon_class, :string, doc: "Determines custom class for the icon"
    attr :color, :string, doc: "Determines color theme"

    attr :size, :string,
      doc:
        "Determines the overall size of the elements, including padding, font size, and other items"
  end

  attr :class, :string, default: nil, doc: "Custom CSS class for additional styling"

  attr :rest, :global,
    doc:
      "Global attributes can define defaults which are merged with attributes provided by the caller"

  def divider(%{variation: "vertical"} = assigns) do
    ~H"""
    <div
      id={@id}
      role="separator"
      aria-orientation="vertical"
      class={[
        color_class(@color, @position),
        height_class(@height),
        border_type_class(@type, :vertical, ""),
        size_class(@size, :vertical, @position),
        margin_class(@margin, :vertical),
        @class
      ]}
      {@rest}
    >
      <div
        :for={text <- @text}
        aria-hidden="true"
        class={[
          "divider-content whitespace-nowrap",
          text[:color],
          text[:class] || "bg-transparent",
          text_position(:divider, @position),
          text[:size]
        ]}
      >
        {render_slot(text)}
      </div>
    </div>
    """
  end

  def divider(assigns) do
    ~H"""
    <div
      id={@id}
      role="separator"
      aria-orientation="horizontal"
      class={[
        default_classes(@position),
        color_class(@color, @position),
        width_class(@width),
        border_type_class(@type, :horizontal, @position),
        size_class(@size, :horizontal, @position),
        margin_class(@margin, :horizontal),
        @class
      ]}
      {@rest}
    >
      <div
        :for={icon <- @icon}
        aria-hidden="true"
        class={[
          "divider-content whitespace-nowrap",
          icon[:size],
          icon[:color],
          icon[:class] || "bg-transparent",
          text_position(:divider, @position)
        ]}
      >
        <.icon name={icon[:name]} class={icon[:icon_class] || size_class(@size, :icon, "")} />
      </div>

      <div
        :for={text <- @text}
        aria-hidden="true"
        class={[
          "divider-content whitespace-nowrap",
          text[:color],
          text[:class] || "bg-transparent",
          text_position(:divider, @position),
          text[:size]
        ]}
      >
        {render_slot(text)}
      </div>
    </div>
    """
  end

  @doc """
  `RadiatorWeb.Components.Divider.hr` is used to create a horizontal divider with customizable style, color,
  and size options.

  It can also include text or icons to enhance visual separation between content sections.

  ## Examples

  ```elixir
  <.hr type="dashed" color="primary" />
  <.hr type="dotted" size="large" />
  <.hr><:text>Or</:text></.hr>
  <.hr color="dawn"><:icon name="hero-circle-stack" /></.hr>
  <.hr type="dashed" size="small"><:text>Or</:text></.hr>
  ```
  """
  @doc type: :component
  attr :id, :string,
    default: nil,
    doc: "A unique identifier is used to manage state and interaction"

  attr :type, :string,
    values: ["dashed", "dotted", "solid"],
    default: "solid",
    doc: "Specifies the type of the element"

  attr :color, :string, default: "base", doc: "Determines color theme"

  attr :size, :string,
    default: "extra_small",
    doc:
      "Determines the overall size of the elements, including padding, font size, and other items"

  attr :width, :string, default: "full", doc: "Determines the element width"
  attr :margin, :string, default: "none", doc: "Determines the element margin"
  attr :position, :string, default: "middle", doc: "Determines the text and icons position"

  slot :text, required: false do
    attr :class, :string, doc: "Custom CSS class for additional styling"
    attr :color, :string, doc: "Determines color theme"

    attr :size, :string,
      doc:
        "Determines the overall size of the elements, including padding, font size, and other items"
  end

  slot :icon, required: false do
    attr :name, :string, required: true, doc: "Specifies the name of the element"
    attr :class, :string, doc: "Custom CSS class for additional styling"
    attr :icon_class, :string, doc: "Determines custom class for the icon"
    attr :color, :string, doc: "Determines color theme"

    attr :size, :string,
      doc:
        "Determines the overall size of the elements, including padding, font size, and other items"
  end

  attr :class, :string, default: nil, doc: "Custom CSS class for additional styling"

  attr :rest, :global,
    doc:
      "Global attributes can define defaults which are merged with attributes provided by the caller"

  def hr(assigns) do
    ~H"""
    <div class="relative">
      <hr
        id={@id}
        role="separator"
        aria-orientation="horizontal"
        class={[
          "mx-auto",
          color_class(@color, @position),
          width_class(@width),
          border_type_class(@type, :horizontal, @position),
          size_class(@size, :horizontal, @position),
          margin_class(@margin, :horizontal),
          @class
        ]}
        {@rest}
      />
      <div
        :for={icon <- @icon}
        class={[
          "flex items-center justify-center absolute p-2",
          "-translate-x-1/2 whitespace-nowrap",
          icon[:size] || size_class(@size, :icon, ""),
          icon[:color] || color_class(@color, @position),
          text_position(:hr, @position),
          icon[:class] || "bg-white"
        ]}
      >
        <.icon name={icon[:name]} class={icon[:icon_class] || ""} />
      </div>

      <div
        :for={text <- @text}
        class={[
          "flex items-center justify-center absolute p-2",
          "-translate-x-1/2 whitespace-nowrap",
          text[:color] || color_class(@color, @position),
          text[:class] || "bg-white",
          text_position(:hr, @position),
          text[:size]
        ]}
      >
        {render_slot(text)}
      </div>
    </div>
    """
  end

  defp size_class("extra_small", :horizontal, position) do
    [
      "[&:not(:has(.divider-content))]:border-t text-xs my-2",
      position == "left" && "has-[.divider-content.divider-left]:after:border-t",
      position == "middle" &&
        "has-[.divider-content.divider-middle]:before:border-t has-[.divider-content.divider-middle]:after:border-t",
      position == "right" && "has-[.divider-content.divider-right]:before:border-t"
    ]
  end

  defp size_class("small", :horizontal, position) do
    [
      "[&:not(:has(.divider-content))]:border-t-2 text-[13px] my-3",
      position == "left" && "has-[.divider-content.divider-left]:after:border-t-2",
      position == "middle" &&
        "has-[.divider-content.divider-middle]:before:border-t-2 has-[.divider-content.divider-middle]:after:border-t-2",
      position == "right" && "has-[.divider-content.divider-right]:before:border-t-2"
    ]
  end

  defp size_class("medium", :horizontal, position) do
    [
      "[&:not(:has(.divider-content))]:border-t-[3px] text-[14px] my-4",
      position == "left" && "has-[.divider-content.divider-left]:after:border-t-[3px]",
      position == "middle" &&
        "has-[.divider-content.divider-middle]:before:border-t-[3px] has-[.divider-content.divider-middle]:after:border-t-[3px]",
      position == "right" && "has-[.divider-content.divider-right]:before:border-t-[3px]"
    ]
  end

  defp size_class("large", :horizontal, position) do
    [
      "[&:not(:has(.divider-content))]:border-t-4 text-[16px] my-5",
      position == "left" && "has-[.divider-content.divider-left]:after:border-t-4",
      position == "middle" &&
        "has-[.divider-content.divider-middle]:before:border-t-4 has-[.divider-content.divider-middle]:after:border-t-4",
      position == "right" && "has-[.divider-content.divider-right]:before:border-t-4"
    ]
  end

  defp size_class("extra_large", :horizontal, position) do
    [
      "[&:not(:has(.divider-content))]:border-t-[5px] text-[17px] my-6",
      position == "left" && "has-[.divider-content.divider-left]:after:border-t-[5px]",
      position == "middle" &&
        "has-[.divider-content.divider-middle]:before:border-t-[5px] has-[.divider-content.divider-middle]:after:border-t-[5px]",
      position == "right" && "has-[.divider-content.divider-right]:before:border-t-[5px]"
    ]
  end

  defp size_class("extra_small", :vertical, _),
    do: "[&:not(:has(.divider-content))]:border-l text-[13px]"

  defp size_class("small", :vertical, _),
    do: "[&:not(:has(.divider-content))]:border-l-2 text-[14px]"

  defp size_class("medium", :vertical, _),
    do: "[&:not(:has(.divider-content))]:border-l-[3px] text-[15px]"

  defp size_class("large", :vertical, _),
    do: "[&:not(:has(.divider-content))]:border-l-4 text-[16px]"

  defp size_class("extra_large", :vertical, _),
    do: "[&:not(:has(.divider-content))]:border-l-[5px] text-[17px]"

  defp size_class("extra_small", :icon, _), do: "[&>*]:size-5"

  defp size_class("small", :icon, _), do: "[&>*]:size-6"

  defp size_class("medium", :icon, _), do: "[&>*]:size-7"

  defp size_class("large", :icon, _), do: "[&>*]:size-8"

  defp size_class("extra_large", :icon, _), do: "[&>*]:size-9"

  defp size_class(params, _, _) when is_binary(params), do: params

  defp width_class("full"), do: "w-full"

  defp width_class("half"), do: "w-1/2"

  defp width_class(params) when is_binary(params), do: params

  defp height_class("full"), do: "h-screen"

  defp height_class("auto"), do: "h-auto"

  defp height_class("half"), do: "h-1/2"

  defp height_class(params) when is_binary(params), do: params

  defp margin_class("extra_small", :horizontal) do
    ["my-2"]
  end

  defp margin_class("small", :horizontal) do
    ["my-3"]
  end

  defp margin_class("medium", :horizontal) do
    ["my-4"]
  end

  defp margin_class("large", :horizontal) do
    ["my-5"]
  end

  defp margin_class("extra_large", :horizontal) do
    ["my-6"]
  end

  defp margin_class("none", :horizontal) do
    ["my-0"]
  end

  defp margin_class("extra_small", :vertical) do
    ["mx-2"]
  end

  defp margin_class("small", :vertical) do
    ["mx-3"]
  end

  defp margin_class("medium", :vertical) do
    ["mx-4"]
  end

  defp margin_class("large", :vertical) do
    ["mx-5"]
  end

  defp margin_class("extra_large", :vertical) do
    ["mx-6"]
  end

  defp margin_class("none", :vertical) do
    ["mx-0"]
  end

  defp margin_class(params, _) when is_binary(params), do: params

  defp color_class("base", position) do
    [
      "text-base-text-light border-base-border-light dark:text-base-text-dark dark:border-base-border-dark",
      position == "right" &&
        "has-[.divider-content.divider-right]:before:border-base-border-light dark:has-[.divider-content.divider-right]:before:border-base-border-dark",
      position == "left" &&
        "has-[.divider-content.divider-left]:after:border-base-border-light dark:has-[.divider-content.divider-left]:after:border-base-border-dark",
      position == "middle" &&
        "has-[.divider-content.divider-middle]:before:border-base-border-light has-[.divider-content.divider-middle]:after:border-base-border-light dark:has-[.divider-content.divider-middle]:before:border-base-border-dark dark:has-[.divider-content.divider-middle]:after:border-base-border-dark"
    ]
  end

  defp color_class("white", position) do
    [
      "text-white border-white",
      position == "right" &&
        "has-[.divider-content.divider-right]:before:border-white dark:has-[.divider-content.divider-right]:before:border-white",
      position == "left" &&
        "has-[.divider-content.divider-left]:after:border-white dark:has-[.divider-content.divider-left]:after:border-white",
      position == "middle" &&
        "has-[.divider-content.divider-middle]:before:border-white has-[.divider-content.divider-middle]:after:border-white dark:has-[.divider-content.divider-middle]:before:border-white dark:has-[.divider-content.divider-middle]:after:border-white"
    ]
  end

  defp color_class("dark", position) do
    [
      "text-default-dark-bg border-default-dark-bg",
      position == "right" &&
        "has-[.divider-content.divider-right]:before:border-default-dark-bg dark:has-[.divider-content.divider-right]:before:border-default-dark-bg",
      position == "left" &&
        "has-[.divider-content.divider-left]:after:border-default-dark-bg dark:has-[.divider-content.divider-left]:after:border-default-dark-bg",
      position == "middle" &&
        "has-[.divider-content.divider-middle]:before:border-default-dark-bg has-[.divider-content.divider-middle]:after:border-default-dark-bg dark:has-[.divider-content.divider-middle]:before:border-default-dark-bg dark:has-[.divider-content.divider-middle]:after:border-default-dark-bg"
    ]
  end

  defp color_class("natural", position) do
    [
      "text-natural-light border-natural-light dark:text-natural-dark dark:border-natural-dark",
      position == "right" &&
        "has-[.divider-content.divider-right]:before:border-natural-light dark:has-[.divider-content.divider-right]:before:border-natural-dark",
      position == "left" &&
        "has-[.divider-content.divider-left]:after:border-natural-light dark:has-[.divider-content.divider-left]:after:border-natural-dark",
      position == "middle" &&
        "has-[.divider-content.divider-middle]:before:border-natural-light has-[.divider-content.divider-middle]:after:border-natural-light dark:has-[.divider-content.divider-middle]:before:border-natural-dark dark:has-[.divider-content.divider-middle]:after:border-natural-dark"
    ]
  end

  defp color_class("primary", position) do
    [
      "text-primary-light border-primary-light dark:text-primary-dark dark:border-primary-dark",
      position == "right" &&
        "has-[.divider-content.divider-right]:before:border-primary-light dark:has-[.divider-content.divider-right]:before:border-primary-dark",
      position == "left" &&
        "has-[.divider-content.divider-left]:after:border-primary-light dark:has-[.divider-content.divider-left]:after:border-primary-dark",
      position == "middle" &&
        "has-[.divider-content.divider-middle]:before:border-primary-light has-[.divider-content.divider-middle]:after:border-primary-light dark:has-[.divider-content.divider-middle]:before:border-primary-dark dark:has-[.divider-content.divider-middle]:after:border-primary-dark"
    ]
  end

  defp color_class("secondary", position) do
    [
      "text-secondary-light border-secondary-light dark:text-secondary-dark dark:border-secondary-dark",
      position == "right" &&
        "has-[.divider-content.divider-right]:before:border-secondary-light dark:has-[.divider-content.divider-right]:before:border-secondary-dark",
      position == "left" &&
        "has-[.divider-content.divider-left]:after:border-secondary-light dark:has-[.divider-content.divider-left]:after:border-secondary-dark",
      position == "middle" &&
        "has-[.divider-content.divider-middle]:before:border-secondary-light has-[.divider-content.divider-middle]:after:border-secondary-light dark:has-[.divider-content.divider-middle]:before:border-secondary-dark dark:has-[.divider-content.divider-middle]:after:border-secondary-dark"
    ]
  end

  defp color_class("success", position) do
    [
      "text-success-light border-success-light dark:text-success-dark dark:border-success-dark",
      position == "right" &&
        "has-[.divider-content.divider-right]:before:border-success-light dark:has-[.divider-content.divider-right]:before:border-success-dark",
      position == "left" &&
        "has-[.divider-content.divider-left]:after:border-success-light dark:has-[.divider-content.divider-left]:after:border-success-dark",
      position == "middle" &&
        "has-[.divider-content.divider-middle]:before:border-success-light has-[.divider-content.divider-middle]:after:border-success-light dark:has-[.divider-content.divider-middle]:before:border-success-dark dark:has-[.divider-content.divider-middle]:after:border-success-dark"
    ]
  end

  defp color_class("warning", position) do
    [
      "text-warning-light border-warning-light dark:text-warning-dark dark:border-warning-dark",
      position == "right" &&
        "has-[.divider-content.divider-right]:before:border-warning-light dark:has-[.divider-content.divider-right]:before:border-warning-dark",
      position == "left" &&
        "has-[.divider-content.divider-left]:after:border-warning-light dark:has-[.divider-content.divider-left]:after:border-warning-dark",
      position == "middle" &&
        "has-[.divider-content.divider-middle]:before:border-warning-light has-[.divider-content.divider-middle]:after:border-warning-light dark:has-[.divider-content.divider-middle]:before:border-warning-dark dark:has-[.divider-content.divider-middle]:after:border-warning-dark"
    ]
  end

  defp color_class("danger", position) do
    [
      "text-danger-light border-danger-light dark:text-danger-dark dark:border-danger-dark",
      position == "right" &&
        "has-[.divider-content.divider-right]:before:border-danger-light dark:has-[.divider-content.divider-right]:before:border-danger-dark",
      position == "left" &&
        "has-[.divider-content.divider-left]:after:border-danger-light dark:has-[.divider-content.divider-left]:after:border-danger-dark",
      position == "middle" &&
        "has-[.divider-content.divider-middle]:before:border-danger-light has-[.divider-content.divider-middle]:after:border-danger-light dark:has-[.divider-content.divider-middle]:before:border-danger-dark dark:has-[.divider-content.divider-middle]:after:border-danger-dark"
    ]
  end

  defp color_class("info", position) do
    [
      "text-info-light border-info-light dark:text-info-dark dark:border-info-dark",
      position == "right" &&
        "has-[.divider-content.divider-right]:before:border-info-light dark:has-[.divider-content.divider-right]:before:border-info-dark",
      position == "left" &&
        "has-[.divider-content.divider-left]:after:border-info-light dark:has-[.divider-content.divider-left]:after:border-info-dark",
      position == "middle" &&
        "has-[.divider-content.divider-middle]:before:border-info-light has-[.divider-content.divider-middle]:after:border-info-light dark:has-[.divider-content.divider-middle]:before:border-info-dark dark:has-[.divider-content.divider-middle]:after:border-info-dark"
    ]
  end

  defp color_class("misc", position) do
    [
      "text-misc-light border-misc-light dark:text-misc-dark dark:border-misc-dark",
      position == "right" &&
        "has-[.divider-content.divider-right]:before:border-misc-light dark:has-[.divider-content.divider-right]:before:border-misc-dark",
      position == "left" &&
        "has-[.divider-content.divider-left]:after:border-misc-light dark:has-[.divider-content.divider-left]:after:border-misc-dark",
      position == "middle" &&
        "has-[.divider-content.divider-middle]:before:border-misc-light has-[.divider-content.divider-middle]:after:border-misc-light dark:has-[.divider-content.divider-middle]:before:border-misc-dark dark:has-[.divider-content.divider-middle]:after:border-misc-dark"
    ]
  end

  defp color_class("dawn", position) do
    [
      "text-dawn-light border-dawn-light dark:text-dawn-dark dark:border-dawn-dark",
      position == "right" &&
        "has-[.divider-content.divider-right]:before:border-dawn-light dark:has-[.divider-content.divider-right]:before:border-dawn-dark",
      position == "left" &&
        "has-[.divider-content.divider-left]:after:border-dawn-light dark:has-[.divider-content.divider-left]:after:border-dawn-dark",
      position == "middle" &&
        "has-[.divider-content.divider-middle]:before:border-dawn-light has-[.divider-content.divider-middle]:after:border-dawn-light dark:has-[.divider-content.divider-middle]:before:border-dawn-dark dark:has-[.divider-content.divider-middle]:after:border-dawn-dark"
    ]
  end

  defp color_class("silver", position) do
    [
      "text-silver-light border-silver-light dark:text-silver-dark dark:border-silver-dark",
      position == "right" &&
        "has-[.divider-content.divider-right]:before:border-silver-light dark:has-[.divider-content.divider-right]:before:border-silver-dark",
      position == "left" &&
        "has-[.divider-content.divider-left]:after:border-silver-light dark:has-[.divider-content.divider-left]:after:border-silver-dark",
      position == "middle" &&
        "has-[.divider-content.divider-middle]:before:border-silver-light has-[.divider-content.divider-middle]:after:border-silver-light dark:has-[.divider-content.divider-middle]:before:border-silver-dark dark:has-[.divider-content.divider-middle]:after:border-silver-dark"
    ]
  end

  defp border_type_class("dashed", :horizontal, position) do
    [
      "border-dashed",
      position == "middle" &&
        "has-[.divider-content.divider-middle]:before:border-dashed has-[.divider-content.divider-middle]:after:border-dashed",
      position == "right" && "has-[.divider-content.divider-right]:before:border-dashed",
      position == "left" && "has-[.divider-content.divider-left]:after:border-dashed"
    ]
  end

  defp border_type_class("dotted", :horizontal, position) do
    [
      "border-dotted",
      position == "middle" &&
        "has-[.divider-content.divider-middle]:before:border-dotted has-[.divider-content.divider-middle]:after:border-dotted",
      position == "right" && "has-[.divider-content.divider-right]:before:border-dotted",
      position == "left" && "has-[.divider-content.divider-left]:after:border-dotted"
    ]
  end

  defp border_type_class("solid", :horizontal, position) do
    [
      "border-solid",
      position == "middle" &&
        "has-[.divider-content.divider-middle]:before:border-solid has-[.divider-content.divider-middle]:after:border-solid",
      position == "right" && "has-[.divider-content.divider-right]:before:border-solid",
      position == "left" && "has-[.divider-content.divider-left]:after:border-solid"
    ]
  end

  defp border_type_class("dashed", :vertical, _), do: "border-dashed"

  defp border_type_class("dotted", :vertical, _), do: "border-dotted"

  defp border_type_class("solid", :vertical, _), do: "border-solid"

  defp text_position(:hr, "right") do
    "-top-1/2 -translate-y-1/2 -right-5"
  end

  defp text_position(:hr, "left") do
    "-top-1/2 -translate-y-1/2 left-0"
  end

  defp text_position(:hr, "middle") do
    "-top-1/2 -translate-y-1/2 left-1/2"
  end

  defp text_position(:divider, "right") do
    "divider-right"
  end

  defp text_position(:divider, "left") do
    "divider-left"
  end

  defp text_position(:divider, "middle") do
    "divider-middle"
  end

  defp default_classes(position) do
    base_classes = [
      "mx-auto",
      "has-[.divider-content]:flex",
      "has-[.divider-content]:items-center",
      "has-[.divider-content]:gap-2"
    ]

    position_classes = position_classes(position)

    base_classes ++ position_classes
  end

  defp position_classes("middle"),
    do: [
      "has-[.divider-content.divider-middle]:before:content-['']",
      "has-[.divider-content.divider-middle]:before:block",
      "has-[.divider-content.divider-middle]:before:w-full",
      "has-[.divider-content.divider-middle]:after:content-['']",
      "has-[.divider-content.divider-middle]:after:block",
      "has-[.divider-content.divider-middle]:after:w-full"
    ]

  defp position_classes("right"),
    do: [
      "has-[.divider-content.divider-right]:before:content-['']",
      "has-[.divider-content.divider-right]:before:block",
      "has-[.divider-content.divider-right]:before:w-full"
    ]

  defp position_classes("left"),
    do: [
      "has-[.divider-content.divider-left]:after:content-['']",
      "has-[.divider-content.divider-left]:after:block",
      "has-[.divider-content.divider-left]:after:w-full"
    ]

  defp position_classes(_), do: []
end
