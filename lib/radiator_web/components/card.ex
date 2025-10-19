defmodule RadiatorWeb.Components.Card do
  @moduledoc """
  Provides a set of card components for the `RadiatorWeb.Components.Card` project. These components
  allow for flexible and customizable card layouts, including features such as card titles,
  media, content sections, and footers.

  ## Components

    - `card/1`: Renders a basic card container with customizable size, color, border,
    padding, and other styling options.
    - `card_title/1`: Renders a title section for the card with support for icons and
    custom positioning.
    - `card_media/1`: Renders a media section within the card, such as an image or other media types.
    - `card_content/1`: Renders a content section within the card to display various information.
    - `card_footer/1`: Renders a footer section for the card, suitable for additional
    information or actions.

  ## Configuration Options

  The module supports various attributes such as size, color, variant, and border
  styles to match different design requirements. Components can be nested and
  combined to create complex card layouts with ease.

  This module offers a powerful and easy-to-use way to create cards with consistent
  styling and behavior while providing the flexibility to adapt to various use cases.

  **Documentation:** https://mishka.tools/chelekom/docs/card
  """

  use Phoenix.Component
  import RadiatorWeb.Components.Icon, only: [icon: 1]

  @positions [
    "start",
    "center",
    "end",
    "between",
    "around"
  ]

  @doc """
  The `card` component is used to display content in a structured container with various customization options such as `variant`, `color`, and `padding`. It supports an inner block for rendering nested content like media, titles, and footers, allowing for flexible layout designs.

  ## Examples

  ```elixir
  <.card>
    <.card_title title="This is a title in inner content" icon="hero-home" size="extra_large" />
    <.card_content>
      Lorem ipsum dolor sit amet consectetur adipisicing elit. Commodi ea atque soluta praesentium
      quidem dicta sapiente accusamus nihil.
    </.card_content>
  </.card>

  <.card>
    <.card_media src="https://example.com/bg.png" alt="test"/>
    <.card_content padding="large">
      <p>
        Lorem ipsum dolor sit amet consectetur adipisicing elit. Commodi ea atque soluta praesentium
        quidem dicta sapiente accusamus nihil.
      </p>
    </.card_content>
    <.card_footer padding="large">
      <.button size="full">See more</.button>
    </.card_footer>
  </.card>

  <.card padding="small">
    <.card_title class="flex items-center gap-2 justify-between">
      <div>Title</div>
      <div>Link</div>
    </.card_title>
    <.hr />
    <.card_content space="large">
      <.card_media rounded="large" src="https://example.com/bg.png" alt="test"/>
      <p>
        Lorem ipsum dolor sit amet consectetur adipisicing elit. Commodi ea atque soluta
        praesentium quidem dicta sapiente accusamus nihil.
      </p>
    </.card_content>
    <.hr />
    <.card_footer class="flex items-center gap-2">
      <.card_media src="https://example.com/bg.png" alt="test"/>
      <.card_media src="https://example.com/bg.png" alt="test"/>
      <.card_media src="https://example.com/bg.png" alt="test"/>
    </.card_footer>
  </.card>
  ```
  """
  @doc type: :component
  attr :id, :string,
    default: nil,
    doc: "A unique identifier is used to manage state and interaction"

  attr :variant, :string, default: "base", doc: "Determines the style"
  attr :color, :string, default: "natural", doc: "Determines color theme"
  attr :border, :string, default: "extra_small", doc: "Determines border style"
  attr :rounded, :string, default: "", doc: "Determines the border radius"
  attr :space, :string, default: "", doc: "Space between items"

  attr :font_weight, :string,
    default: "font-normal",
    doc: "Determines custom class for the font weight"

  attr :padding, :string, default: "", doc: "Determines padding for items"
  attr :class, :string, default: nil, doc: "Custom CSS class for additional styling"

  attr :rest, :global,
    doc:
      "Global attributes can define defaults which are merged with attributes provided by the caller"

  slot :inner_block, required: false, doc: "Inner block that renders HEEx content"

  def card(assigns) do
    ~H"""
    <div
      id={@id}
      role={@rest[:role] || "region"}
      class={[
        "overflow-hidden [&:has(.overlay)]:relative",
        space_class(@space),
        border_class(@border, @variant),
        color_variant(@variant, @color),
        rounded_size(@rounded),
        wrapper_padding(@padding),
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
  The `card_title` component is used to display the title section of a card with customizable
  attributes such as `position`, `size`, and `padding`.

  It supports adding an optional icon alongside the title and includes an inner block for additional content.

  ## Examples

  ```elixir
  <.card_title class="border-b" padding="small" position="between">
    <div>Title</div>
    <div><.icon name="hero-ellipsis-horizontal" /></div>
  </.card_title>
  ```
  """
  @doc type: :component
  attr :id, :string,
    default: nil,
    doc: "A unique identifier is used to manage state and interaction"

  attr :class, :string, default: nil, doc: "Custom CSS class for additional styling"
  attr :title, :string, default: nil, doc: "Specifies the title of the element"
  attr :icon, :string, default: nil, doc: "Icon displayed alongside of an item"

  attr :position, :string,
    values: @positions,
    default: "start",
    doc: "Determines the element position"

  attr :font_weight, :string,
    default: "font-semibold",
    doc: "Determines custom class for the font weight"

  attr :size, :string,
    default: "large",
    doc:
      "Determines the overall size of the elements, including padding, font size, and other items"

  attr :padding, :string, default: "", doc: "Determines padding for items"

  attr :rest, :global,
    doc:
      "Global attributes can define defaults which are merged with attributes provided by the caller"

  slot :inner_block, required: false, doc: "Inner block that renders HEEx content"

  def card_title(assigns) do
    ~H"""
    <div
      id={@id}
      class={[
        "card-section flex items-center gap-2",
        padding_size(@padding),
        content_position(@position),
        size_class(@size),
        @font_weight,
        @class
      ]}
      {@rest}
    >
      <div
        :if={@title || @icon}
        class="flex gap-2 items-center"
        aria-labelledby={if @title && @id, do: "#{@id}-title"}
      >
        <.icon :if={@icon} name={@icon} class="card-title-icon" />
        <h3 :if={@title}>{@title}</h3>
      </div>
      {render_slot(@inner_block)}
    </div>
    """
  end

  @doc """
  The `card_media` component is used to display media elements, such as images, within a card.

  It supports customizable attributes like `rounded` and `class` for styling and can include an inner
  block for additional content.

  ## Examples

  ```elixir
  <.card_media src="https://example.com/bg.png" alt="test"/>
  ```
  """
  @doc type: :component
  attr :id, :string,
    default: nil,
    doc: "A unique identifier is used to manage state and interaction"

  attr :alt, :string, default: nil, doc: "Media link description"
  attr :src, :string, required: true, doc: "Media link"
  attr :width, :string, default: "w-full", doc: "Media width"
  attr :rounded, :string, default: "", doc: "Determines the border radius"
  attr :class, :string, default: nil, doc: "Custom CSS class for additional styling"

  attr :rest, :global,
    doc:
      "Global attributes can define defaults which are merged with attributes provided by the caller"

  slot :inner_block, required: false, doc: "Inner block that renders HEEx content"

  def card_media(assigns) do
    ~H"""
    <div id={@id} class={["card-media overflow-hidden", rounded_size(@rounded), @width, @class]}>
      <img
        src={@src}
        alt={@alt}
        role={if !is_nil(@alt) && @alt == "", do: "presentation"}
        class={[
          "max-w-full"
        ]}
      />
    </div>
    """
  end

  @doc """
  The `card_content` component is used to display the main content of a card with customizable attributes
  such as `padding` and `space` between items.

  It supports an inner block for rendering additional content, allowing for flexible layout and styling.

  ## Examples

  ```elixir
  <.card_content padding="large">
    <p>
      Lorem ipsum dolor sit amet consectetur adipisicing elit. Commodi ea atque soluta praesentium
      quidem dicta sapiente accusamus nihil.
    </p>
  </.card_content>
  ```
  """
  @doc type: :component
  attr :id, :string,
    default: nil,
    doc: "A unique identifier is used to manage state and interaction"

  attr :space, :string, default: "", doc: "Space between items"
  attr :padding, :string, default: "", doc: "Determines padding for items"
  attr :class, :string, default: nil, doc: "Custom CSS class for additional styling"

  attr :rest, :global,
    doc:
      "Global attributes can define defaults which are merged with attributes provided by the caller"

  slot :inner_block, required: false, doc: "Inner block that renders HEEx content"

  def card_content(assigns) do
    ~H"""
    <div
      id={@id}
      class={[
        "card-section",
        space_class(@space),
        padding_size(@padding),
        @class
      ]}
    >
      {render_slot(@inner_block)}
    </div>
    """
  end

  @doc """
  The `card_footer` component is used to display the footer section of a card, allowing for
  additional actions or information at the bottom of the card.

  It supports customizable attributes such as `padding` and `class` for styling and includes an
  inner block for rendering content.

  ## Examples

  ```elixir
  <.card_footer padding="large">
    <.button size="full">See more</.button>
  </.card_footer>
  ```
  """
  @doc type: :component
  attr :id, :string,
    default: nil,
    doc: "A unique identifier is used to manage state and interaction"

  attr :class, :string, default: nil, doc: "Custom CSS class for additional styling"
  attr :padding, :string, default: "", doc: "Determines padding for items"

  attr :rest, :global,
    doc:
      "Global attributes can define defaults which are merged with attributes provided by the caller"

  slot :inner_block, required: false, doc: "Inner block that renders HEEx content"

  def card_footer(assigns) do
    ~H"""
    <div
      id={@id}
      class={[
        "card-section",
        padding_size(@padding),
        @class
      ]}
      {@rest}
    >
      {render_slot(@inner_block)}
    </div>
    """
  end

  defp border_class(_, variant) when variant in ["default", "shadow", "transparent", "gradient"],
    do: nil

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

  defp size_class("extra_small"), do: "text-xs [&_.card-title-icon]:size-3"

  defp size_class("small"), do: "text-sm [&_.card-title-icon]:size-3.5"

  defp size_class("medium"), do: "text-base [&_.card-title-icon]:size-4"

  defp size_class("large"), do: "text-lg [&_.card-title-icon]:size-5"

  defp size_class("extra_large"), do: "text-xl [&_.card-title-icon]:size-6"

  defp size_class(params) when is_binary(params), do: params

  defp content_position("start") do
    "justify-start"
  end

  defp content_position("end") do
    "justify-end"
  end

  defp content_position("center") do
    "justify-center"
  end

  defp content_position("between") do
    "justify-between"
  end

  defp content_position("around") do
    "justify-around"
  end

  defp content_position(params) when is_binary(params), do: params

  defp wrapper_padding("extra_small"),
    do: "[&:has(.card-section)>.card-section]:p-1 [&:not(:has(.card-section))]:p-1"

  defp wrapper_padding("small"),
    do: "[&:has(.card-section)>.card-section]:p-2 [&:not(:has(.card-section))]:p-2"

  defp wrapper_padding("medium"),
    do: "[&:has(.card-section)>.card-section]:p-3 [&:not(:has(.card-section))]:p-3"

  defp wrapper_padding("large"),
    do: "[&:has(.card-section)>.card-section]:p-4 [&:not(:has(.card-section))]:p-4"

  defp wrapper_padding("extra_large"),
    do: "[&:has(.card-section)>.card-section]:p-5 [&:not(:has(.card-section))]:p-5"

  defp wrapper_padding(params) when is_binary(params), do: params

  defp padding_size("extra_small"), do: "p-1"

  defp padding_size("small"), do: "p-2"

  defp padding_size("medium"), do: "p-3"

  defp padding_size("large"), do: "p-4"

  defp padding_size("extra_large"), do: "p-5"

  defp padding_size(params) when is_binary(params), do: params

  defp space_class("extra_small"), do: "space-y-2"

  defp space_class("small"), do: "space-y-3"

  defp space_class("medium"), do: "space-y-4"

  defp space_class("large"), do: "space-y-5"

  defp space_class("extra_large"), do: "space-y-6"

  defp space_class("none"), do: nil

  defp space_class(params) when is_binary(params), do: params

  defp color_variant("base", _) do
    [
      "[&:not(:has(.overlay))]:bg-white text-base-text-light border-base-border-light shadow-sm",
      "dark:[&:not(:has(.overlay))]:bg-base-bg-dark dark:text-base-text-dark dark:border-base-border-dark"
    ]
  end

  defp color_variant("default", "white") do
    ["[&:not(:has(.overlay))]:bg-default-white-bg text-black"]
  end

  defp color_variant("default", "dark") do
    ["[&:not(:has(.overlay))]:bg-default-dark-bg text-white"]
  end

  defp color_variant("default", "natural") do
    [
      "[&:not(:has(.overlay))]:bg-natural-light text-white dark:[&:not(:has(.overlay))]:bg-natural-dark dark:text-black"
    ]
  end

  defp color_variant("default", "primary") do
    [
      "[&:not(:has(.overlay))]:bg-primary-light text-white dark:[&:not(:has(.overlay))]:bg-primary-dark dark:text-black"
    ]
  end

  defp color_variant("default", "secondary") do
    [
      "[&:not(:has(.overlay))]:bg-secondary-light text-white dark:[&:not(:has(.overlay))]:bg-secondary-dark dark:text-black"
    ]
  end

  defp color_variant("default", "success") do
    [
      "[&:not(:has(.overlay))]:bg-success-light text-white dark:[&:not(:has(.overlay))]:bg-success-dark dark:text-black"
    ]
  end

  defp color_variant("default", "warning") do
    [
      "[&:not(:has(.overlay))]:bg-warning-light text-white dark:[&:not(:has(.overlay))]:bg-warning-dark dark:text-black"
    ]
  end

  defp color_variant("default", "danger") do
    [
      "[&:not(:has(.overlay))]:bg-danger-light text-white dark:[&:not(:has(.overlay))]:bg-danger-dark dark:text-black"
    ]
  end

  defp color_variant("default", "info") do
    [
      "[&:not(:has(.overlay))]:bg-info-light text-white dark:[&:not(:has(.overlay))]:bg-info-dark dark:text-black"
    ]
  end

  defp color_variant("default", "misc") do
    [
      "[&:not(:has(.overlay))]:bg-misc-light text-white dark:[&:not(:has(.overlay))]:bg-misc-dark dark:text-black"
    ]
  end

  defp color_variant("default", "dawn") do
    [
      "[&:not(:has(.overlay))]:bg-dawn-light text-white dark:[&:not(:has(.overlay))]:bg-dawn-dark dark:text-black"
    ]
  end

  defp color_variant("default", "silver") do
    [
      "[&:not(:has(.overlay))]:bg-silver-light text-white dark:[&:not(:has(.overlay))]:bg-silver-dark dark:text-black"
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
      "[&:not(:has(.overlay))]:bg-natural-light text-white dark:[&:not(:has(.overlay))]:bg-natural-dark dark:text-black",
      "shadow-[0px_4px_6px_-4px_var(--color-shadow-natural)] shadow-[0px_10px_15px_-3px_var(--color-shadow-natural)] dark:shadow-none"
    ]
  end

  defp color_variant("shadow", "primary") do
    [
      "[&:not(:has(.overlay))]:bg-primary-light text-white dark:[&:not(:has(.overlay))]:bg-primary-dark dark:text-black",
      "shadow-[0px_4px_6px_-4px_var(--color-shadow-primary)] shadow-[0px_10px_15px_-3px_var(--color-shadow-primary)] dark:shadow-none"
    ]
  end

  defp color_variant("shadow", "secondary") do
    [
      "[&:not(:has(.overlay))]:bg-secondary-light text-white dark:[&:not(:has(.overlay))]:bg-secondary-dark dark:text-black",
      "shadow-[0px_4px_6px_-4px_var(--color-shadow-secondary)] shadow-[0px_10px_15px_-3px_var(--color-shadow-secondary)] dark:shadow-none"
    ]
  end

  defp color_variant("shadow", "success") do
    [
      "[&:not(:has(.overlay))]:bg-success-light text-white dark:[&:not(:has(.overlay))]:bg-success-dark dark:text-black",
      "shadow-[0px_4px_6px_-4px_var(--color-shadow-success)] shadow-[0px_10px_15px_-3px_var(--color-shadow-success)] dark:shadow-none"
    ]
  end

  defp color_variant("shadow", "warning") do
    [
      "[&:not(:has(.overlay))]:bg-warning-light text-white dark:[&:not(:has(.overlay))]:bg-warning-dark dark:text-black",
      "shadow-[0px_4px_6px_-4px_var(--color-shadow-warning)] shadow-[0px_10px_15px_-3px_var(--color-shadow-warning)] dark:shadow-none"
    ]
  end

  defp color_variant("shadow", "danger") do
    [
      "[&:not(:has(.overlay))]:bg-danger-light text-white dark:[&:not(:has(.overlay))]:bg-danger-dark dark:text-black",
      "shadow-[0px_4px_6px_-4px_var(--color-shadow-danger)] shadow-[0px_10px_15px_-3px_var(--color-shadow-danger)] dark:shadow-none"
    ]
  end

  defp color_variant("shadow", "info") do
    [
      "[&:not(:has(.overlay))]:bg-info-light text-white dark:[&:not(:has(.overlay))]:bg-info-dark dark:text-black",
      "shadow-[0px_4px_6px_-4px_var(--color-shadow-info)] shadow-[0px_10px_15px_-3px_var(--color-shadow-info)] dark:shadow-none"
    ]
  end

  defp color_variant("shadow", "misc") do
    [
      "[&:not(:has(.overlay))]:bg-misc-light text-white dark:[&:not(:has(.overlay))]:bg-misc-dark dark:text-black",
      "shadow-[0px_4px_6px_-4px_var(--color-shadow-misc)] shadow-[0px_10px_15px_-3px_var(--color-shadow-misc)] dark:shadow-none"
    ]
  end

  defp color_variant("shadow", "dawn") do
    [
      "[&:not(:has(.overlay))]:bg-dawn-light text-white dark:[&:not(:has(.overlay))]:bg-dawn-dark dark:text-black",
      "shadow-[0px_4px_6px_-4px_var(--color-shadow-dawn)] shadow-[0px_10px_15px_-3px_var(--color-shadow-dawn)] dark:shadow-none"
    ]
  end

  defp color_variant("shadow", "silver") do
    [
      "[&:not(:has(.overlay))]:bg-silver-light text-white dark:[&:not(:has(.overlay))]:bg-silver-dark dark:text-black",
      "shadow-[0px_4px_6px_-4px_var(--color-shadow-silver)] shadow-[0px_10px_15px_-3px_var(--color-shadow-silver)] dark:shadow-none"
    ]
  end

  defp color_variant("bordered", "white") do
    [
      "[&:not(:has(.overlay))]:bg-white text-black border-bordered-white-border"
    ]
  end

  defp color_variant("bordered", "dark") do
    [
      "[&:not(:has(.overlay))]:bg-bordered-dark-bg text-white border-bordered-dark-border"
    ]
  end

  defp color_variant("bordered", "natural") do
    [
      "text-natural-bordered-text-light border-natural-border-light [&:not(:has(.overlay))]:bg-natural-bordered-bg-light",
      "dark:text-natural-bordered-text-dark dark:border-natural-border-dark dark:[&:not(:has(.overlay))]:bg-natural-bordered-bg-dark"
    ]
  end

  defp color_variant("bordered", "primary") do
    [
      "text-primary-bordered-text-light border-primary-bordered-text-light [&:not(:has(.overlay))]:bg-primary-bordered-bg-light",
      "dark:text-primary-bordered-text-dark dark:border-primary-bordered-text-dark dark:[&:not(:has(.overlay))]:bg-primary-bordered-bg-dark"
    ]
  end

  defp color_variant("bordered", "secondary") do
    [
      "text-secondary-bordered-text-light border-secondary-bordered-text-light [&:not(:has(.overlay))]:bg-secondary-bordered-bg-light",
      "dark:text-secondary-bordered-text-dark dark:border-secondary-bordered-text-dark dark:[&:not(:has(.overlay))]:bg-secondary-bordered-bg-dark"
    ]
  end

  defp color_variant("bordered", "success") do
    [
      "text-success-bordered-text-light border-success-bordered-text-light [&:not(:has(.overlay))]:bg-success-bordered-bg-light",
      "dark:text-success-bordered-text-dark dark:border-success-bordered-text-dark dark:[&:not(:has(.overlay))]:bg-success-bordered-bg-dark"
    ]
  end

  defp color_variant("bordered", "warning") do
    [
      "text-warning-bordered-text-light border-warning-bordered-text-light [&:not(:has(.overlay))]:bg-warning-bordered-bg-light",
      "dark:text-warning-bordered-text-dark dark:border-warning-bordered-text-dark dark:[&:not(:has(.overlay))]:bg-warning-bordered-bg-dark"
    ]
  end

  defp color_variant("bordered", "danger") do
    [
      "text-danger-bordered-text-light border-danger-bordered-text-light [&:not(:has(.overlay))]:bg-danger-bordered-bg-light",
      "dark:text-danger-bordered-text-dark dark:border-danger-bordered-text-dark dark:[&:not(:has(.overlay))]:bg-danger-bordered-bg-dark"
    ]
  end

  defp color_variant("bordered", "info") do
    [
      "text-info-bordered-text-light border-info-bordered-text-light [&:not(:has(.overlay))]:bg-info-bordered-bg-light",
      "dark:text-info-bordered-text-dark dark:border-info-bordered-text-dark dark:[&:not(:has(.overlay))]:bg-info-bordered-bg-dark"
    ]
  end

  defp color_variant("bordered", "misc") do
    [
      "text-misc-bordered-text-light border-misc-bordered-text-light [&:not(:has(.overlay))]:bg-misc-bordered-bg-light",
      "dark:text-misc-bordered-text-dark dark:border-misc-bordered-text-dark dark:[&:not(:has(.overlay))]:bg-misc-bordered-bg-dark"
    ]
  end

  defp color_variant("bordered", "dawn") do
    [
      "text-dawn-bordered-text-light border-dawn-bordered-text-light [&:not(:has(.overlay))]:bg-dawn-bordered-bg-light",
      "dark:text-dawn-bordered-text-dark dark:border-dawn-bordered-text-dark dark:[&:not(:has(.overlay))]:bg-dawn-bordered-bg-dark"
    ]
  end

  defp color_variant("bordered", "silver") do
    [
      "text-silver-bordered-text-light border-silver-bordered-text-light [&:not(:has(.overlay))]:bg-silver-bordered-bg-light",
      "dark:text-silver-bordered-text-dark dark:border-silver-bordered-text-dark dark:[&:not(:has(.overlay))]:bg-silver-bordered-bg-dark"
    ]
  end

  defp color_variant("transparent", "natural") do
    [
      "text-natural-light dark:text-natural-dark"
    ]
  end

  defp color_variant("transparent", "primary") do
    [
      "text-primary-light dark:text-primary-dark"
    ]
  end

  defp color_variant("transparent", "secondary") do
    [
      "text-secondary-light dark:text-secondary-dark"
    ]
  end

  defp color_variant("transparent", "success") do
    [
      "text-success-light dark:text-success-dark"
    ]
  end

  defp color_variant("transparent", "warning") do
    [
      "text-warning-light dark:text-warning-dark"
    ]
  end

  defp color_variant("transparent", "danger") do
    [
      "text-danger-light dark:text-danger-dark"
    ]
  end

  defp color_variant("transparent", "info") do
    [
      "text-info-light dark:text-info-dark"
    ]
  end

  defp color_variant("transparent", "misc") do
    [
      "text-misc-light dark:text-misc-dark"
    ]
  end

  defp color_variant("transparent", "dawn") do
    [
      "text-dawn-light dark:text-dawn-dark"
    ]
  end

  defp color_variant("transparent", "silver") do
    [
      "text-silver-light dark:text-silver-dark"
    ]
  end

  defp color_variant("gradient", "natural") do
    [
      "[&:not(:has(.overlay))]:bg-gradient-to-br from-gradient-natural-from-light to-gradient-natural-to-light text-white",
      "dark:from-gradient-natural-from-dark dark:to-white dark:text-black"
    ]
  end

  defp color_variant("gradient", "primary") do
    [
      "[&:not(:has(.overlay))]:bg-gradient-to-br from-gradient-primary-from-light to-gradient-primary-to-light text-white",
      "dark:from-gradient-primary-from-dark dark:to-gradient-primary-to-dark dark:text-black"
    ]
  end

  defp color_variant("gradient", "secondary") do
    [
      "[&:not(:has(.overlay))]:bg-gradient-to-br from-gradient-secondary-from-light to-gradient-secondary-to-light text-white",
      "dark:from-gradient-secondary-from-dark dark:to-gradient-secondary-to-dark dark:text-black"
    ]
  end

  defp color_variant("gradient", "success") do
    [
      "[&:not(:has(.overlay))]:bg-gradient-to-br from-gradient-success-from-light to-gradient-success-to-light text-white",
      "dark:from-gradient-success-from-dark dark:to-gradient-success-to-dark dark:text-black"
    ]
  end

  defp color_variant("gradient", "warning") do
    [
      "[&:not(:has(.overlay))]:bg-gradient-to-br from-gradient-warning-from-light to-gradient-warning-to-light text-white",
      "dark:from-gradient-warning-from-dark dark:to-gradient-warning-to-dark dark:text-black"
    ]
  end

  defp color_variant("gradient", "danger") do
    [
      "[&:not(:has(.overlay))]:bg-gradient-to-br from-gradient-danger-from-light to-gradient-danger-to-light text-white",
      "dark:from-gradient-danger-from-dark dark:to-gradient-danger-to-dark dark:text-black"
    ]
  end

  defp color_variant("gradient", "info") do
    [
      "[&:not(:has(.overlay))]:bg-gradient-to-br from-gradient-info-from-light to-gradient-info-to-light text-white",
      "dark:from-gradient-info-from-dark dark:to-gradient-info-to-dark dark:text-black"
    ]
  end

  defp color_variant("gradient", "misc") do
    [
      "[&:not(:has(.overlay))]:bg-gradient-to-br from-gradient-misc-from-light to-gradient-misc-to-light text-white",
      "dark:from-gradient-misc-from-dark dark:to-gradient-misc-to-dark dark:text-black"
    ]
  end

  defp color_variant("gradient", "dawn") do
    [
      "[&:not(:has(.overlay))]:bg-gradient-to-br from-gradient-dawn-from-light to-gradient-dawn-to-light text-white",
      "dark:from-gradient-dawn-from-dark dark:to-gradient-dawn-to-dark dark:text-black"
    ]
  end

  defp color_variant("gradient", "silver") do
    [
      "[&:not(:has(.overlay))]:bg-gradient-to-br from-gradient-silver-from-light to-gradient-silver-to-light text-white",
      "dark:from-gradient-silver-from-dark dark:to-gradient-silver-to-dark dark:text-black"
    ]
  end

  defp color_variant(params, _) when is_binary(params), do: params
end
