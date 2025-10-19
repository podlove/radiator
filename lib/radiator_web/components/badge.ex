defmodule RadiatorWeb.Components.Badge do
  @moduledoc """
  Provides customizable and flexible badge components for use in Phoenix LiveView.

  The `RadiatorWeb.Components.Badge` module allows you to create badge elements with various styles,
  sizes, and colors. You can add icons, indicators, and dismiss buttons, and configure
  the badge's appearance and behavior using a range of attributes.
  This module also provides helper functions to show and hide badges with smooth transition effects.

  > The badges can be customized further with global attributes such as position, padding, and more.
  > Utilize the built-in helper functions to dynamically show and hide badges as needed.

  This module is designed to be highly customizable, enabling you to create badges
  that fit your application's needs seamlessly.

  **Documentation:** https://mishka.tools/chelekom/docs/badge
  """

  use Phoenix.Component
  alias Phoenix.LiveView.JS
  import RadiatorWeb.Components.Icon, only: [icon: 1]
  use Gettext, backend: RadiatorWeb.Gettext

  @icon_positions [
    "right_icon",
    "left_icon"
  ]

  @indicator_positions [
    "indicator",
    "right_indicator",
    "left_indicator",
    "top_left_indicator",
    "top_center_indicator",
    "top_right_indicator",
    "middle_left_indicator",
    "middle_right_indicator",
    "bottom_left_indicator",
    "bottom_center_indicator",
    "bottom_right_indicator"
  ]

  @dismiss_positions ["dismiss", "right_dismiss", "left_dismiss"]

  @doc """
  The `badge` component is used to display badges with various styles and indicators.

  It supports customization of attributes such as `variant`, `size`, and `color`,
  along with optional icons and indicator styles.

  ## Examples

  ```elixir
  <.badge icon="hero-arrow-down-tray" color="warning" dismiss indicator>Default warning</.badge>
  <.badge variant="shadow" rounded="large" indicator>Active</.badge>

  <.badge icon="hero-square-2-stack" color="danger" size="medium" bottom_center_indicator pinging>
    Duplicate
  </.badge>
  ```
  """
  @doc type: :component
  attr :id, :string,
    default: nil,
    doc: "A unique identifier is used to manage state and interaction"

  attr :variant, :string, default: "base", doc: "Determines the style"

  attr :size, :string,
    default: "extra_small",
    doc:
      "Determines the overall size of the elements, including padding, font size, and other items"

  attr :rounded, :string, default: "small", doc: "Determines the border radius"

  attr :color, :string, default: "natural", doc: "Determines color theme"
  attr :border, :string, default: "extra_small", doc: "Determines border style"

  attr :font_weight, :string,
    default: "font-normal",
    doc: "Determines custom class for the font weight"

  attr :icon, :string, default: nil, doc: "Icon displayed alongside of an item"
  attr :class, :string, default: nil, doc: "Custom CSS class for additional styling"
  attr :icon_class, :string, default: nil, doc: "Custom CSS class for additional styling"
  attr :content_class, :string, default: nil, doc: "Custom CSS class for additional styling"

  attr :dismiss_class, :string,
    default: nil,
    doc: "Custom CSS class for additional styling of dismiss button"

  attr :badge_position, :string, default: "", doc: "position of badge"

  attr :indicator_class, :string,
    default: nil,
    doc: "CSS class for additional styling of the badge indicator"

  attr :indicator_size, :string, default: "", doc: "Specifies the size of the badge indicator"

  attr :params, :map,
    default: %{kind: "badge"},
    doc: "A map of additional parameters used for element configuration, such as type or kind"

  attr :rest, :global,
    include:
      ["pinging", "circle"] ++ @dismiss_positions ++ @indicator_positions ++ @icon_positions,
    doc:
      "Global attributes can define defaults which are merged with attributes provided by the caller"

  slot :inner_block, required: false, doc: "Inner block that renders HEEx content"

  attr :type, :string, default: "button", doc: "Determines the type of the badge"

  def badge(assigns) do
    ~H"""
    <div
      id={@id}
      role="status"
      class={
        default_classes(@rest[:pinging]) ++
          size_class(@size, @rest[:circle]) ++
          [
            color_variant(@variant, @color),
            border_size(@border, @variant),
            rounded_size(@rounded),
            badge_position(@badge_position),
            @badge_position != "" && "absolute",
            @font_weight,
            @class
          ]
      }
      {drop_rest(@rest)}
    >
      <.badge_dismiss
        :if={dismiss_position(@rest) == "left"}
        id={@id}
        type={@type}
        class={@dismiss_class}
        params={@params}
      />
      <.badge_indicator position="left" size={@indicator_size} class={@indicator_class} {@rest} />
      <.icon
        :if={icon_position(@icon, @rest) == "left"}
        name={@icon}
        class={["badge-icon", @icon_class]}
      />
      <div class={["leading-5", @content_class]}>
        {render_slot(@inner_block)}
      </div>
      <.icon
        :if={icon_position(@icon, @rest) == "right"}
        name={@icon}
        class={["badge-icon", @icon_class]}
      />
      <.badge_indicator size={@indicator_size} class={@indicator_class} {@rest} />
      <.badge_dismiss
        :if={dismiss_position(@rest) == "right"}
        id={@id}
        type={@type}
        class={@dismiss_class}
        params={@params}
      />
    </div>
    """
  end

  @doc type: :component
  attr :id, :string,
    default: nil,
    doc: "A unique identifier is used to manage state and interaction"

  attr :dismiss, :boolean,
    default: false,
    doc: "Determines if the badge should include a dismiss button"

  attr :icon_class, :string, default: "size-4", doc: "Determines custom class for the icon"
  attr :class, :string, default: "size-4", doc: "Determines custom class"

  attr :params, :map,
    default: %{kind: "badge"},
    doc: "A map of additional parameters used for badge configuration, such as type or kind"

  attr :type, :string, default: "button", doc: "Determines the type of the badge"

  defp badge_dismiss(assigns) do
    ~H"""
    <button
      type={@type}
      class={["dismiss-button inline-flex justify-center items-center w-fit shrink-0", @class]}
      aria-label={gettext("close")}
      phx-click={JS.push("dismiss", value: Map.merge(%{id: @id}, @params)) |> hide_badge("##{@id}")}
    >
      <.icon name="hero-x-mark" class={"#{@icon_class}"} />
    </button>
    """
  end

  @doc type: :component
  attr :position, :string, default: "none", doc: "Determines the element position"
  attr :class, :string, default: nil, doc: "Custom CSS class for additional styling"

  attr :size, :string,
    doc:
      "Determines the overall size of the elements, including padding, font size, and other items"

  attr :rest, :global,
    doc:
      "Global attributes can define defaults which are merged with attributes provided by the caller"

  defp badge_indicator(%{position: "left", rest: %{left_indicator: true}} = assigns) do
    ~H"""
    <span class={["indicator", indicator_size(@size), @class]} />
    """
  end

  defp badge_indicator(%{position: "left", rest: %{indicator: true}} = assigns) do
    ~H"""
    <span class={["indicator", indicator_size(@size), @class]} />
    """
  end

  defp badge_indicator(%{position: "none", rest: %{right_indicator: true}} = assigns) do
    ~H"""
    <span class={["indicator", indicator_size(@size), @class]} />
    """
  end

  defp badge_indicator(%{position: "none", rest: %{top_left_indicator: true}} = assigns) do
    ~H"""
    <span class={[
      "indicator",
      indicator_size(@size),
      @class || "absolute -translate-y-1/2 -translate-x-1/2 right-auto top-0 left-0"
    ]} />
    """
  end

  defp badge_indicator(%{position: "none", rest: %{top_center_indicator: true}} = assigns) do
    ~H"""
    <span class={[
      "indicator",
      indicator_size(@size),
      @class || "absolute top-0 -translate-y-1/2 translate-x-1/2 right-1/2"
    ]} />
    """
  end

  defp badge_indicator(%{position: "none", rest: %{top_right_indicator: true}} = assigns) do
    ~H"""
    <span class={[
      "indicator",
      indicator_size(@size),
      @class || "absolute -translate-y-1/2 translate-x-1/2 left-auto top-0 right-0"
    ]} />
    """
  end

  defp badge_indicator(%{position: "none", rest: %{middle_left_indicator: true}} = assigns) do
    ~H"""
    <span class={[
      "indicator",
      indicator_size(@size),
      @class || "absolute -translate-y-1/2 -translate-x-1/2 right-auto left-0 top-2/4"
    ]} />
    """
  end

  defp badge_indicator(%{position: "none", rest: %{middle_right_indicator: true}} = assigns) do
    ~H"""
    <span class={[
      "indicator",
      indicator_size(@size),
      @class || "absolute -translate-y-1/2 translate-x-1/2 left-auto right-0 top-2/4"
    ]} />
    """
  end

  defp badge_indicator(%{position: "none", rest: %{bottom_left_indicator: true}} = assigns) do
    ~H"""
    <span class={[
      "indicator",
      indicator_size(@size),
      @class || "absolute translate-y-1/2 -translate-x-1/2 right-auto bottom-0 left-0"
    ]} />
    """
  end

  defp badge_indicator(%{position: "none", rest: %{bottom_center_indicator: true}} = assigns) do
    ~H"""
    <span class={[
      "indicator",
      indicator_size(@size),
      @class || "absolute translate-y-1/2 translate-x-1/2 bottom-0 right-1/2"
    ]} />
    """
  end

  defp badge_indicator(%{position: "none", rest: %{bottom_right_indicator: true}} = assigns) do
    ~H"""
    <span class={[
      "indicator",
      indicator_size(@size),
      @class || "absolute translate-y-1/2 translate-x-1/2 left-auto bottom-0 right-0"
    ]} />
    """
  end

  defp badge_indicator(assigns) do
    ~H"""
    """
  end

  defp badge_position("top-left"), do: "-translate-y-1/2 -translate-x-1/2 right-auto top-0 left-0"

  defp badge_position("top-right"), do: "-translate-y-1/2 translate-x-1/2 left-auto top-0 right-0"

  defp badge_position("bottom-left"),
    do: "translate-y-1/2 -translate-x-1/2 right-auto bottom-0 left-0"

  defp badge_position("bottom-right"),
    do: "translate-y-1/2 translate-x-1/2 left-auto bottom-0 right-0"

  defp badge_position(params) when is_binary(params), do: params

  defp color_variant("base", _) do
    [
      "bg-white text-base-text-light border-base-border-light shadow-sm [&>.indicator]:bg-base-border-light",
      "dark:bg-base-bg-dark dark:text-base-text-dark dark:border-base-border-dark dark:[&>.indicator]:bg-base-border-dark"
    ]
  end

  defp color_variant("default", "white") do
    ["bg-white text-black [&>.indicator]:bg-black"]
  end

  defp color_variant("default", "dark") do
    ["bg-default-dark-bg text-white [&>.indicator]:bg-white"]
  end

  defp color_variant("default", "natural") do
    [
      "bg-natural-light text-white dark:bg-natural-dark dark:text-black",
      "[&>.indicator]:bg-white dark:[&>.indicator]:bg-black"
    ]
  end

  defp color_variant("default", "primary") do
    [
      "bg-primary-light text-white dark:bg-primary-dark dark:text-black",
      "[&>.indicator]:bg-primary-indicator-light dark:[&>.indicator]:bg-primary-indicator-dark"
    ]
  end

  defp color_variant("default", "secondary") do
    [
      "bg-secondary-light text-white dark:bg-secondary-dark dark:text-black",
      "[&>.indicator]:bg-secondary-indicator-light dark:[&>.indicator]:bg-secondary-indicator-dark"
    ]
  end

  defp color_variant("default", "success") do
    [
      "bg-success-light text-white dark:bg-success-dark dark:text-black",
      "[&>.indicator]:bg-success-indicator-light dark:[&>.indicator]:bg-success-indicator-dark"
    ]
  end

  defp color_variant("default", "warning") do
    [
      "bg-warning-light text-white dark:bg-warning-dark dark:text-black",
      "[&>.indicator]:bg-warning-indicator-light dark:[&>.indicator]:bg-warning-indicator-dark"
    ]
  end

  defp color_variant("default", "danger") do
    [
      "bg-danger-light text-white dark:bg-danger-dark dark:text-black",
      "[&>.indicator]:bg-danger-indicator-light dark:[&>.indicator]:bg-danger-indicator-dark"
    ]
  end

  defp color_variant("default", "info") do
    [
      "bg-info-light text-white dark:bg-info-dark dark:text-black",
      "[&>.indicator]:bg-info-indicator-light dark:[&>.indicator]:bg-info-indicator-dark"
    ]
  end

  defp color_variant("default", "misc") do
    [
      "bg-misc-light text-white dark:bg-misc-dark dark:text-black",
      "[&>.indicator]:bg-misc-indicator-light dark:[&>.indicator]:bg-misc-indicator-dark"
    ]
  end

  defp color_variant("default", "dawn") do
    [
      "bg-dawn-light text-white dark:bg-dawn-dark dark:text-black",
      "[&>.indicator]:bg-dawn-indicator-light dark:[&>.indicator]:bg-dawn-indicator-dark"
    ]
  end

  defp color_variant("default", "silver") do
    [
      "bg-silver-light text-white dark:bg-silver-dark dark:text-black",
      "[&>.indicator]:bg-silver-indicator-light dark:[&>.indicator]:bg-silver-indicator-dark"
    ]
  end

  defp color_variant("outline", "natural") do
    [
      "bg-transparent text-natural-light border-natural-light",
      "dark:text-natural-dark dark:border-natural-dark",
      "[&>.indicator]:bg-black dark:[&>.indicator]:bg-white"
    ]
  end

  defp color_variant("outline", "primary") do
    [
      "bg-transparent text-primary-light border-primary-light",
      "dark:text-primary-dark dark:border-primary-dark",
      "[&>.indicator]:bg-primary-indicator-light dark:[&>.indicator]:bg-primary-indicator-dark"
    ]
  end

  defp color_variant("outline", "secondary") do
    [
      "bg-transparent text-secondary-light border-secondary-light",
      "dark:text-secondary-dark dark:border-secondary-dark",
      "[&>.indicator]:bg-secondary-indicator-light dark:[&>.indicator]:bg-secondary-indicator-dark"
    ]
  end

  defp color_variant("outline", "success") do
    [
      "bg-transparent text-success-light border-success-light",
      "dark:text-success-dark dark:border-success-dark",
      "[&>.indicator]:bg-success-indicator-alt-light dark:[&>.indicator]:bg-success-indicator-dark"
    ]
  end

  defp color_variant("outline", "warning") do
    [
      "bg-transparent text-warning-light border-warning-light",
      "dark:text-warning-dark dark:border-warning-dark",
      "[&>.indicator]:bg-warning-indicator-alt-light dark:[&>.indicator]:bg-warning-indicator-dark"
    ]
  end

  defp color_variant("outline", "danger") do
    [
      "bg-transparent text-danger-light border-danger-light",
      "dark:text-danger-dark dark:border-danger-dark",
      "[&>.indicator]:bg-danger-indicator-alt-light dark:[&>.indicator]:bg-danger-indicator-dark"
    ]
  end

  defp color_variant("outline", "info") do
    [
      "bg-transparent text-info-light border-info-light",
      "dark:text-info-dark dark:border-info-dark",
      "[&>.indicator]:bg-info-indicator-alt-light dark:[&>.indicator]:bg-info-indicator-dark"
    ]
  end

  defp color_variant("outline", "misc") do
    [
      "bg-transparent text-misc-light border-misc-light",
      "dark:text-misc-dark dark:border-misc-dark",
      "[&>.indicator]:bg-misc-indicator-alt-light dark:[&>.indicator]:bg-misc-indicator-dark"
    ]
  end

  defp color_variant("outline", "dawn") do
    [
      "bg-transparent text-dawn-light border-dawn-light",
      "dark:text-dawn-dark dark:border-dawn-dark",
      "[&>.indicator]:bg-dawn-indicator-alt-light dark:[&>.indicator]:bg-dawn-indicator-dark"
    ]
  end

  defp color_variant("outline", "silver") do
    [
      "bg-transparent text-silver-light border-silver-light",
      "dark:text-silver-dark dark:border-silver-dark",
      "[&>.indicator]:bg-silver-indicator-alt-light dark:[&>.indicator]:bg-silver-indicator-dark"
    ]
  end

  defp color_variant("transparent", "natural") do
    [
      "bg-transparent text-natural-light",
      "dark:text-natural-dark border-transparent",
      "[&>.indicator]:bg-black dark:[&>.indicator]:bg-white"
    ]
  end

  defp color_variant("transparent", "primary") do
    [
      "bg-transparent text-primary-light",
      "dark:text-primary-dark border-transparent",
      "[&>.indicator]:bg-primary-indicator-light dark:[&>.indicator]:bg-primary-indicator-dark"
    ]
  end

  defp color_variant("transparent", "secondary") do
    [
      "bg-transparent text-secondary-light",
      "dark:text-secondary-dark border-transparent",
      "[&>.indicator]:bg-secondary-indicator-light dark:[&>.indicator]:bg-secondary-indicator-dark"
    ]
  end

  defp color_variant("transparent", "success") do
    [
      "bg-transparent text-success-light",
      "dark:text-success-dark border-transparent",
      "[&>.indicator]:bg-success-indicator-alt-light dark:[&>.indicator]:bg-success-indicator-dark"
    ]
  end

  defp color_variant("transparent", "warning") do
    [
      "bg-transparent text-warning-light",
      "dark:text-warning-dark border-transparent",
      "[&>.indicator]:bg-warning-indicator-alt-light dark:[&>.indicator]:bg-warning-indicator-dark"
    ]
  end

  defp color_variant("transparent", "danger") do
    [
      "bg-transparent text-danger-light",
      "dark:text-danger-dark border-transparent",
      "[&>.indicator]:bg-danger-indicator-alt-light dark:[&>.indicator]:bg-danger-indicator-dark"
    ]
  end

  defp color_variant("transparent", "info") do
    [
      "bg-transparent text-info-light",
      "dark:text-info-dark border-transparent",
      "[&>.indicator]:bg-info-indicator-alt-light dark:[&>.indicator]:bg-info-indicator-dark"
    ]
  end

  defp color_variant("transparent", "misc") do
    [
      "bg-transparent text-misc-light",
      "dark:text-misc-dark border-transparent",
      "[&>.indicator]:bg-misc-indicator-alt-light dark:[&>.indicator]:bg-misc-indicator-dark"
    ]
  end

  defp color_variant("transparent", "dawn") do
    [
      "bg-transparent text-dawn-light",
      "dark:text-dawn-dark border-transparent",
      "[&>.indicator]:bg-dawn-indicator-alt-light dark:[&>.indicator]:bg-dawn-indicator-dark"
    ]
  end

  defp color_variant("transparent", "silver") do
    [
      "bg-transparent text-silver-light",
      "dark:text-silver-dark border-transparent",
      "[&>.indicator]:bg-silver-indicator-alt-light dark:[&>.indicator]:bg-silver-indicator-dark"
    ]
  end

  defp color_variant("shadow", "natural") do
    [
      "bg-natural-light text-white dark:bg-natural-dark dark:text-black",
      "[&>.indicator]:bg-white dark:[&>.indicator]:bg-black",
      "shadow-[0px_4px_6px_-4px_var(--color-shadow-natural)] shadow-[0px_10px_15px_-3px_var(--color-shadow-natural)] dark:shadow-none"
    ]
  end

  defp color_variant("shadow", "primary") do
    [
      "bg-primary-light text-white dark:bg-primary-dark dark:text-black",
      "[&>.indicator]:bg-primary-indicator-light dark:[&>.indicator]:bg-primary-indicator-dark",
      "shadow-[0px_4px_6px_-4px_var(--color-shadow-primary)] shadow-[0px_10px_15px_-3px_var(--color-shadow-primary)] dark:shadow-none"
    ]
  end

  defp color_variant("shadow", "secondary") do
    [
      "bg-secondary-light text-white dark:bg-secondary-dark dark:text-black",
      "[&>.indicator]:bg-secondary-indicator-light dark:[&>.indicator]:bg-secondary-indicator-dark",
      "shadow-[0px_4px_6px_-4px_var(--color-shadow-secondary)] shadow-[0px_10px_15px_-3px_var(--color-shadow-secondary)] dark:shadow-none"
    ]
  end

  defp color_variant("shadow", "success") do
    [
      "bg-success-light text-white dark:bg-success-dark dark:text-black",
      "[&>.indicator]:bg-success-indicator-light dark:[&>.indicator]:bg-success-indicator-dark",
      "shadow-[0px_4px_6px_-4px_var(--color-shadow-success)] shadow-[0px_10px_15px_-3px_var(--color-shadow-success)] dark:shadow-none"
    ]
  end

  defp color_variant("shadow", "warning") do
    [
      "bg-warning-light text-white dark:bg-warning-dark dark:text-black",
      "[&>.indicator]:bg-warning-indicator-light dark:[&>.indicator]:bg-warning-indicator-dark",
      "shadow-[0px_4px_6px_-4px_var(--color-shadow-warning)] shadow-[0px_10px_15px_-3px_var(--color-shadow-warning)] dark:shadow-none"
    ]
  end

  defp color_variant("shadow", "danger") do
    [
      "bg-danger-light text-white dark:bg-danger-dark dark:text-black",
      "[&>.indicator]:bg-danger-indicator-light dark:[&>.indicator]:bg-danger-indicator-dark",
      "shadow-[0px_4px_6px_-4px_var(--color-shadow-danger)] shadow-[0px_10px_15px_-3px_var(--color-shadow-danger)] dark:shadow-none"
    ]
  end

  defp color_variant("shadow", "info") do
    [
      "bg-info-light text-white dark:bg-info-dark dark:text-black",
      "[&>.indicator]:bg-info-indicator-light dark:[&>.indicator]:bg-info-indicator-dark",
      "shadow-[0px_4px_6px_-4px_var(--color-shadow-info)] shadow-[0px_10px_15px_-3px_var(--color-shadow-info)] dark:shadow-none"
    ]
  end

  defp color_variant("shadow", "misc") do
    [
      "bg-misc-light text-white dark:bg-misc-dark dark:text-black",
      "[&>.indicator]:bg-misc-indicator-light dark:[&>.indicator]:bg-misc-indicator-dark",
      "shadow-[0px_4px_6px_-4px_var(--color-shadow-misc)] shadow-[0px_10px_15px_-3px_var(--color-shadow-misc)] dark:shadow-none"
    ]
  end

  defp color_variant("shadow", "dawn") do
    [
      "bg-dawn-light text-white dark:bg-dawn-dark dark:text-black",
      "[&>.indicator]:bg-dawn-indicator-light dark:[&>.indicator]:bg-dawn-indicator-dark",
      "shadow-[0px_4px_6px_-4px_var(--color-shadow-dawn)] shadow-[0px_10px_15px_-3px_var(--color-shadow-dawn)] dark:shadow-none"
    ]
  end

  defp color_variant("shadow", "silver") do
    [
      "bg-silver-light text-white dark:bg-silver-dark dark:text-black",
      "[&>.indicator]:bg-silver-indicator-light dark:[&>.indicator]:bg-silver-indicator-dark",
      "shadow-[0px_4px_6px_-4px_var(--color-shadow-silver)] shadow-[0px_10px_15px_-3px_var(--color-shadow-silver)] dark:shadow-none"
    ]
  end

  defp color_variant("bordered", "white") do
    ["bg-white text-black border-bordered-white-border [&>.indicator]:bg-black"]
  end

  defp color_variant("bordered", "dark") do
    ["bg-bordered-dark-bg text-white border-bordered-dark-border [&>.indicator]:bg-white"]
  end

  defp color_variant("bordered", "natural") do
    [
      "text-natural-bordered-text-light border-natural-border-light bg-natural-bordered-bg-light",
      "dark:text-natural-bordered-text-dark dark:border-natural-border-dark dark:bg-natural-bordered-bg-dark",
      "[&>.indicator]:bg-black dark:[&>.indicator]:bg-white"
    ]
  end

  defp color_variant("bordered", "primary") do
    [
      "text-primary-bordered-text-light border-primary-bordered-text-light bg-primary-bordered-bg-light",
      "dark:text-primary-bordered-text-dark dark:border-primary-bordered-text-dark dark:bg-primary-bordered-bg-dark",
      "[&>.indicator]:bg-primary-indicator-light dark:[&>.indicator]:bg-primary-indicator-dark"
    ]
  end

  defp color_variant("bordered", "secondary") do
    [
      "text-secondary-bordered-text-light border-secondary-bordered-text-light bg-secondary-bordered-bg-light",
      "dark:text-secondary-bordered-text-dark dark:border-secondary-bordered-text-dark dark:bg-secondary-bordered-bg-dark",
      "[&>.indicator]:bg-secondary-indicator-light dark:[&>.indicator]:bg-secondary-indicator-dark"
    ]
  end

  defp color_variant("bordered", "success") do
    [
      "text-success-bordered-text-light border-success-bordered-text-light bg-success-bordered-bg-light",
      "dark:text-success-bordered-text-dark dark:border-success-bordered-text-dark dark:bg-success-bordered-bg-dark",
      "[&>.indicator]:bg-success-indicator-alt-light dark:[&>.indicator]:bg-success-indicator-dark"
    ]
  end

  defp color_variant("bordered", "warning") do
    [
      "text-warning-bordered-text-light border-warning-bordered-text-light bg-warning-bordered-bg-light",
      "dark:text-warning-bordered-text-dark dark:border-warning-bordered-text-dark dark:bg-warning-bordered-bg-dark",
      "[&>.indicator]:bg-warning-indicator-alt-light dark:[&>.indicator]:bg-warning-indicator-dark"
    ]
  end

  defp color_variant("bordered", "danger") do
    [
      "text-danger-bordered-text-light border-danger-bordered-text-light bg-danger-bordered-bg-light",
      "dark:text-danger-bordered-text-dark dark:border-danger-bordered-text-dark dark:bg-danger-bordered-bg-dark",
      "[&>.indicator]:bg-danger-indicator-alt-light dark:[&>.indicator]:bg-danger-indicator-dark"
    ]
  end

  defp color_variant("bordered", "info") do
    [
      "text-info-bordered-text-light border-info-bordered-text-light bg-info-bordered-bg-light",
      "dark:text-info-bordered-text-dark dark:border-info-bordered-text-dark dark:bg-info-bordered-bg-dark",
      "[&>.indicator]:bg-info-indicator-alt-light dark:[&>.indicator]:bg-info-indicator-dark"
    ]
  end

  defp color_variant("bordered", "misc") do
    [
      "text-misc-bordered-text-light border-misc-bordered-text-light bg-misc-bordered-bg-light",
      "dark:text-misc-bordered-text-dark dark:border-misc-bordered-text-dark dark:bg-misc-bordered-bg-dark",
      "[&>.indicator]:bg-misc-indicator-alt-light dark:[&>.indicator]:bg-misc-indicator-dark"
    ]
  end

  defp color_variant("bordered", "dawn") do
    [
      "text-dawn-bordered-text-light border-dawn-bordered-text-light bg-dawn-bordered-bg-light",
      "dark:text-dawn-bordered-text-dark dark:border-dawn-bordered-text-dark dark:bg-dawn-bordered-bg-dark",
      "[&>.indicator]:bg-dawn-indicator-alt-light dark:[&>.indicator]:bg-dawn-indicator-dark"
    ]
  end

  defp color_variant("bordered", "silver") do
    [
      "text-silver-bordered-text-light border-silver-bordered-text-light bg-silver-bordered-bg-light",
      "dark:text-silver-bordered-text-dark dark:border-silver-bordered-text-dark dark:bg-silver-bordered-bg-dark",
      "[&>.indicator]:bg-silver-indicator-alt-light dark:[&>.indicator]:bg-silver-indicator-dark"
    ]
  end

  defp color_variant("gradient", "natural") do
    [
      "bg-gradient-to-br from-gradient-natural-from-light to-gradient-natural-to-light text-white",
      "dark:from-gradient-natural-from-dark dark:to-white dark:text-black",
      "[&>.indicator]:bg-white dark:[&>.indicator]:bg-black"
    ]
  end

  defp color_variant("gradient", "primary") do
    [
      "bg-gradient-to-br from-gradient-primary-from-light to-gradient-primary-to-light text-white",
      "dark:from-gradient-primary-from-dark dark:to-gradient-primary-to-dark dark:text-black",
      "[&>.indicator]:bg-primary-indicator-light dark:[&>.indicator]:bg-primary-gradient-indicator-dark"
    ]
  end

  defp color_variant("gradient", "secondary") do
    [
      "bg-gradient-to-br from-gradient-secondary-from-light to-gradient-secondary-to-light text-white",
      "dark:from-gradient-secondary-from-dark dark:to-gradient-secondary-to-dark dark:text-black",
      "[&>.indicator]:bg-secondary-indicator-light dark:[&>.indicator]:bg-secondary-gradient-indicator-dark"
    ]
  end

  defp color_variant("gradient", "success") do
    [
      "bg-gradient-to-br from-gradient-success-from-light to-gradient-success-to-light text-white",
      "dark:from-gradient-success-from-dark dark:to-gradient-success-to-dark dark:text-black",
      "[&>.indicator]:bg-success-indicator-alt-light dark:[&>.indicator]:bg-success-gradient-indicator-dark"
    ]
  end

  defp color_variant("gradient", "warning") do
    [
      "bg-gradient-to-br from-gradient-warning-from-light to-gradient-warning-to-light text-white",
      "dark:from-gradient-warning-from-dark dark:to-gradient-warning-to-dark dark:text-black",
      "[&>.indicator]:bg-warning-indicator-alt-light dark:[&>.indicator]:bg-warning-gradient-indicator-dark"
    ]
  end

  defp color_variant("gradient", "danger") do
    [
      "bg-gradient-to-br from-gradient-danger-from-light to-gradient-danger-to-light text-white",
      "dark:from-gradient-danger-from-dark dark:to-gradient-danger-to-dark dark:text-black",
      "[&>.indicator]:bg-danger-indicator-alt-light dark:[&>.indicator]:bg-danger-gradient-indicator-dark"
    ]
  end

  defp color_variant("gradient", "info") do
    [
      "bg-gradient-to-br from-gradient-info-from-light to-gradient-info-to-light text-white",
      "dark:from-gradient-info-from-dark dark:to-gradient-info-to-dark dark:text-black",
      "[&>.indicator]:bg-info-indicator-alt-light dark:[&>.indicator]:bg-info-gradient-indicator-dark"
    ]
  end

  defp color_variant("gradient", "misc") do
    [
      "bg-gradient-to-br from-gradient-misc-from-light to-gradient-misc-to-light text-white",
      "dark:from-gradient-misc-from-dark dark:to-gradient-misc-to-dark dark:text-black",
      "[&>.indicator]:bg-misc-indicator-alt-light dark:[&>.indicator]:bg-misc-gradient-indicator-dark"
    ]
  end

  defp color_variant("gradient", "dawn") do
    [
      "bg-gradient-to-br from-gradient-dawn-from-light to-gradient-dawn-to-light text-white",
      "dark:from-gradient-dawn-from-dark dark:to-gradient-dawn-to-dark dark:text-black",
      "[&>.indicator]:bg-dawn-indicator-alt-light dark:[&>.indicator]:bg-dawn-gradient-indicator-dark"
    ]
  end

  defp color_variant("gradient", "silver") do
    [
      "bg-gradient-to-br from-gradient-silver-from-light to-gradient-silver-to-light text-white",
      "dark:from-gradient-silver-from-dark dark:to-gradient-silver-to-dark dark:text-black",
      "[&>.indicator]:bg-natural-light dark:[&>.indicator]:bg-natural-hover-dark"
    ]
  end

  defp color_variant(params, _) when is_binary(params), do: params

  defp rounded_size("extra_small"), do: "rounded-sm"

  defp rounded_size("small"), do: "rounded"

  defp rounded_size("medium"), do: "rounded-md"

  defp rounded_size("large"), do: "rounded-lg"

  defp rounded_size("extra_large"), do: "rounded-xl"

  defp rounded_size("full"), do: "rounded-full"

  defp rounded_size("none"), do: nil

  defp rounded_size(params) when is_binary(params), do: params

  defp border_size(_, variant) when variant in ["default", "shadow", "transparent", "gradient"],
    do: nil

  defp border_size("none", _), do: nil
  defp border_size("extra_small", _), do: "border"
  defp border_size("small", _), do: "border-2"
  defp border_size("medium", _), do: "border-[3px]"
  defp border_size("large", _), do: "border-4"
  defp border_size("extra_large", _), do: "border-[5px]"
  defp border_size(params, _) when is_binary(params), do: params

  defp indicator_size("extra_small"), do: "!size-2"
  defp indicator_size("small"), do: "!size-2.5"
  defp indicator_size("medium"), do: "!size-3"
  defp indicator_size("large"), do: "!size-3.5"
  defp indicator_size("extra_large"), do: "!size-4"
  defp indicator_size(params) when is_binary(params), do: params

  defp size_class("extra_small", circle) do
    [
      is_nil(circle) && "px-2 py-px",
      "text-[12px] [&>.indicator]:size-1",
      !is_nil(circle) && "size-6"
    ]
  end

  defp size_class("small", circle) do
    [
      is_nil(circle) && "px-2.5 py-0.5",
      "text-[13px] [&>.indicator]:size-1.5",
      !is_nil(circle) && "size-7"
    ]
  end

  defp size_class("medium", circle) do
    [
      is_nil(circle) && "px-2.5 py-1",
      "text-[14px] [&>.indicator]:size-2",
      !is_nil(circle) && "size-8"
    ]
  end

  defp size_class("large", circle) do
    [
      is_nil(circle) && "px-3 py-1.5",
      "text-[15px] [&>.indicator]:size-2.5",
      !is_nil(circle) && "size-9"
    ]
  end

  defp size_class("extra_large", circle) do
    [
      is_nil(circle) && "px-3.5 py-2",
      "text-[16px] [&>.indicator]:size-3",
      !is_nil(circle) && "size-10"
    ]
  end

  defp size_class(params, _circle) when is_binary(params), do: [params]

  defp icon_position(nil, _), do: false
  defp icon_position(_icon, %{left_icon: true}), do: "left"
  defp icon_position(_icon, %{right_icon: true}), do: "right"
  defp icon_position(_icon, _), do: "left"

  defp dismiss_position(%{right_dismiss: true}), do: "right"
  defp dismiss_position(%{left_dismiss: true}), do: "left"
  defp dismiss_position(%{dismiss: true}), do: "right"
  defp dismiss_position(_), do: false

  defp default_classes(pinging) do
    [
      "has-[.indicator]:relative inline-flex gap-1.5 justify-center items-center",
      "[&>.indicator]:inline-block [&>.indicator]:shrink-0 [&>.indicator]:rounded-full",
      !is_nil(pinging) && "[&>.indicator]:animate-ping"
    ]
  end

  defp drop_rest(rest) do
    all_rest =
      (["pinging", "circle"] ++ @dismiss_positions ++ @indicator_positions ++ @icon_positions)
      |> Enum.map(&if(is_binary(&1), do: String.to_atom(&1), else: &1))

    Map.drop(rest, all_rest)
  end

  ## JS Commands
  @doc """
  Displays a badge element by applying a transition effect.

  ## Parameters

    - `js`: (optional) An existing `Phoenix.LiveView.JS` structure to apply
    transformations on. Defaults to a new `%JS{}`.
    - `selector`: A string representing the CSS selector of the badge element to be shown.

  ## Returns

    - A `Phoenix.LiveView.JS` structure with commands to show the badge element with a
    smooth transition effect.

  ## Transition Details

    - The element transitions from an initial state of reduced opacity and
    scale (`opacity-0 translate-y-4 sm:translate-y-0 sm:scale-95`) to full opacity
    and scale (`opacity-100 translate-y-0 sm:scale-100`) over a duration of 300 milliseconds.

  ## Example

  ```elixir
  show_badge(%JS{}, "#badge-element")
  ```

  This example will show the badge element with the ID badge-element using the defined transition effect.
  """
  def show_badge(js \\ %JS{}, selector) do
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
  Hides a badge element by applying a transition effect.

  ## Parameters

    - `js`: (optional) An existing `Phoenix.LiveView.JS` structure to apply transformations on.
    Defaults to a new `%JS{}`.
    - `selector`: A string representing the CSS selector of the badge element to be hidden.

  ## Returns

    - A `Phoenix.LiveView.JS` structure with commands to hide the badge element
    with a smooth transition effect.

  ## Transition Details

    - The element transitions from full opacity and scale (`opacity-100 translate-y-0 sm:scale-100`)
    to reduced opacity and scale (`opacity-0 translate-y-4 sm:translate-y-0 sm:scale-95`)
    over a duration of 200 milliseconds.

  ## Example

  ```elixir
  hide_badge(%JS{}, "#badge-element")
  ```

  This example will hide the badge element with the ID badge-element using the defined transition effect.
  """

  def hide_badge(js \\ %JS{}, selector) do
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
