defmodule RadiatorWeb.Components.Blockquote do
  @moduledoc """
  This module provides a versatile `RadiatorWeb.Components.Blockquote` component for creating
  stylish and customizable blockquotes in your Phoenix LiveView application.

  ## Features

  - **Customizable Styles**: Choose from multiple `variant` styles like `default`,
  `outline`, `transparent`, `shadow`, and `bordered` to match your design needs.
  - **Color Themes**: Apply different color themes, including `primary`, `secondary`,
  `success`, `warning`, and more.
  - **Flexible Sizing**: Control the overall size of the blockquote, as well as specific
  attributes like padding, border radius, and font weight.
  - **Icon and Caption Support**: Add icons and captions to your blockquotes for
  enhanced visual appeal and content clarity.
  - **Positioning Options**: Fine-tune the positioning and spacing of content within the
  blockquote for a polished layout.
  - **Global Attributes**: Utilize global attributes such as `left_border`, `right_border`,
  `hide_border`, and `full_border` to easily customize the border display and positioning.

  Use this module to create visually appealing and content-rich blockquotes that enhance
  the readability and aesthetics of your LiveView applications.

  **Documentation:** https://mishka.tools/chelekom/docs/blockquote
  """

  use Phoenix.Component
  import RadiatorWeb.Components.Icon, only: [icon: 1]
  use Gettext, backend: RadiatorWeb.Gettext

  @doc """
  The `blockquote` component is used to display stylized quotations with customizable attributes
  such as `variant`, `color`, and `padding`. It supports optional captions and icons to
  enhance the visual presentation.

  ## Examples

  ```elixir
  <.blockquote left_border hide_icon>
    <p>
      Lorem ipsum, dolor sit amet consectetur adipisicing elit. Rem nihil commodi,
      facere voluptatum dolores tempora vero soluta harum nam esse
    </p>
    <:caption
      image="https://example.com/profile.jpg"
      position="left"
    >
      Shahryar Tavakkoli | CEO
    </:caption>
  </.blockquote>

  <.blockquote left_border icon="hero-chat-bubble-left-ellipsis">
    <p>
      Lorem ipsum, dolor sit amet consectetur adipisicing elit. Rem nihil commodi,
      facere voluptatum dolores tempora vero soluta harum nam esse
    </p>
    <:caption
      image="https://example.com/profile.jpg"
      position="left"
    >
      Shahryar Tavakkoli | CEO
    </:caption>
  </.blockquote>

  <.blockquote variant="transparent" color="primary">
    <p>
      Lorem ipsum, dolor sit amet consectetur adipisicing elit. Rem nihil commodi,
      facere voluptatum dolores tempora vero soluta harum nam esse
    </p>
    <:caption image="https://example.com/profile.jpg">
      Shahryar Tavakkoli | CEO
    </:caption>
  </.blockquote>

  <.blockquote variant="shadow" color="dark">
    <p>
      Lorem ipsum, dolor sit amet consectetur adipisicing elit. Rem nihil commodi,
      facere voluptatum dolores tempora vero soluta harum nam esse
    </p>
    <:caption image="https://example.com/profile.jpg">
      Shahryar Tavakkoli | CEO
    </:caption>
  </.blockquote>
  ```
  """
  @doc type: :component
  attr :id, :string,
    default: nil,
    doc: "A unique identifier is used to manage state and interaction"

  attr :variant, :string, default: "base", doc: "Determines the style"
  attr :color, :string, default: "natural", doc: "Determines color theme"
  attr :border, :string, default: "medium", doc: "Determines border style"
  attr :rounded, :string, default: "small", doc: "Determines the border radius"

  attr :size, :string,
    default: "medium",
    doc:
      "Determines the overall size of the elements, including padding, font size, and other items"

  attr :space, :string, default: "small", doc: "Space between items"

  attr :font_weight, :string,
    default: "font-normal",
    doc: "Determines custom class for the font weight"

  attr :padding, :string, default: "small", doc: "Determines padding for items"

  attr :class, :string, default: nil, doc: "Custom CSS class for additional styling"
  attr :icon, :string, default: "hero-quote", doc: "Icon displayed alongside of an item"
  attr :icon_class, :string, default: nil, doc: "Determines custom class for the icon"
  attr :blockquote_class, :string, default: nil, doc: "Determines custom class for the blockquote"

  slot :caption, required: false do
    attr :image, :string, doc: "Image displayed alongside of an item"
    attr :image_class, :string, doc: "Determines custom class for the image"
    attr :alt, :string, doc: "Determines alt of image"
    attr :class, :string, doc: "Determines custom class for caption wrapper"
    attr :content_class, :string, doc: "Determines custom class for caption content"

    attr :position, :string,
      values: ["right", "left", "center"],
      doc: "Determines the element position"
  end

  slot :inner_block, required: false, doc: "Inner block that renders HEEx content"

  attr :rest, :global,
    include: ~w(left_border right_border hide_border full_border hide_icon),
    doc:
      "Global attributes can define defaults which are merged with attributes provided by the caller"

  def blockquote(assigns) do
    ~H"""
    <div class={[
      space_class(@space),
      border_class(@border, border_position(@rest), @variant),
      color_variant(@variant, @color),
      rounded_size(@rounded),
      padding_size(@padding),
      size_class(@size),
      @font_weight,
      @class
    ]}>
      <.blockquote_icon
        :if={is_nil(@rest[:hide_icon])}
        name={@icon}
        class={["quote-icon", @icon_class]}
      />
      <blockquote class={["p-2 italic", @blockquote_class]} cite={@rest[:cite] && @rest[:cite]}>
        <p>
          {render_slot(@inner_block)}
        </p>
      </blockquote>
      <div
        :for={caption <- @caption}
        class={[
          "flex items-center space-x-3 rtl:space-x-reverse",
          !is_nil(caption[:position]) && caption_position(caption[:position]),
          caption[:class]
        ]}
      >
        <img
          :if={!is_nil(caption[:image])}
          class={["w-6 h-6 rounded-full", caption[:image_class]]}
          src={caption[:image]}
          alt={caption[:alt] || gettext("Author image")}
        />
        <div class={["flex items-center divide-x-2 rtl:divide-x-reverse", caption[:content_class]]}>
          {render_slot(caption)}
        </div>
      </div>
    </div>
    """
  end

  @doc type: :component
  attr :name, :string, required: true, doc: "Specifies the name of the element"
  attr :class, :list, default: nil, doc: "Custom CSS class for additional styling"

  defp blockquote_icon(%{name: "hero-quote"} = assigns) do
    ~H"""
    <svg
      class={["w-8 h-8", @class]}
      xmlns="http://www.w3.org/2000/svg"
      fill="currentColor"
      viewBox="0 0 18 14"
    >
      <path d="M6 0H2a2 2 0 0 0-2 2v4a2 2 0 0 0 2 2h4v1a3 3 0 0 1-3 3H2a1 1 0 0 0 0 2h1a5.006 5.006 0 0 0 5-5V2a2 2 0 0 0-2-2Zm10 0h-4a2 2 0 0 0-2 2v4a2 2 0 0 0 2 2h4v1a3 3 0 0 1-3 3h-1a1 1 0 0 0 0 2h1a5.006 5.006 0 0 0 5-5V2a2 2 0 0 0-2-2Z" />
    </svg>
    """
  end

  defp blockquote_icon(assigns) do
    ~H"""
    <.icon
      :if={!is_nil(@name)}
      name={@name}
      class={Enum.reject(@class, &is_nil(&1)) |> Enum.join(" ")}
    />
    """
  end

  defp caption_position("right") do
    "ltr:justify-end rtl:justify-start"
  end

  defp caption_position("left") do
    "ltr:justify-start rtl:justify-end"
  end

  defp caption_position("center") do
    "justify-center"
  end

  defp caption_position(params) when is_binary(params), do: params

  defp space_class("extra_small"), do: "space-y-2"

  defp space_class("small"), do: "space-y-3"

  defp space_class("medium"), do: "space-y-4"

  defp space_class("large"), do: "space-y-5"

  defp space_class("extra_large"), do: "space-y-6"

  defp space_class("none"), do: nil

  defp space_class(params) when is_binary(params), do: params

  defp border_class(_, _, variant)
       when variant in ["default", "shadow", "transparent", "gradient"],
       do: nil

  defp border_class(_, "none", _), do: nil

  defp border_class("extra_small", position, _) do
    [
      position == "left" && "border-s",
      position == "right" && "border-e",
      position == "full" && "border"
    ]
  end

  defp border_class("small", position, _) do
    [
      position == "left" && "border-s-2",
      position == "right" && "border-s-2",
      position == "full" && "border-2"
    ]
  end

  defp border_class("medium", position, _) do
    [
      position == "left" && "border-s-[3px]",
      position == "right" && "border-e-[3px]",
      position == "full" && "border-[3px]"
    ]
  end

  defp border_class("large", position, _) do
    [
      position == "left" && "border-s-4",
      position == "right" && "border-e-4",
      position == "full" && "border-4"
    ]
  end

  defp border_class("extra_large", position, _) do
    [
      position == "left" && "border-s-[5px]",
      position == "right" && "border-e-[5px]",
      position == "full" && "border-[5px]"
    ]
  end

  defp border_class(params, _, _) when is_binary(params), do: [params]

  defp rounded_size("extra_small"), do: "rounded-sm"

  defp rounded_size("small"), do: "rounded"

  defp rounded_size("medium"), do: "rounded-md"

  defp rounded_size("large"), do: "rounded-lg"

  defp rounded_size("extra_large"), do: "rounded-xl"

  defp rounded_size("full"), do: "rounded-full"

  defp rounded_size("none"), do: nil

  defp rounded_size(params) when is_binary(params), do: params

  defp padding_size("extra_small"), do: "p-1"

  defp padding_size("small"), do: "p-2"

  defp padding_size("medium"), do: "p-3"

  defp padding_size("large"), do: "p-4"

  defp padding_size("extra_large"), do: "p-5"

  defp padding_size("none"), do: "p-0"

  defp padding_size(params) when is_binary(params), do: params

  defp size_class("extra_small"), do: "text-[12px] [&>.quote-icon]:size-7"

  defp size_class("small"), do: "text-[13px] [&>.quote-icon]:size-8"

  defp size_class("medium"), do: "text-[14px] [&>.quote-icon]:size-9"

  defp size_class("large"), do: "text-[15px] [&>.quote-icon]:size-10"

  defp size_class("extra_large"), do: "text-[16px] [&>.quote-icon]:size-12"

  defp size_class(params) when is_binary(params), do: params

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

  defp color_variant("bordered", "white") do
    ["bg-white text-black border-bordered-white-border"]
  end

  defp color_variant("bordered", "dark") do
    ["bg-bordered-dark-bg text-white border-bordered-dark-border"]
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

  defp border_position(%{hide_border: true}), do: "none"
  defp border_position(%{left_border: true}), do: "left"
  defp border_position(%{right_border: true}), do: "right"
  defp border_position(%{full_border: true}), do: "full"
  defp border_position(_), do: "left"
end
