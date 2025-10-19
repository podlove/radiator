defmodule RadiatorWeb.Components.TableContent do
  @moduledoc """
  `RadiatorWeb.Components.TableContent` is a component module designed to create flexible and dynamic
  content within a table. This module allows for a variety of customizations, including styles,
  colors, borders, padding, and animations. It is composed of several subcomponents such as
  `table_content/1`, `content_wrapper/1`, and `content_item/1`, each providing specific
  roles for content display and interaction.

  The `table_content/1` function creates a container with customizable styles and an optional title.
  `content_wrapper/1` and `content_item/1` allow further structuring of content, including icons,
  font weights, and active states, making it easy to build interactive and visually appealing
  layouts within tables. The module leverages slots to enable dynamic content rendering,
  offering high flexibility in the design of complex table layouts.

  **Documentation:** https://mishka.tools/chelekom/docs/table-content
  """

  use Phoenix.Component
  alias Phoenix.LiveView.JS
  import RadiatorWeb.Components.Icon, only: [icon: 1]

  @doc """
  The `table_content` component is used to display organized content with customizable styling
  options such as color, padding, and animation.

  It supports nested content items and wrappers for better content management and display.

  ## Examples

  ```elixir
  <.table_content color="primary" animated>
    <.content_item icon="hero-hashtag">
      <.link href="#prag">Content 1</.link>
    </.content_item>

    <.content_item icon="hero-hashtag">
      <.link href="#home">Content 2</.link>
    </.content_item>

    <.content_item title="Wrapper Content">
      <.content_wrapper>
        <.content_item icon="hero-hashtag">
          <.link href="#home">Content 1</.link>
        </.content_item>

        <.content_item icon="hero-hashtag">
          <.link href="#home">Content 2</.link>
        </.content_item>

        <.content_item icon="hero-hashtag" active>
          <.link href="#home">Content 3</.link>
        </.content_item>
      </.content_wrapper>
    </.content_item>
  </.table_content>
  ```
  """
  @doc type: :component
  attr :id, :string,
    default: nil,
    doc: "A unique identifier is used to manage state and interaction"

  attr :class, :string, default: nil, doc: "Custom CSS class for additional styling"

  attr :title_class, :string,
    default: nil,
    doc: "Custom CSS class for additional styling to title"

  attr :title, :string, default: nil, doc: "Specifies the title of the element"
  attr :color, :string, default: "natural", doc: "Determines color theme"
  attr :variant, :string, default: "base", doc: "Determines the style"
  attr :space, :string, default: "", doc: "Space between items"
  attr :animated, :boolean, default: false, doc: "Determines whether element's icon has animation"
  attr :padding, :string, default: "", doc: "Determines padding for items"
  attr :rounded, :string, default: "", doc: "Determines the border radius"
  attr :border, :string, default: "extra_small", doc: "Determines border style"

  attr :size, :string,
    default: "small",
    doc:
      "Determines the overall size of the elements, including padding, font size, and other items"

  attr :rest, :global,
    doc:
      "Global attributes can define defaults which are merged with attributes provided by the caller"

  slot :inner_block, required: false, doc: "Inner block that renders HEEx content"

  slot :item, required: false do
    attr :class, :string, doc: "Custom CSS class for additional styling"
    attr :title, :string, doc: "Specifies the title of the element"
    attr :icon, :string, doc: "Icon displayed alongside of an item"
    attr :icon_class, :string, doc: "Determines custom class for the icon"
    attr :font_weight, :string, doc: "Determines custom class for the font weight"
    attr :link_title, :string, doc: "Determines link"
    attr :link, :string, doc: "Determines link path"
    attr :active, :boolean, doc: "Indicates whether the element is currently active and visible"
    attr :title_class, :string, doc: "Custom CSS class for additional styling to title"

    attr :wrapper_class, :string,
      doc: "Custom CSS class for additional styling to content wrapper"

    attr :link_class, :string, doc: "Custom CSS class for additional styling to link"
    attr :content_class, :string, doc: "Custom CSS class for additional styling to content"
  end

  def table_content(assigns) do
    ~H"""
    <div
      id={@id}
      phx-mounted={@animated && JS.add_class("scroll-smooth", to: "html")}
      role="navigation"
      aria-labelledby={@title && @id && "#{@id}-title"}
      class={[
        color_variant(@variant, @color),
        padding_size(@padding),
        rounded_size(@rounded),
        border_class(@border, @variant),
        space_size(@space),
        size_class(@size)
      ]}
      {@rest}
    >
      <h5
        :if={@title}
        class={["font-semibold text-sm leading-6", @title_class]}
        id={@title && @id && "#{@id}-title"}
      >
        {@title}
      </h5>

      <div
        :for={item <- @item}
        class={[
          "content-item",
          item[:active] && "font-bold",
          item[:font_weight],
          item[:class]
        ]}
      >
        <div :if={!is_nil(item[:title])} class={item[:title_class]}>{item[:title]}</div>
        <div class={[
          "flex items-center transition-all hover:font-bold hover:opacity-90",
          item[:wrapper_class]
        ]}>
          <.icon
            :if={!is_nil(item[:icon])}
            name={item[:icon]}
            class={["content-icon me-2 inline-block", item[:icon_class]]}
          />
          <.link :if={item[:link_title] && item[:link]} patch={item[:link]} class={item[:link_class]}>
            {item[:link_title]}
          </.link>
          <div class={item[:content_class]}>
            {render_slot(item)}
          </div>
        </div>
      </div>

      {render_slot(@inner_block)}
    </div>
    """
  end

  @doc """
  The `content_wrapper` component is used to wrap multiple content items, allowing for grouped
  and structured presentation of content. It provides options for custom styling and font
  weight, making it versatile for various use cases.

  ## Examples

  ```elixir
  <.content_wrapper>
    <.content_item icon="hero-hashtag">
      <.link href="#home">Content 1</.link>
    </.content_item>

    <.content_item icon="hero-hashtag">
      <.link href="#home">Content 2</.link>
    </.content_item>

    <.content_item icon="hero-hashtag" active>
      <.link href="#home">Content 3</.link>
    </.content_item>
  </.content_wrapper>
  ```
  """
  @doc type: :component
  attr :id, :string,
    default: nil,
    doc: "A unique identifier is used to manage state and interaction"

  attr :class, :string, default: nil, doc: "Custom CSS class for additional styling"
  attr :title, :string, default: nil, doc: "Specifies the title of the element"
  attr :icon, :string, default: nil, doc: "Icon displayed alongside of an item"

  attr :font_weight, :string,
    default: "font-normal",
    doc: "Determines custom class for the font weight"

  attr :rest, :global,
    doc:
      "Global attributes can define defaults which are merged with attributes provided by the caller"

  slot :inner_block, required: false, doc: "Inner block that renders HEEx content"

  def content_wrapper(assigns) do
    ~H"""
    <div
      id={@id}
      class={[
        "content-wrapper",
        @font_weight,
        @class
      ]}
      {@rest}
    >
      {render_slot(@inner_block)}
    </div>
    """
  end

  @doc """
  The `content_item` component is used to represent a single content item with an optional
  icon and custom styling.

  It allows for active state management and supports various configurations such as font
  weight and additional CSS classes.

  ## Examples

  ```elixir
  <.content_item icon="hero-hashtag">
    <.link href="#prag">Content 1</.link>
  </.content_item>
  ```
  """
  @doc type: :component
  attr :id, :string,
    default: nil,
    doc: "A unique identifier is used to manage state and interaction"

  attr :class, :string, default: nil, doc: "Custom CSS class for additional styling"

  attr :title_class, :string,
    default: nil,
    doc: "Custom CSS class for additional styling to title"

  attr :wrapper_content_class, :string,
    default: nil,
    doc: "Custom CSS class for additional styling to content wrapper"

  attr :content_class, :string,
    default: nil,
    doc: "Custom CSS class for additional styling to content"

  attr :link_class, :string, default: nil, doc: "Custom CSS class for additional styling to link"
  attr :title, :string, default: nil, doc: "Specifies the title of the element"
  attr :icon, :string, default: nil, doc: "Icon displayed alongside of an item"
  attr :icon_class, :string, default: nil, doc: "Determines custom class for the icon"
  attr :link_title, :string, default: nil, doc: "Determines link name"
  attr :link, :string, default: nil, doc: "Determines path of link"

  attr :font_weight, :string,
    default: "font-normal",
    doc: "Determines custom class for the font weight"

  attr :active, :boolean,
    default: false,
    doc: "Indicates whether the element is currently active and visible"

  attr :rest, :global,
    doc:
      "Global attributes can define defaults which are merged with attributes provided by the caller"

  slot :inner_block, required: false, doc: "Inner block that renders HEEx content"

  def content_item(assigns) do
    ~H"""
    <div
      id={@id}
      role="listitem"
      aria-current={@active && "true"}
      class={[
        "content-item",
        @active && "font-bold",
        @font_weight,
        @class
      ]}
      {@rest}
    >
      <div :if={!is_nil(@title)} class={@title_class}>{@title}</div>
      <div class={[
        "flex items-center transition-all hover:font-bold hover:opacity-90",
        @wrapper_content_class
      ]}>
        <.icon
          :if={!is_nil(@icon)}
          name={@icon}
          class={["content-icon me-2 inline-block", @icon_class]}
        />
        <.link :if={@link_title && @link} patch={@link} class={@link_class}>{@link_title}</.link>
        <div class={@content_class}>
          {render_slot(@inner_block)}
        </div>
      </div>
    </div>
    """
  end

  defp size_class("extra_small") do
    [
      "text-xs [&_.content-item]:py-1 [&_.content-item]:px-1.5 [&_.content-icon]:size-2.5"
    ]
  end

  defp size_class("small") do
    [
      "text-sm [&_.content-item]:py-1.5 [&_.content-item]:px-2 [&_.content-icon]:size-3"
    ]
  end

  defp size_class("medium") do
    [
      "text-base [&_.content-item]:py-2 [&_.content-item]:px-2.5 [&_.content-icon]:size-3.5"
    ]
  end

  defp size_class("large") do
    [
      "text-lg [&_.content-item]:py-2.5 [&_.content-item]:px-3 [&_.content-icon]:size-4"
    ]
  end

  defp size_class("extra_large") do
    [
      "text-xl [&_.content-item]:py-3 [&_.content-item]:px-3.5 [&_.content-icon]:size-5"
    ]
  end

  defp size_class(params) when is_binary(params), do: params

  defp space_size("extra_small"), do: "space-y-1"

  defp space_size("small"), do: "space-y-2"

  defp space_size("medium"), do: "space-y-3"

  defp space_size("large"), do: "space-y-4"

  defp space_size("extra_large"), do: "space-y-5"

  defp space_size(params) when is_binary(params), do: params

  defp border_class(_, variant)
       when variant in ["default", "shadow", "transparent", "gradient"],
       do: nil

  defp border_class("none", _), do: "border-0"
  defp border_class("extra_small", _), do: "border"
  defp border_class("small", _), do: "border-2"
  defp border_class("medium", _), do: "border-[3px]"
  defp border_class("large", _), do: "border-4"
  defp border_class("extra_large", _), do: "border-[5px]"
  defp border_class(params, _) when is_binary(params), do: params

  defp padding_size("extra_small"), do: "p-5"

  defp padding_size("small"), do: "p-6"

  defp padding_size("medium"), do: "p-7"

  defp padding_size("large"), do: "p-8"

  defp padding_size("extra_large"), do: "p-9"

  defp padding_size("double_large"), do: "p-10"

  defp padding_size("triple_large"), do: "p-12"

  defp padding_size("quadruple_large"), do: "p-16"

  defp padding_size(params) when is_binary(params), do: params

  defp rounded_size("extra_small"), do: "rounded-sm"

  defp rounded_size("small"), do: "rounded"

  defp rounded_size("medium"), do: "rounded-md"

  defp rounded_size("large"), do: "rounded-lg"

  defp rounded_size("extra_large"), do: "rounded-xl"

  defp rounded_size(params) when is_binary(params), do: params

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
      "bg-natural-light text-white",
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
      "bg-danger-light text-white",
      "dark:bg-danger-dark dark:text-black"
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
