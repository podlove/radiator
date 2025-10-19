defmodule RadiatorWeb.Components.Button do
  @moduledoc """
  Provides a comprehensive set of button components for the `RadiatorWeb.Components.Button` project.
  These components are highly customizable, allowing various styles, sizes, colors,
  and configurations, including buttons with icons, gradients, and different indicator positions.

  ## Components

    - `button/1`: Renders a standard button with extensive customization options.
    - `button_group/1`: Renders a group of buttons with configurable layout and styling.
    - `input_button/1`: Renders a button with input attributes, useful for form submissions.
    - `button_link/1`: Renders a button as a link, supporting different navigation types.
    - `button_indicator/1`: A utility component to render indicators on buttons based on configuration.

  ## Configuration Options

  The module supports various predefined options for attributes like size, color,
  variant, and border style. These can be customized through the attributes of each
  component function to match specific design requirements.

  > This module makes it easy to render buttons with consistent styling and behavior
  > across your application while offering the flexibility needed for various use cases.

  **Documentation:** https://mishka.tools/chelekom/docs/button
  """

  use Phoenix.Component
  import RadiatorWeb.Components.Icon, only: [icon: 1]

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

  @doc """
  The `button_group` component is used to group multiple buttons together with customizable
  attributes like `variant`, `color`, and `variation`.

  It supports different layout orientations, allowing buttons to be displayed horizontally or vertically.

  ## Examples

  ```elixir
  <.button_group>
    <.button icon="hero-adjustments-vertical">Button 1</.button>
    <.button icon="hero-adjustments-vertical" />
    <.button icon="hero-adjustments-vertical" />
    <.button>Button 3</.button>
  </.button_group>

  <.button_group>
    <.button>Button 1</.button>
    <.button>Button 2</.button>
    <.button>Button 3</.button>
    <.button>Button 4</.button>
    <.button>Button 5</.button>
  </.button_group>

  <.button_group color="success">
    <.button icon="hero-adjustments-vertical">Button 1</.button>
    <.button icon="hero-adjustments-vertical" color="success" />
    <.button icon="hero-adjustments-vertical" />
    <.button color="success">Button 3</.button>
  </.button_group>
  ```
  """
  @doc type: :component
  attr :id, :string,
    default: nil,
    doc: "A unique identifier is used to manage state and interaction"

  attr :variation, :string,
    values: ["horizontal", "vertical"],
    default: "horizontal",
    doc: "Defines the layout orientation of the component"

  attr :color, :string, default: "base", doc: "Determines color theme"
  attr :rounded, :string, default: "small", doc: "Determines the border radius"
  attr :class, :string, default: nil, doc: "Custom CSS class for additional styling"

  attr :rest, :global,
    doc:
      "Global attributes can define defaults which are merged with attributes provided by the caller"

  slot :inner_block, required: false, doc: "Inner block that renders HEEx content"

  def button_group(assigns) do
    ~H"""
    <div
      id={@id}
      role="group"
      class={[
        default_classes(:grouped, false),
        variation(@variation),
        rounded_size(@rounded),
        border_class(@color),
        @class
      ]}
      {@rest}
    >
      {render_slot(@inner_block)}
    </div>
    """
  end

  @doc """
  The `button` component is used to create customizable buttons with various styles, icons, and indicators.

  It supports different types such as `button`, `submit`, and `reset`, and provides
  options for configuring size, color, and border radius.

  ## Examples

  ```elixir
  <.button variant="inverted_gradient" color="danger">Button 4</.button>
  <.button variant="inverted_gradient" color="info">Button 2</.button>
  <.button icon="hero-adjustments-vertical" variant="inverted_gradient" color="success"/>
  ```
  """
  @doc type: :component
  attr :id, :string,
    default: nil,
    doc: "A unique identifier is used to manage state and interaction"

  attr :variant, :string, default: "base", doc: "Determines the style"

  attr :type, :any,
    values: ["button", "submit", "reset", nil],
    default: nil,
    doc: "Specifies the type of the element"

  attr :color, :string, default: "base", doc: "Determines color theme"
  attr :rounded, :string, default: "large", doc: "Determines the border radius"
  attr :border, :string, default: "extra_small", doc: "Determines border style"

  attr :size, :string,
    default: "large",
    doc:
      "Determines the overall size of the elements, including padding, font size, and other items"

  attr :content_position, :string,
    default: "center",
    doc: "Determines the alignment of the element's content"

  attr :display, :string,
    default: "inline-flex",
    doc: "Specifies the CSS display property for the element"

  attr :line_height, :string, default: "leading-5", doc: "Line height"
  attr :icon, :string, default: nil, doc: "Icon displayed alongside of an item"
  attr :icon_class, :string, default: nil, doc: "Determines custom class for the icon"

  attr :font_weight, :string,
    default: "font-normal",
    doc: "Determines custom class for the font weight"

  attr :full_width, :boolean, default: false, doc: "Make button full width"

  attr :indicator_class, :string,
    default: nil,
    doc: "Custom CSS class for styling the indicator element"

  attr :indicator_size, :string,
    default: "extra_small",
    doc: "Defines the size of the indicator element"

  attr :class, :string, default: nil, doc: "Custom CSS class for additional styling"
  attr :content_class, :string, default: "block", doc: "Custom CSS class for additional styling"

  attr :rest, :global,
    include:
      ~w(disabled form name value right_icon left_icon pinging circle download) ++
        @indicator_positions,
    doc:
      "Global attributes can define defaults which are merged with attributes provided by the caller"

  slot :inner_block, required: false, doc: "Inner block that renders HEEx content"

  slot :loading, required: false do
    attr :class, :string, doc: "Custom CSS class for additional styling"

    attr :position, :string,
      values: ["start", "end"],
      doc: "Determines the element position"
  end

  def button(assigns) do
    assigns = assign_new(assigns, :indicator, fn -> is_indicators?(assigns[:rest]) end)

    ~H"""
    <button
      type={@type}
      id={@id}
      class={[
        default_classes(@rest[:pinging], @indicator),
        size_class(@size, @rest[:circle]),
        color_variant(@variant, @color, @indicator),
        content_position(@content_position),
        rounded_size(@rounded),
        border_size(@border, @variant),
        @full_width && "w-full",
        @line_height,
        @font_weight,
        @display,
        @class
      ]}
      {drop_rest(@rest)}
    >
      <span
        :for={loading <- @loading}
        :if={is_nil(loading[:position]) || loading[:position] == "start"}
        class={loading[:class]}
      >
        {render_slot(loading)}
      </span>

      <.button_indicator position="left" size={@indicator_size} class={@indicator_class} {@rest} />
      <.icon :if={icon_position(@icon, @rest) == "left"} name={@icon} class={@icon_class} />
      <span :if={@inner_block && render_slot(@inner_block)} class={[@content_class]}>
        {render_slot(@inner_block)}
      </span>
      <.icon :if={icon_position(@icon, @rest) == "right"} name={@icon} class={@icon_class} />
      <.button_indicator size={@indicator_size} class={@indicator_class} {@rest} />

      <span :for={loading <- @loading} :if={loading[:position] == "end"} class={loading[:class]}>
        {render_slot(loading)}
      </span>
    </button>
    """
  end

  @doc """
  The `input_button` component is used to create input elements with button-like styles and various
  customization options such as `color`, `size`, and `border`.

  It supports different input types like `button`, `submit`, and `reset`, allowing for
  flexible usage in forms and interactive elements.

  ## Examples

  ```elixir
  <.input_button value="input button" color="warning" />
  <.input_button value="input submit" type="submit" />
  <.input_button value="input reset" type="reset" color="silver" />
  ```
  """
  @doc type: :component
  attr :id, :string,
    default: nil,
    doc: "A unique identifier is used to manage state and interaction"

  attr :variant, :string, default: "base", doc: "Determines the style"
  attr :color, :string, default: "base", doc: "Determines color theme"
  attr :rounded, :string, default: "large", doc: "Determines the border radius"
  attr :value, :string, default: "", doc: "Value of input"
  attr :border, :string, default: "extra_small", doc: "Determines border style"

  attr :size, :string,
    default: "large",
    doc:
      "Determines the overall size of the elements, including padding, font size, and other items"

  attr :type, :string, default: "button", doc: "Determines type of input"
  attr :line_height, :string, default: "leading-5", doc: "Line height"

  attr :content_position, :string,
    default: "center",
    doc: "Determines the alignment of the element's content"

  attr :display, :string,
    default: "inline-block",
    doc: "Specifies the CSS display property for the element"

  attr :font_weight, :string,
    default: "font-normal",
    doc: "Determines custom class for the font weight"

  attr :full_width, :boolean, default: false, doc: "Make button full width"

  attr :class, :string, default: nil, doc: "Custom CSS class for additional styling"

  attr :rest, :global,
    doc:
      "Global attributes can define defaults which are merged with attributes provided by the caller"

  def input_button(assigns) do
    ~H"""
    <input
      type={@type}
      id={@id}
      value={@value}
      class={[
        default_classes(@rest[:pinging], false),
        size_class(@size, @rest[:circle]),
        color_variant(@variant, @color, false),
        content_position(@content_position),
        rounded_size(@rounded),
        border_size(@border, @variant),
        @full_width && "w-full",
        @font_weight,
        @line_height,
        @display,
        @class
      ]}
      {@rest}
    />
    """
  end

  @doc """
  The `button_link` component is used to create stylized link elements that resemble buttons.

  It supports different navigation methods like `navigate`, `patch`, and `href` along with
  customizable attributes for appearance and behavior.

  ## Examples

  ```elixir
  <.button_link navigate="/admin" icon="hero-adjustments-vertical" />
  <.button_link navigate="/admin">Button 3</.button_link>

  <.button_link navigate="/admin" icon="hero-adjustments-vertical">
    Button 1
  </.button_link>
  ```
  """
  @doc type: :component
  attr :id, :string,
    default: nil,
    doc: "A unique identifier is used to manage state and interaction"

  attr :title, :string, default: nil, doc: "Specifies the title of the element"

  attr :navigate, :string,
    doc: "Defines the path for navigation within the application using a `navigate` attribute."

  attr :patch, :string, doc: "Specifies the path for navigation using a LiveView patch"
  attr :href, :string, doc: "Sets the URL for an external link"
  attr :variant, :string, default: "base", doc: "Determines the style"
  attr :color, :string, default: "base", doc: "Determines color theme"
  attr :rounded, :string, default: "large", doc: ""
  attr :border, :string, default: "extra_small", doc: "Determines border style"

  attr :size, :string,
    default: "large",
    doc:
      "Determines the overall size of the elements, including padding, font size, and other items"

  attr :class, :string, default: nil, doc: "Custom CSS class for additional styling"
  attr :content_class, :string, default: "block", doc: "Custom CSS class for additional styling"

  attr :display, :string,
    default: "inline-flex",
    doc: "Specifies the CSS display property for the element"

  attr :line_height, :string, default: "leading-5", doc: "Line height"
  attr :icon, :string, default: nil, doc: "Icon displayed alongside of an item"
  attr :icon_class, :string, default: nil, doc: "Determines custom class for the icon"

  attr :font_weight, :string,
    default: "font-normal",
    doc: "Determines custom class for the font weight"

  attr :full_width, :boolean, default: false, doc: "Make button full width"

  attr :indicator_class, :string,
    default: nil,
    doc: "Custom CSS class for styling the indicator element"

  attr :indicator_size, :string,
    default: "extra_small",
    doc: "Defines the size of the indicator element"

  attr :rest, :global,
    include:
      ~w(right_icon left_icon pinging circle download hreflang referrerpolicy rel target type csrf_token method replace download) ++
        @indicator_positions,
    doc:
      "Global attributes can define defaults which are merged with attributes provided by the caller"

  slot :inner_block, required: false, doc: "Inner block that renders HEEx content"

  slot :loading, required: false do
    attr :class, :string, doc: "Custom CSS class for additional styling"

    attr :position, :string,
      values: ["start", "end"],
      doc: "Determines the element position"
  end

  def button_link(%{navigate: _navigate} = assigns) do
    assigns = assign_new(assigns, :indicator, fn -> is_indicators?(assigns[:rest]) end)

    ~H"""
    <.link
      navigate={@navigate}
      id={@id}
      class={[
        default_classes(@rest[:pinging], @indicator),
        size_class(@size, @rest[:circle]),
        color_variant(@variant, @color, @indicator),
        rounded_size(@rounded),
        border_size(@border, @variant),
        @full_width && "w-full",
        @font_weight,
        @line_height,
        @display,
        @class
      ]}
      {drop_rest(@rest)}
    >
      <span
        :for={loading <- @loading}
        :if={is_nil(loading[:position]) || loading[:position] == "start"}
        class={loading[:class]}
      >
        {render_slot(loading)}
      </span>

      <.button_indicator position="left" size={@indicator_size} class={@indicator_class} {@rest} />
      <.icon :if={icon_position(@icon, @rest) == "left"} name={@icon} class={@icon_class} />
      <span :if={(@inner_block && render_slot(@inner_block)) || @title} class={[@content_class]}>
        {render_slot(@inner_block) || @title}
      </span>
      <.icon :if={icon_position(@icon, @rest) == "right"} name={@icon} class={@icon_class} />
      <.button_indicator size={@indicator_size} class={@indicator_class} {@rest} />

      <span :for={loading <- @loading} :if={loading[:position] == "end"} class={loading[:class]}>
        {render_slot(loading)}
      </span>
    </.link>
    """
  end

  def button_link(%{patch: _patch} = assigns) do
    assigns = assign_new(assigns, :indicator, fn -> is_indicators?(assigns[:rest]) end)

    ~H"""
    <.link
      patch={@patch}
      id={@id}
      class={[
        default_classes(@rest[:pinging], @indicator),
        size_class(@size, @rest[:circle]),
        color_variant(@variant, @color, @indicator),
        rounded_size(@rounded),
        border_size(@border, @variant),
        @full_width && "w-full",
        @font_weight,
        @line_height,
        @class
      ]}
      {drop_rest(@rest)}
    >
      <span
        :for={loading <- @loading}
        :if={is_nil(loading[:position]) || loading[:position] == "start"}
        class={loading[:class]}
      >
        {render_slot(loading)}
      </span>

      <.button_indicator position="left" size={@indicator_size} class={@indicator_class} {@rest} />
      <.icon :if={icon_position(@icon, @rest) == "left"} name={@icon} />
      <span :if={(@inner_block && render_slot(@inner_block)) || @title} class={[@content_class]}>
        {render_slot(@inner_block) || @title}
      </span>
      <.icon :if={icon_position(@icon, @rest) == "right"} name={@icon} />
      <.button_indicator size={@indicator_size} class={@indicator_class} {@rest} />

      <span :for={loading <- @loading} :if={loading[:position] == "end"} class={loading[:class]}>
        {render_slot(loading)}
      </span>
    </.link>
    """
  end

  def button_link(%{href: _href} = assigns) do
    assigns = assign_new(assigns, :indicator, fn -> is_indicators?(assigns[:rest]) end)

    ~H"""
    <.link
      href={@href}
      id={@id}
      class={[
        default_classes(@rest[:pinging], @indicator),
        size_class(@size, @rest[:circle]),
        color_variant(@variant, @color, @indicator),
        rounded_size(@rounded),
        border_size(@border, @variant),
        @full_width && "w-full",
        @font_weight,
        @line_height,
        @class
      ]}
      {drop_rest(@rest)}
    >
      <span
        :for={loading <- @loading}
        :if={is_nil(loading[:position]) || loading[:position] == "start"}
        class={loading[:class]}
      >
        {render_slot(loading)}
      </span>

      <.button_indicator position="left" size={@indicator_size} class={@indicator_class} {@rest} />
      <.icon :if={icon_position(@icon, @rest) == "left"} name={@icon} />
      <span :if={(@inner_block && render_slot(@inner_block)) || @title} class={[@content_class]}>
        {render_slot(@inner_block) || @title}
      </span>
      <.icon :if={icon_position(@icon, @rest) == "right"} name={@icon} />
      <.button_indicator size={@indicator_size} class={@indicator_class} {@rest} />

      <span :for={loading <- @loading} :if={loading[:position] == "end"} class={loading[:class]}>
        {render_slot(loading)}
      </span>
    </.link>
    """
  end

  @doc """
  Renders a back navigation link.

  ## Examples

      <.back navigate={~p"/posts"}>Back to posts</.back>
  """
  @doc type: :component
  attr :navigate, :any, required: true
  slot :inner_block, required: true

  def back(assigns) do
    ~H"""
    <div class="mt-16">
      <.link
        navigate={@navigate}
        class="text-sm font-semibold leading-6 text-zinc-900 hover:text-zinc-700"
      >
        <.icon name="hero-arrow-left-solid" class="h-3 w-3" />
        {render_slot(@inner_block)}
      </.link>
    </div>
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

  defp button_indicator(%{position: "left", rest: %{left_indicator: true}} = assigns) do
    ~H"""
    <span aria-hidden="true" class={["indicator", indicator_size(@size), @class]} />
    """
  end

  defp button_indicator(%{position: "left", rest: %{indicator: true}} = assigns) do
    ~H"""
    <span aria-hidden="true" class={["indicator", indicator_size(@size), @class]} />
    """
  end

  defp button_indicator(%{position: "none", rest: %{right_indicator: true}} = assigns) do
    ~H"""
    <span aria-hidden="true" class={["indicator", indicator_size(@size), @class]} />
    """
  end

  defp button_indicator(%{position: "none", rest: %{top_left_indicator: true}} = assigns) do
    ~H"""
    <span
      aria-hidden="true"
      class={[
        "indicator",
        indicator_size(@size),
        @class || "absolute -translate-y-1/2 -translate-x-1/2 right-auto top-0 left-0"
      ]}
    />
    """
  end

  defp button_indicator(%{position: "none", rest: %{top_center_indicator: true}} = assigns) do
    ~H"""
    <span
      aria-hidden="true"
      class={[
        "indicator",
        indicator_size(@size),
        @class || "absolute top-0 -translate-y-1/2 translate-x-1/2 right-1/2"
      ]}
    />
    """
  end

  defp button_indicator(%{position: "none", rest: %{top_right_indicator: true}} = assigns) do
    ~H"""
    <span
      aria-hidden="true"
      class={[
        "indicator",
        indicator_size(@size),
        @class || "absolute -translate-y-1/2 translate-x-1/2 left-auto top-0 right-0"
      ]}
    />
    """
  end

  defp button_indicator(%{position: "none", rest: %{middle_left_indicator: true}} = assigns) do
    ~H"""
    <span
      aria-hidden="true"
      class={[
        "indicator",
        indicator_size(@size),
        @class || "absolute -translate-y-1/2 -translate-x-1/2 right-auto left-0 top-2/4"
      ]}
    />
    """
  end

  defp button_indicator(%{position: "none", rest: %{middle_right_indicator: true}} = assigns) do
    ~H"""
    <span
      aria-hidden="true"
      class={[
        "indicator",
        indicator_size(@size),
        @class || "absolute -translate-y-1/2 translate-x-1/2 left-auto right-0 top-2/4"
      ]}
    />
    """
  end

  defp button_indicator(%{position: "none", rest: %{bottom_left_indicator: true}} = assigns) do
    ~H"""
    <span
      aria-hidden="true"
      class={[
        "indicator",
        indicator_size(@size),
        @class || "absolute translate-y-1/2 -translate-x-1/2 right-auto bottom-0 left-0"
      ]}
    />
    """
  end

  defp button_indicator(%{position: "none", rest: %{bottom_center_indicator: true}} = assigns) do
    ~H"""
    <span
      aria-hidden="true"
      class={[
        "indicator",
        indicator_size(@size),
        @class || "absolute translate-y-1/2 translate-x-1/2 bottom-0 right-1/2"
      ]}
    />
    """
  end

  defp button_indicator(%{position: "none", rest: %{bottom_right_indicator: true}} = assigns) do
    ~H"""
    <span
      aria-hidden="true"
      class={[
        "indicator",
        indicator_size(@size),
        @class || "absolute translate-y-1/2 translate-x-1/2 left-auto bottom-0 right-0"
      ]}
    />
    """
  end

  defp button_indicator(assigns) do
    ~H"""
    """
  end

  defp border_size(_, variant)
       when variant in [
              "default",
              "shadow",
              "transparent",
              "subtle",
              "default_gradient",
              "outline_gradient",
              "inverted_gradient"
            ],
       do: nil

  defp border_size("none", _), do: nil
  defp border_size("extra_small", _), do: "border"
  defp border_size("small", _), do: "border-2"
  defp border_size("medium", _), do: "border-[3px]"
  defp border_size("large", _), do: "border-4"
  defp border_size("extra_large", _), do: "border-[5px]"
  defp border_size(params, _) when is_binary(params), do: params

  defp color_variant("base", _, indicator) do
    [
      "bg-white text-base-text-light border-base-border-light hover:bg-base-hover-light",
      "dark:bg-base-bg-dark dark:text-base-text-dark dark:border-base-border-dark dark:hover:bg-base-hover-dark",
      "disabled:bg-base-disabled-bg-light disabled:text-base-disabled-text-light dark:disabled:bg-base-disabled-bg-dark dark:disabled:text-base-disabled-text-dark",
      "disabled:border-base-disabled-border-light dark:disabled:border-base-disabled-border-dark",
      "shadow-sm",
      indicator && "[&>.indicator]:bg-base-border-light dark:[&>.indicator]:bg-base-border-dark"
    ]
  end

  defp color_variant("default", "white", _) do
    ["bg-white text-black"]
  end

  defp color_variant("default", "dark", _) do
    ["bg-default-dark-bg text-white"]
  end

  defp color_variant("default", "natural", indicator) do
    [
      "bg-natural-light text-white hover:bg-natural-hover-light dark:bg-natural-dark",
      "dark:text-black dark:hover:bg-natural-hover-dark",
      "disabled:bg-disabled-bg-light disabled:text-disabled-text-light",
      "dark:disabled:bg-disabled-bg-dark dark:disabled:text-disabled-text-dark",
      indicator && "[&>.indicator]:bg-white dark:[&>.indicator]:bg-black"
    ]
  end

  defp color_variant("default", "primary", indicator) do
    [
      "bg-primary-light text-white hover:bg-primary-hover-light dark:bg-primary-dark",
      "dark:text-black dark:hover:bg-primary-hover-dark",
      "disabled:bg-disabled-bg-light disabled:text-disabled-text-light",
      "dark:disabled:bg-disabled-bg-dark dark:disabled:text-disabled-text-dark",
      indicator &&
        "[&>.indicator]:bg-primary-indicator-light dark:[&>.indicator]:bg-primary-indicator-dark"
    ]
  end

  defp color_variant("default", "secondary", indicator) do
    [
      "bg-secondary-light text-white hover:bg-secondary-hover-light dark:bg-secondary-dark",
      "dark:text-black dark:hover:bg-secondary-hover-dark",
      "disabled:bg-disabled-bg-light disabled:text-disabled-text-light",
      "dark:disabled:bg-disabled-bg-dark dark:disabled:text-disabled-text-dark",
      indicator &&
        "[&>.indicator]:bg-secondary-indicator-light dark:[&>.indicator]:bg-secondary-indicator-dark"
    ]
  end

  defp color_variant("default", "success", indicator) do
    [
      "bg-success-light text-white hover:bg-success-hover-light dark:bg-success-dark",
      "dark:text-black dark:hover:bg-success-hover-dark",
      "disabled:bg-disabled-bg-light disabled:text-disabled-text-light",
      "dark:disabled:bg-disabled-bg-dark dark:disabled:text-disabled-text-dark",
      indicator &&
        "[&>.indicator]:bg-success-indicator-light dark:[&>.indicator]:bg-success-indicator-dark"
    ]
  end

  defp color_variant("default", "warning", indicator) do
    [
      "bg-warning-light text-white hover:bg-warning-hover-light dark:bg-warning-dark",
      "dark:text-black dark:hover:bg-warning-hover-dark",
      "disabled:bg-disabled-bg-light disabled:text-disabled-text-light",
      "dark:disabled:bg-disabled-bg-dark dark:disabled:text-disabled-text-dark",
      indicator &&
        "[&>.indicator]:bg-warning-indicator-light dark:[&>.indicator]:bg-warning-indicator-dark"
    ]
  end

  defp color_variant("default", "danger", indicator) do
    [
      "bg-danger-light text-white hover:bg-danger-hover-light dark:bg-danger-dark",
      "dark:text-black dark:hover:bg-danger-hover-dark",
      "disabled:bg-disabled-bg-light disabled:text-disabled-text-light",
      "dark:disabled:bg-disabled-bg-dark dark:disabled:text-disabled-text-dark",
      indicator &&
        "[&>.indicator]:bg-danger-indicator-light dark:[&>.indicator]:bg-danger-indicator-dark"
    ]
  end

  defp color_variant("default", "info", indicator) do
    [
      "bg-info-light text-white hover:bg-info-hover-light dark:bg-info-dark",
      "dark:text-black dark:hover:bg-info-hover-dark",
      "disabled:bg-disabled-bg-light disabled:text-disabled-text-light",
      "dark:disabled:bg-disabled-bg-dark dark:disabled:text-disabled-text-dark",
      indicator &&
        "[&>.indicator]:bg-info-indicator-light dark:[&>.indicator]:bg-info-indicator-dark"
    ]
  end

  defp color_variant("default", "misc", indicator) do
    [
      "bg-misc-light text-white hover:bg-misc-hover-light dark:bg-misc-dark",
      "dark:text-black dark:hover:bg-misc-hover-dark",
      "disabled:bg-disabled-bg-light disabled:text-disabled-text-light",
      "dark:disabled:bg-disabled-bg-dark dark:disabled:text-disabled-text-dark",
      indicator &&
        "[&>.indicator]:bg-misc-indicator-light dark:[&>.indicator]:bg-misc-indicator-dark"
    ]
  end

  defp color_variant("default", "dawn", indicator) do
    [
      "bg-dawn-light text-white hover:bg-dawn-hover-light dark:bg-dawn-dark",
      "dark:text-black dark:hover:bg-dawn-hover-dark",
      "disabled:bg-disabled-bg-light disabled:text-disabled-text-light",
      "dark:disabled:bg-disabled-bg-dark dark:disabled:text-disabled-text-dark",
      indicator &&
        "[&>.indicator]:bg-dawn-indicator-light dark:[&>.indicator]:bg-dawn-indicator-dark"
    ]
  end

  defp color_variant("default", "silver", indicator) do
    [
      "bg-silver-light text-white hover:bg-silver-hover-light dark:bg-silver-dark",
      "dark:text-black dark:hover:bg-silver-hover-dark",
      "disabled:bg-disabled-bg-light disabled:text-disabled-text-light",
      "dark:disabled:bg-disabled-bg-dark dark:disabled:text-disabled-text-dark",
      indicator &&
        "[&>.indicator]:bg-silver-indicator-light dark:[&>.indicator]:bg-silver-indicator-dark"
    ]
  end

  defp color_variant("outline", "natural", indicator) do
    [
      "bg-transparent text-natural-light border-natural-light hover:text-natural-hover-light",
      "hover:border-natural-hover-light dark:text-natural-dark dark:border-natural-dark",
      "dark:hover:text-natural-hover-dark dark:hover:border-natural-hover-dark disabled:text-natural-disabled-light",
      "disabled:border-natural-disabled-light dark:disabled:text-natural-disabled-dark dark:disabled:border-natural-disabled-dark",
      indicator && "[&>.indicator]:bg-black dark:[&>.indicator]:bg-white"
    ]
  end

  defp color_variant("outline", "primary", indicator) do
    [
      "bg-transparent text-primary-light border-primary-light hover:text-primary-hover-light",
      "hover:border-primary-hover-light dark:text-primary-dark dark:border-primary-dark",
      "dark:hover:text-primary-hover-dark dark:hover:border-primary-hover-dark disabled:text-natural-disabled-light",
      "disabled:border-natural-disabled-light dark:disabled:text-natural-disabled-dark dark:disabled:border-natural-disabled-dark",
      indicator &&
        "[&>.indicator]:bg-primary-indicator-light dark:[&>.indicator]:bg-primary-indicator-dark"
    ]
  end

  defp color_variant("outline", "secondary", indicator) do
    [
      "bg-transparent text-secondary-light border-secondary-light hover:text-secondary-hover-light",
      "hover:border-secondary-hover-light dark:text-secondary-dark dark:border-secondary-dark",
      "dark:hover:text-secondary-hover-dark dark:hover:border-secondary-hover-dark disabled:text-natural-disabled-light",
      "disabled:border-natural-disabled-light dark:disabled:text-natural-disabled-dark dark:disabled:border-natural-disabled-dark",
      indicator &&
        "[&>.indicator]:bg-secondary-indicator-light dark:[&>.indicator]:bg-secondary-indicator-dark"
    ]
  end

  defp color_variant("outline", "success", indicator) do
    [
      "bg-transparent text-success-light border-success-light hover:text-success-hover-light",
      "hover:border-success-hover-light dark:text-success-dark dark:border-success-dark",
      "dark:hover:text-success-hover-dark dark:hover:border-success-hover-dark disabled:text-natural-disabled-light",
      "disabled:border-natural-disabled-light dark:disabled:text-natural-disabled-dark dark:disabled:border-natural-disabled-dark",
      indicator &&
        "[&>.indicator]:bg-success-indicator-alt-light dark:[&>.indicator]:bg-success-indicator-dark"
    ]
  end

  defp color_variant("outline", "warning", indicator) do
    [
      "bg-transparent text-warning-light border-warning-light hover:text-warning-hover-light",
      "hover:border-warning-hover-light dark:text-warning-dark dark:border-warning-dark",
      "dark:hover:text-warning-hover-dark dark:hover:border-warning-hover-dark disabled:text-natural-disabled-light",
      "disabled:border-natural-disabled-light dark:disabled:text-natural-disabled-dark dark:disabled:border-natural-disabled-dark",
      indicator &&
        "[&>.indicator]:bg-warning-indicator-alt-light dark:[&>.indicator]:bg-warning-indicator-dark"
    ]
  end

  defp color_variant("outline", "danger", indicator) do
    [
      "bg-transparent text-danger-light border-danger-light hover:text-danger-hover-light",
      "hover:border-danger-hover-light dark:text-danger-dark dark:border-danger-dark",
      "dark:hover:text-danger-hover-dark dark:hover:border-danger-hover-dark disabled:text-natural-disabled-light",
      "disabled:border-natural-disabled-light dark:disabled:text-natural-disabled-dark dark:disabled:border-natural-disabled-dark",
      indicator &&
        "[&>.indicator]:bg-danger-indicator-alt-light dark:[&>.indicator]:bg-danger-indicator-dark"
    ]
  end

  defp color_variant("outline", "info", indicator) do
    [
      "bg-transparent text-info-light border-info-light hover:text-info-hover-light",
      "hover:border-info-hover-light dark:text-info-dark dark:border-info-dark",
      "dark:hover:text-info-hover-dark dark:hover:border-info-hover-dark disabled:text-natural-disabled-light",
      "disabled:border-natural-disabled-light dark:disabled:text-natural-disabled-dark dark:disabled:border-natural-disabled-dark",
      indicator &&
        "[&>.indicator]:bg-info-indicator-alt-light dark:[&>.indicator]:bg-info-indicator-dark"
    ]
  end

  defp color_variant("outline", "misc", indicator) do
    [
      "bg-transparent text-misc-light border-misc-light hover:text-misc-hover-light",
      "hover:border-misc-hover-light dark:text-misc-dark dark:border-misc-dark",
      "dark:hover:text-misc-hover-dark dark:hover:border-misc-hover-dark disabled:text-natural-disabled-light",
      "disabled:border-natural-disabled-light dark:disabled:text-natural-disabled-dark dark:disabled:border-natural-disabled-dark",
      indicator &&
        "[&>.indicator]:bg-misc-indicator-alt-light dark:[&>.indicator]:bg-misc-indicator-dark"
    ]
  end

  defp color_variant("outline", "dawn", indicator) do
    [
      "bg-transparent text-dawn-light border-dawn-light hover:text-dawn-hover-light",
      "hover:border-dawn-hover-light dark:text-dawn-dark dark:border-dawn-dark",
      "dark:hover:text-dawn-hover-dark dark:hover:border-dawn-hover-dark disabled:text-natural-disabled-light",
      "disabled:border-natural-disabled-light dark:disabled:text-natural-disabled-dark dark:disabled:border-natural-disabled-dark",
      indicator &&
        "[&>.indicator]:bg-dawn-indicator-alt-light dark:[&>.indicator]:bg-dawn-indicator-dark"
    ]
  end

  defp color_variant("outline", "silver", indicator) do
    [
      "bg-transparent text-silver-light border-silver-light hover:text-silver-hover-light",
      "hover:border-silver-hover-light dark:text-silver-dark dark:border-silver-dark",
      "dark:hover:text-silver-hover-dark dark:hover:border-silver-hover-dark disabled:text-natural-disabled-light",
      "disabled:border-natural-disabled-light dark:disabled:text-natural-disabled-dark dark:disabled:border-natural-disabled-dark",
      indicator &&
        "[&>.indicator]:bg-silver-indicator-alt-light dark:[&>.indicator]:bg-silver-indicator-dark"
    ]
  end

  defp color_variant("transparent", "natural", indicator) do
    [
      "bg-transparent text-natural-light hover:text-natural-hover-light",
      "dark:text-natural-dark dark:hover:text-natural-hover-dark",
      "disabled:text-natural-disabled-light dark:disabled:text-natural-disabled-dark",
      indicator && "[&>.indicator]:bg-black dark:[&>.indicator]:bg-white"
    ]
  end

  defp color_variant("transparent", "primary", indicator) do
    [
      "bg-transparent text-primary-light hover:text-primary-hover-light",
      "dark:text-primary-dark dark:hover:text-primary-hover-dark",
      "disabled:text-natural-disabled-light dark:disabled:text-natural-disabled-dark",
      indicator &&
        "[&>.indicator]:bg-primary-indicator-light dark:[&>.indicator]:bg-primary-indicator-dark"
    ]
  end

  defp color_variant("transparent", "secondary", indicator) do
    [
      "bg-transparent text-secondary-light hover:text-secondary-hover-light",
      "dark:text-secondary-dark dark:hover:text-secondary-hover-dark",
      "disabled:text-natural-disabled-light dark:disabled:text-natural-disabled-dark",
      indicator &&
        "[&>.indicator]:bg-secondary-indicator-light dark:[&>.indicator]:bg-secondary-indicator-dark"
    ]
  end

  defp color_variant("transparent", "success", indicator) do
    [
      "bg-transparent text-success-light hover:text-success-hover-light",
      "dark:text-success-dark dark:hover:text-success-hover-dark",
      "disabled:text-natural-disabled-light dark:disabled:text-natural-disabled-dark",
      indicator &&
        "[&>.indicator]:bg-success-indicator-alt-light dark:[&>.indicator]:bg-success-indicator-dark"
    ]
  end

  defp color_variant("transparent", "warning", indicator) do
    [
      "bg-transparent text-warning-light hover:text-warning-hover-light",
      "dark:text-warning-dark dark:hover:text-warning-hover-dark",
      "disabled:text-natural-disabled-light dark:disabled:text-natural-disabled-dark",
      indicator &&
        "[&>.indicator]:bg-warning-indicator-alt-light dark:[&>.indicator]:bg-warning-indicator-dark"
    ]
  end

  defp color_variant("transparent", "danger", indicator) do
    [
      "bg-transparent text-danger-light hover:text-danger-hover-light",
      "dark:text-danger-dark dark:hover:text-danger-hover-dark",
      "disabled:text-natural-disabled-light dark:disabled:text-natural-disabled-dark",
      indicator &&
        "[&>.indicator]:bg-danger-indicator-alt-light dark:[&>.indicator]:bg-danger-indicator-dark"
    ]
  end

  defp color_variant("transparent", "info", indicator) do
    [
      "bg-transparent text-info-light hover:text-info-hover-light",
      "dark:text-info-dark dark:hover:text-info-hover-dark",
      "disabled:text-natural-disabled-light dark:disabled:text-natural-disabled-dark",
      indicator &&
        "[&>.indicator]:bg-info-indicator-alt-light dark:[&>.indicator]:bg-info-indicator-dark"
    ]
  end

  defp color_variant("transparent", "misc", indicator) do
    [
      "bg-transparent text-misc-light hover:text-misc-hover-light",
      "dark:text-misc-dark dark:hover:text-misc-hover-dark",
      "disabled:text-natural-disabled-light dark:disabled:text-natural-disabled-dark",
      indicator &&
        "[&>.indicator]:bg-misc-indicator-alt-light dark:[&>.indicator]:bg-misc-indicator-dark"
    ]
  end

  defp color_variant("transparent", "dawn", indicator) do
    [
      "bg-transparent text-dawn-light hover:text-dawn-hover-light",
      "dark:text-dawn-dark dark:hover:text-dawn-hover-dark",
      "disabled:text-natural-disabled-light dark:disabled:text-natural-disabled-dark",
      indicator &&
        "[&>.indicator]:bg-dawn-indicator-alt-light dark:[&>.indicator]:bg-dawn-indicator-dark"
    ]
  end

  defp color_variant("transparent", "silver", indicator) do
    [
      "bg-transparent text-silver-light hover:text-silver-hover-light",
      "dark:text-silver-dark dark:hover:text-silver-hover-dark",
      "disabled:text-natural-disabled-light dark:disabled:text-natural-disabled-dark",
      indicator &&
        "[&>.indicator]:bg-silver-indicator-alt-light dark:[&>.indicator]:bg-silver-indicator-dark"
    ]
  end

  defp color_variant("subtle", "natural", indicator) do
    [
      "bg-transparent text-natural-light hover:text-natural-hover-light hover:bg-natural-bg-light",
      "dark:text-natural-dark dark:hover:text-natural-hover-dark dark:hover:bg-natural-bg-dark",
      "disabled:text-natural-disabled-light dark:disabled:text-natural-disabled-dark",
      "disabled:hover:bg-transparent dark:disabled:hover:bg-transparent",
      indicator && "[&>.indicator]:bg-black dark:[&>.indicator]:bg-white"
    ]
  end

  defp color_variant("subtle", "primary", indicator) do
    [
      "bg-transparent text-primary-light hover:text-primary-hover-light hover:bg-primary-bordered-bg-light",
      "dark:text-primary-dark dark:hover:text-primary-hover-dark dark:hover:bg-primary-bordered-bg-dark",
      "disabled:text-natural-disabled-light dark:disabled:text-natural-disabled-dark",
      "disabled:hover:bg-transparent dark:disabled:hover:bg-transparent",
      indicator &&
        "[&>.indicator]:bg-primary-indicator-light dark:[&>.indicator]:bg-primary-indicator-dark"
    ]
  end

  defp color_variant("subtle", "secondary", indicator) do
    [
      "bg-transparent text-secondary-light hover:text-secondary-hover-light hover:bg-secondary-bordered-bg-light",
      "dark:text-secondary-dark dark:hover:text-secondary-hover-dark dark:hover:bg-secondary-bordered-bg-dark",
      "disabled:text-natural-disabled-light dark:disabled:text-natural-disabled-dark",
      "disabled:hover:bg-transparent dark:disabled:hover:bg-transparent",
      indicator &&
        "[&>.indicator]:bg-secondary-indicator-light dark:[&>.indicator]:bg-secondary-indicator-dark"
    ]
  end

  defp color_variant("subtle", "success", indicator) do
    [
      "bg-transparent text-success-light hover:text-success-hover-light hover:bg-success-bordered-bg-light",
      "dark:text-success-dark dark:hover:text-success-hover-dark dark:hover:bg-success-bordered-bg-dark",
      "disabled:text-natural-disabled-light dark:disabled:text-natural-disabled-dark",
      "disabled:hover:bg-transparent dark:disabled:hover:bg-transparent",
      indicator &&
        "[&>.indicator]:bg-success-indicator-alt-light dark:[&>.indicator]:bg-success-indicator-dark"
    ]
  end

  defp color_variant("subtle", "warning", indicator) do
    [
      "bg-transparent text-warning-light hover:text-warning-hover-light hover:bg-warning-bordered-bg-light",
      "dark:text-warning-dark dark:hover:text-warning-hover-dark dark:hover:bg-warning-bordered-bg-dark",
      "disabled:text-natural-disabled-light dark:disabled:text-natural-disabled-dark",
      "disabled:hover:bg-transparent dark:disabled:hover:bg-transparent",
      indicator &&
        "[&>.indicator]:bg-warning-indicator-alt-light dark:[&>.indicator]:bg-warning-indicator-dark"
    ]
  end

  defp color_variant("subtle", "danger", indicator) do
    [
      "bg-transparent text-danger-light hover:text-danger-hover-light hover:bg-danger-bordered-bg-light",
      "dark:text-danger-dark dark:hover:text-danger-hover-dark dark:hover:bg-danger-bordered-bg-dark",
      "disabled:text-natural-disabled-light dark:disabled:text-natural-disabled-dark",
      "disabled:hover:bg-transparent dark:disabled:hover:bg-transparent",
      indicator &&
        "[&>.indicator]:bg-danger-indicator-alt-light dark:[&>.indicator]:bg-danger-indicator-dark"
    ]
  end

  defp color_variant("subtle", "info", indicator) do
    [
      "bg-transparent text-info-light hover:text-info-hover-light hover:bg-info-bordered-bg-light",
      "dark:text-info-dark dark:hover:text-info-hover-dark dark:hover:bg-info-bordered-bg-dark",
      "disabled:text-natural-disabled-light dark:disabled:text-natural-disabled-dark",
      "disabled:hover:bg-transparent dark:disabled:hover:bg-transparent",
      indicator &&
        "[&>.indicator]:bg-info-indicator-alt-light dark:[&>.indicator]:bg-info-indicator-dark"
    ]
  end

  defp color_variant("subtle", "misc", indicator) do
    [
      "bg-transparent text-misc-light hover:text-misc-hover-light hover:bg-misc-bordered-bg-light",
      "dark:text-misc-dark dark:hover:text-misc-hover-dark dark:hover:bg-misc-bordered-bg-dark",
      "disabled:text-natural-disabled-light dark:disabled:text-natural-disabled-dark",
      "disabled:hover:bg-transparent dark:disabled:hover:bg-transparent",
      indicator &&
        "[&>.indicator]:bg-misc-indicator-alt-light dark:[&>.indicator]:bg-misc-indicator-dark"
    ]
  end

  defp color_variant("subtle", "dawn", indicator) do
    [
      "bg-transparent text-dawn-light hover:text-dawn-hover-light hover:bg-dawn-bordered-bg-light",
      "dark:text-dawn-dark dark:hover:text-dawn-hover-dark dark:hover:bg-dawn-bordered-bg-dark",
      "disabled:text-natural-disabled-light dark:disabled:text-natural-disabled-dark",
      "disabled:hover:bg-transparent dark:disabled:hover:bg-transparent",
      indicator &&
        "[&>.indicator]:bg-dawn-indicator-alt-light dark:[&>.indicator]:bg-dawn-indicator-dark"
    ]
  end

  defp color_variant("subtle", "silver", indicator) do
    [
      "bg-transparent text-silver-light hover:text-silver-hover-light hover:bg-silver-bordered-bg-light",
      "dark:text-silver-dark dark:hover:text-silver-hover-dark dark:hover:bg-silver-bordered-bg-dark",
      "disabled:text-natural-disabled-light dark:disabled:text-natural-disabled-dark",
      "disabled:hover:bg-transparent dark:disabled:hover:bg-transparent",
      indicator &&
        "[&>.indicator]:bg-silver-indicator-alt-light dark:[&>.indicator]:bg-silver-indicator-dark"
    ]
  end

  defp color_variant("bordered", "natural", indicator) do
    [
      "bg-white dark:bg-bordered-dark-bg text-natural-light border-natural-light hover:text-natural-hover-light",
      "hover:border-natural-hover-light dark:text-natural-dark dark:border-natural-dark",
      "dark:hover:text-natural-hover-dark dark:hover:border-natural-hover-dark disabled:text-natural-disabled-light",
      "disabled:border-natural-disabled-light dark:disabled:text-natural-disabled-dark dark:disabled:border-natural-disabled-dark",
      indicator && "[&>.indicator]:bg-black dark:[&>.indicator]:bg-white"
    ]
  end

  defp color_variant("bordered", "primary", indicator) do
    [
      "bg-white dark:bg-bordered-dark-bg text-primary-light border-primary-light hover:text-primary-hover-light",
      "hover:border-primary-hover-light dark:text-primary-dark dark:border-primary-dark",
      "dark:hover:text-primary-hover-dark dark:hover:border-primary-hover-dark disabled:text-natural-disabled-light",
      "disabled:border-natural-disabled-light dark:disabled:text-natural-disabled-dark dark:disabled:border-natural-disabled-dark",
      indicator &&
        "[&>.indicator]:bg-primary-indicator-light dark:[&>.indicator]:bg-primary-indicator-dark"
    ]
  end

  defp color_variant("bordered", "secondary", indicator) do
    [
      "bg-white dark:bg-bordered-dark-bg text-secondary-light border-secondary-light hover:text-secondary-hover-light",
      "hover:border-secondary-hover-light dark:text-secondary-dark dark:border-secondary-dark",
      "dark:hover:text-secondary-hover-dark dark:hover:border-secondary-hover-dark disabled:text-natural-disabled-light",
      "disabled:border-natural-disabled-light dark:disabled:text-natural-disabled-dark dark:disabled:border-natural-disabled-dark",
      indicator &&
        "[&>.indicator]:bg-secondary-indicator-light dark:[&>.indicator]:bg-secondary-indicator-dark"
    ]
  end

  defp color_variant("bordered", "success", indicator) do
    [
      "bg-white dark:bg-bordered-dark-bg text-success-light border-success-light hover:text-success-hover-light",
      "hover:border-success-hover-light dark:text-success-dark dark:border-success-dark",
      "dark:hover:text-success-hover-dark dark:hover:border-success-hover-dark disabled:text-natural-disabled-light",
      "disabled:border-natural-disabled-light dark:disabled:text-natural-disabled-dark dark:disabled:border-natural-disabled-dark",
      indicator &&
        "[&>.indicator]:bg-success-indicator-alt-light dark:[&>.indicator]:bg-success-indicator-dark"
    ]
  end

  defp color_variant("bordered", "warning", indicator) do
    [
      "bg-white dark:bg-bordered-dark-bg text-warning-light border-warning-light hover:text-warning-hover-light",
      "hover:border-warning-hover-light dark:text-warning-dark dark:border-warning-dark",
      "dark:hover:text-warning-hover-dark dark:hover:border-warning-hover-dark disabled:text-natural-disabled-light",
      "disabled:border-natural-disabled-light dark:disabled:text-natural-disabled-dark dark:disabled:border-natural-disabled-dark",
      indicator &&
        "[&>.indicator]:bg-warning-indicator-alt-light dark:[&>.indicator]:bg-warning-indicator-dark"
    ]
  end

  defp color_variant("bordered", "danger", indicator) do
    [
      "bg-white dark:bg-bordered-dark-bg text-danger-light border-danger-light hover:text-danger-hover-light",
      "hover:border-danger-hover-light dark:text-danger-dark dark:border-danger-dark",
      "dark:hover:text-danger-hover-dark dark:hover:border-danger-hover-dark disabled:text-natural-disabled-light",
      "disabled:border-natural-disabled-light dark:disabled:text-natural-disabled-dark dark:disabled:border-natural-disabled-dark",
      indicator &&
        "[&>.indicator]:bg-danger-indicator-alt-light dark:[&>.indicator]:bg-danger-indicator-dark"
    ]
  end

  defp color_variant("bordered", "info", indicator) do
    [
      "bg-white dark:bg-bordered-dark-bg text-info-light border-info-light hover:text-info-hover-light",
      "hover:border-info-light dark:text-info-dark dark:border-info-dark",
      "dark:hover:text-info-hover-dark dark:hover:border-info-hover-dark disabled:text-natural-disabled-light",
      "disabled:border-natural-disabled-light dark:disabled:text-natural-disabled-dark dark:disabled:border-natural-disabled-dark",
      indicator &&
        "[&>.indicator]:bg-info-indicator-alt-light dark:[&>.indicator]:bg-info-indicator-dark"
    ]
  end

  defp color_variant("bordered", "misc", indicator) do
    [
      "bg-white dark:bg-bordered-dark-bg text-misc-light border-misc-light hover:text-misc-hover-light",
      "hover:border-misc-hover-light dark:text-misc-dark dark:border-misc-dark",
      "dark:hover:text-misc-hover-dark dark:hover:border-misc-hover-dark disabled:text-natural-disabled-light",
      "disabled:border-natural-disabled-light dark:disabled:text-natural-disabled-dark dark:disabled:border-natural-disabled-dark",
      indicator &&
        "[&>.indicator]:bg-misc-indicator-alt-light dark:[&>.indicator]:bg-misc-indicator-dark"
    ]
  end

  defp color_variant("bordered", "dawn", indicator) do
    [
      "bg-white dark:bg-bordered-dark-bg text-dawn-light border-dawn-light hover:text-dawn-hover-light",
      "hover:border-dawn-hover-light dark:text-dawn-dark dark:border-dawn-dark",
      "dark:hover:text-dawn-hover-dark dark:hover:border-dawn-hover-dark disabled:text-natural-disabled-light",
      "disabled:border-natural-disabled-light dark:disabled:text-natural-disabled-dark dark:disabled:border-natural-disabled-dark",
      indicator &&
        "[&>.indicator]:bg-dawn-indicator-alt-light dark:[&>.indicator]:bg-dawn-indicator-dark"
    ]
  end

  defp color_variant("bordered", "silver", indicator) do
    [
      "bg-white dark:bg-bordered-dark-bg text-silver-light border-silver-light hover:text-silver-hover-light",
      "hover:border-silver-hover-light dark:text-silver-dark dark:border-silver-dark",
      "dark:hover:text-silver-hover-dark dark:hover:border-silver-hover-dark disabled:text-natural-disabled-light",
      "disabled:border-natural-disabled-light dark:disabled:text-natural-disabled-dark dark:disabled:border-natural-disabled-dark",
      indicator &&
        "[&>.indicator]:bg-silver-indicator-alt-light dark:[&>.indicator]:bg-silver-indicator-dark"
    ]
  end

  defp color_variant("shadow", "natural", indicator) do
    [
      "bg-natural-light text-white hover:bg-natural-hover-light dark:bg-natural-dark",
      "dark:text-black dark:hover:bg-natural-hover-dark disabled:bg-disabled-bg-light disabled:text-disabled-text-light",
      "dark:disabled:bg-disabled-bg-dark dark:disabled:text-disabled-text-dark",
      "shadow-[0px_4px_6px_-4px_var(--color-shadow-natural)] shadow-[0px_10px_15px_-3px_var(--color-shadow-natural)] dark:shadow-none",
      indicator && "[&>.indicator]:bg-white dark:[&>.indicator]:bg-black"
    ]
  end

  defp color_variant("shadow", "primary", indicator) do
    [
      "bg-primary-light text-white hover:bg-primary-hover-light dark:bg-primary-dark",
      "dark:text-black dark:hover:bg-primary-hover-dark disabled:bg-disabled-bg-light disabled:text-disabled-text-light",
      "dark:disabled:bg-disabled-bg-dark dark:disabled:text-disabled-text-dark",
      "shadow-[0px_4px_6px_-4px_var(--color-shadow-primary)] shadow-[0px_10px_15px_-3px_var(--color-shadow-primary)] dark:shadow-none",
      indicator &&
        "[&>.indicator]:bg-primary-indicator-light dark:[&>.indicator]:bg-primary-indicator-dark"
    ]
  end

  defp color_variant("shadow", "secondary", indicator) do
    [
      "bg-secondary-light text-white hover:bg-secondary-hover-light dark:bg-secondary-dark",
      "dark:text-black dark:hover:bg-secondary-hover-dark disabled:bg-disabled-bg-light disabled:text-disabled-text-light",
      "dark:disabled:bg-disabled-bg-dark dark:disabled:text-disabled-text-dark",
      "shadow-[0px_4px_6px_-4px_var(--color-shadow-secondary)] shadow-[0px_10px_15px_-3px_var(--color-shadow-secondary)] dark:shadow-none",
      indicator &&
        "[&>.indicator]:bg-secondary-indicator-light dark:[&>.indicator]:bg-secondary-indicator-dark"
    ]
  end

  defp color_variant("shadow", "success", indicator) do
    [
      "bg-success-light text-white hover:bg-success-hover-light dark:bg-success-dark",
      "dark:text-black dark:hover:bg-success-hover-dark disabled:bg-disabled-bg-light disabled:text-disabled-text-light",
      "dark:disabled:bg-disabled-bg-dark dark:disabled:text-disabled-text-dark",
      "shadow-[0px_4px_6px_-4px_var(--color-shadow-success)] shadow-[0px_10px_15px_-3px_var(--color-shadow-success)] dark:shadow-none",
      indicator &&
        "[&>.indicator]:bg-success-indicator-light dark:[&>.indicator]:bg-success-indicator-dark"
    ]
  end

  defp color_variant("shadow", "warning", indicator) do
    [
      "bg-warning-light text-white hover:bg-warning-hover-light dark:bg-warning-dark",
      "dark:text-black dark:hover:bg-warning-hover-dark disabled:bg-disabled-bg-light disabled:text-disabled-text-light",
      "dark:disabled:bg-disabled-bg-dark dark:disabled:text-disabled-text-dark",
      "shadow-[0px_4px_6px_-4px_var(--color-shadow-warning)] shadow-[0px_10px_15px_-3px_var(--color-shadow-warning)] dark:shadow-none",
      indicator &&
        "[&>.indicator]:bg-warning-indicator-light dark:[&>.indicator]:bg-warning-indicator-dark"
    ]
  end

  defp color_variant("shadow", "danger", indicator) do
    [
      "bg-danger-light text-white hover:bg-danger-hover-light dark:bg-danger-dark",
      "dark:text-black dark:hover:bg-danger-hover-dark disabled:bg-disabled-bg-light disabled:text-disabled-text-light",
      "dark:disabled:bg-disabled-bg-dark dark:disabled:text-disabled-text-dark",
      "shadow-[0px_4px_6px_-4px_var(--color-shadow-danger)] shadow-[0px_10px_15px_-3px_var(--color-shadow-danger)] dark:shadow-none",
      indicator &&
        "[&>.indicator]:bg-danger-indicator-light dark:[&>.indicator]:bg-danger-indicator-dark"
    ]
  end

  defp color_variant("shadow", "info", indicator) do
    [
      "bg-info-light text-white hover:bg-info-hover-light dark:bg-info-dark",
      "dark:text-black dark:hover:bg-info-hover-dark disabled:bg-disabled-bg-light disabled:text-disabled-text-light",
      "dark:disabled:bg-disabled-bg-dark dark:disabled:text-disabled-text-dark",
      "shadow-[0px_4px_6px_-4px_var(--color-shadow-info)] shadow-[0px_10px_15px_-3px_var(--color-shadow-info)] dark:shadow-none",
      indicator &&
        "[&>.indicator]:bg-info-indicator-light dark:[&>.indicator]:bg-info-indicator-dark"
    ]
  end

  defp color_variant("shadow", "misc", indicator) do
    [
      "bg-misc-light text-white hover:bg-misc-hover-light dark:bg-misc-dark",
      "dark:text-black dark:hover:bg-misc-hover-dark disabled:bg-disabled-bg-light disabled:text-disabled-text-light",
      "dark:disabled:bg-disabled-bg-dark dark:disabled:text-disabled-text-dark",
      "shadow-[0px_4px_6px_-4px_var(--color-shadow-misc)] shadow-[0px_10px_15px_-3px_var(--color-shadow-misc)] dark:shadow-none",
      indicator &&
        "[&>.indicator]:bg-misc-indicator-light dark:[&>.indicator]:bg-misc-indicator-dark"
    ]
  end

  defp color_variant("shadow", "dawn", indicator) do
    [
      "bg-dawn-light text-white hover:bg-dawn-hover-light dark:bg-dawn-dark",
      "dark:text-black dark:hover:bg-dawn-hover-dark disabled:bg-disabled-bg-light disabled:text-disabled-text-light",
      "dark:disabled:bg-disabled-bg-dark dark:disabled:text-disabled-text-dark",
      "shadow-[0px_4px_6px_-4px_var(--color-shadow-dawn)] shadow-[0px_10px_15px_-3px_var(--color-shadow-dawn)] dark:shadow-none",
      indicator &&
        "[&>.indicator]:bg-dawn-indicator-light dark:[&>.indicator]:bg-dawn-indicator-dark"
    ]
  end

  defp color_variant("shadow", "silver", indicator) do
    [
      "bg-silver-light text-white hover:bg-silver-hover-light dark:bg-silver-dark",
      "dark:text-black dark:hover:bg-silver-hover-dark disabled:bg-disabled-bg-light disabled:text-disabled-text-light",
      "dark:disabled:bg-disabled-bg-dark dark:disabled:text-disabled-text-dark",
      "shadow-[0px_4px_6px_-4px_var(--color-shadow-silver)] shadow-[0px_10px_15px_-3px_var(--color-shadow-silver)] dark:shadow-none",
      indicator &&
        "[&>.indicator]:bg-silver-indicator-light dark:[&>.indicator]:bg-silver-indicator-dark"
    ]
  end

  defp color_variant("inverted", "natural", indicator) do
    [
      "bg-transparent text-natural-light border-natural-light hover:text-natural-hover-light",
      "hover:border-natural-hover-light hover:bg-natural-bg-light",
      "dark:text-natural-dark dark:border-natural-dark dark:hover:text-natural-hover-dark",
      "dark:hover:border-natural-hover-dark dark:hover:bg-natural-bg-dark disabled:text-natural-disabled-light",
      "disabled:border-natural-disabled-light dark:disabled:text-natural-disabled-dark dark:disabled:border-natural-disabled-dark",
      "disabled:hover:bg-transparent dark:disabled:hover:bg-transparent",
      indicator && "[&>.indicator]:bg-black dark:[&>.indicator]:bg-white"
    ]
  end

  defp color_variant("inverted", "primary", indicator) do
    [
      "bg-transparent text-primary-light border-primary-light hover:text-primary-hover-light",
      "hover:border-primary-hover-light hover:bg-primary-bordered-bg-light",
      "dark:text-primary-dark dark:border-primary-dark dark:hover:text-primary-hover-dark",
      "dark:hover:border-primary-hover-dark dark:hover:bg-primary-bordered-bg-dark disabled:text-natural-disabled-light",
      "disabled:border-natural-disabled-light dark:disabled:text-natural-disabled-dark dark:disabled:border-natural-disabled-dark",
      "disabled:hover:bg-transparent dark:disabled:hover:bg-transparent",
      indicator &&
        "[&>.indicator]:bg-primary-indicator-light dark:[&>.indicator]:bg-primary-indicator-dark"
    ]
  end

  defp color_variant("inverted", "secondary", indicator) do
    [
      "bg-transparent text-secondary-light border-secondary-light hover:text-secondary-hover-light",
      "hover:border-secondary-hover-light hover:bg-secondary-bordered-bg-light",
      "dark:text-secondary-dark dark:border-secondary-dark dark:hover:text-secondary-hover-dark",
      "dark:hover:border-secondary-hover-dark dark:hover:bg-secondary-bordered-bg-dark disabled:text-natural-disabled-light",
      "disabled:border-natural-disabled-light dark:disabled:text-natural-disabled-dark dark:disabled:border-natural-disabled-dark",
      "disabled:hover:bg-transparent dark:disabled:hover:bg-transparent",
      indicator &&
        "[&>.indicator]:bg-secondary-indicator-light dark:[&>.indicator]:bg-secondary-indicator-dark"
    ]
  end

  defp color_variant("inverted", "success", indicator) do
    [
      "bg-transparent text-success-light border-success-light hover:text-success-hover-light",
      "hover:border-success-hover-light hover:bg-success-bordered-bg-light",
      "dark:text-success-dark dark:border-success-dark dark:hover:text-success-hover-dark",
      "dark:hover:border-success-hover-dark dark:hover:bg-success-bordered-bg-dark disabled:text-natural-disabled-light",
      "disabled:border-natural-disabled-light dark:disabled:text-natural-disabled-dark dark:disabled:border-natural-disabled-dark",
      "disabled:hover:bg-transparent dark:disabled:hover:bg-transparent",
      indicator &&
        "[&>.indicator]:bg-success-indicator-alt-light dark:[&>.indicator]:bg-success-indicator-dark"
    ]
  end

  defp color_variant("inverted", "warning", indicator) do
    [
      "bg-transparent text-warning-light border-warning-light hover:text-warning-hover-light",
      "hover:border-warning-hover-light hover:bg-warning-bordered-bg-light",
      "dark:text-warning-dark dark:border-warning-dark dark:hover:text-warning-hover-dark",
      "dark:hover:border-warning-hover-dark dark:hover:bg-warning-bordered-bg-dark disabled:text-natural-disabled-light",
      "disabled:border-natural-disabled-light dark:disabled:text-natural-disabled-dark dark:disabled:border-natural-disabled-dark",
      "disabled:hover:bg-transparent dark:disabled:hover:bg-transparent",
      indicator &&
        "[&>.indicator]:bg-warning-indicator-alt-light dark:[&>.indicator]:bg-warning-indicator-dark"
    ]
  end

  defp color_variant("inverted", "danger", indicator) do
    [
      "bg-transparent text-danger-light border-danger-light hover:text-danger-hover-light",
      "hover:border-danger-hover-light hover:bg-danger-bordered-bg-light",
      "dark:text-danger-dark dark:border-danger-dark dark:hover:text-danger-hover-dark",
      "dark:hover:border-danger-hover-dark dark:hover:bg-danger-bordered-bg-dark disabled:text-natural-disabled-light",
      "disabled:border-natural-disabled-light dark:disabled:text-natural-disabled-dark dark:disabled:border-natural-disabled-dark",
      "disabled:hover:bg-transparent dark:disabled:hover:bg-transparent",
      indicator &&
        "[&>.indicator]:bg-danger-indicator-alt-light dark:[&>.indicator]:bg-danger-indicator-dark"
    ]
  end

  defp color_variant("inverted", "info", indicator) do
    [
      "bg-transparent text-info-light border-info-light hover:text-info-hover-light",
      "hover:border-info-light hover:bg-info-bordered-bg-light",
      "dark:text-info-dark dark:border-info-dark dark:hover:text-info-hover-dark",
      "dark:hover:border-info-hover-dark dark:hover:bg-info-bordered-bg-dark disabled:text-natural-disabled-light",
      "disabled:border-natural-disabled-light dark:disabled:text-natural-disabled-dark dark:disabled:border-natural-disabled-dark",
      "disabled:hover:bg-transparent dark:disabled:hover:bg-transparent",
      indicator &&
        "[&>.indicator]:bg-info-indicator-alt-light dark:[&>.indicator]:bg-info-indicator-dark"
    ]
  end

  defp color_variant("inverted", "misc", indicator) do
    [
      "bg-transparent text-misc-light border-misc-light hover:text-misc-hover-light",
      "hover:border-misc-hover-light hover:bg-misc-bordered-bg-light",
      "dark:text-misc-dark dark:border-misc-dark dark:hover:text-misc-hover-dark",
      "dark:hover:border-misc-hover-dark dark:hover:bg-misc-bordered-bg-dark disabled:text-natural-disabled-light",
      "disabled:border-natural-disabled-light dark:disabled:text-natural-disabled-dark dark:disabled:border-natural-disabled-dark",
      "disabled:hover:bg-transparent dark:disabled:hover:bg-transparent",
      indicator &&
        "[&>.indicator]:bg-misc-indicator-alt-light dark:[&>.indicator]:bg-misc-indicator-dark"
    ]
  end

  defp color_variant("inverted", "dawn", indicator) do
    [
      "bg-transparent text-dawn-light border-dawn-light hover:text-dawn-hover-light",
      "hover:border-dawn-hover-light hover:bg-dawn-bordered-bg-light",
      "dark:text-dawn-dark dark:border-dawn-dark dark:hover:text-dawn-hover-dark",
      "dark:hover:border-dawn-hover-dark dark:hover:bg-dawn-bordered-bg-dark disabled:text-natural-disabled-light",
      "disabled:border-natural-disabled-light dark:disabled:text-natural-disabled-dark dark:disabled:border-natural-disabled-dark",
      "disabled:hover:bg-transparent dark:disabled:hover:bg-transparent",
      indicator &&
        "[&>.indicator]:bg-dawn-indicator-alt-light dark:[&>.indicator]:bg-dawn-indicator-dark"
    ]
  end

  defp color_variant("inverted", "silver", indicator) do
    [
      "bg-transparent text-silver-light border-silver-light hover:text-silver-hover-light",
      "hover:border-silver-hover-light hover:bg-silver-bordered-bg-light",
      "dark:text-silver-dark dark:border-silver-dark dark:hover:text-silver-hover-dark",
      "dark:hover:border-silver-hover-dark dark:hover:bg-silver-bordered-bg-dark disabled:text-natural-disabled-light",
      "disabled:border-natural-disabled-light dark:disabled:text-natural-disabled-dark dark:disabled:border-natural-disabled-dark",
      "disabled:hover:bg-transparent dark:disabled:hover:bg-transparent",
      indicator &&
        "[&>.indicator]:bg-silver-indicator-alt-light dark:[&>.indicator]:bg-silver-indicator-dark"
    ]
  end

  defp color_variant("default_gradient", "natural", indicator) do
    [
      "bg-gradient-to-br hover:bg-gradient-to-bl",
      "from-gradient-natural-from-light to-gradient-natural-to-light text-white",
      "dark:from-gradient-natural-from-dark dark:to-white dark:text-black",
      "disabled:text-disabled-text-light dark:disabled:bg-disabled-bg-dark dark:disabled:text-disabled-text-dark",
      "disabled:from-disabled-bg-light disabled:to-disabled-bg-light",
      "dark:disabled:from-disabled-bg-dark dark:disabled:to-disabled-bg-dark",
      indicator && "[&>.indicator]:bg-white dark:[&>.indicator]:bg-black"
    ]
  end

  defp color_variant("default_gradient", "primary", indicator) do
    [
      "bg-gradient-to-br hover:bg-gradient-to-bl",
      "from-gradient-primary-from-light to-gradient-primary-to-light text-white",
      "dark:from-gradient-primary-from-dark dark:to-gradient-primary-to-dark dark:text-black",
      "disabled:text-disabled-text-light dark:disabled:bg-disabled-bg-dark dark:disabled:text-disabled-text-dark",
      "disabled:from-disabled-bg-light disabled:to-disabled-bg-light",
      "dark:disabled:from-disabled-bg-dark dark:disabled:to-disabled-bg-dark",
      indicator &&
        "[&>.indicator]:bg-primary-indicator-light dark:[&>.indicator]:bg-primary-gradient-indicator-dark"
    ]
  end

  defp color_variant("default_gradient", "secondary", indicator) do
    [
      "bg-gradient-to-br hover:bg-gradient-to-bl",
      "from-gradient-secondary-from-light to-gradient-secondary-to-light text-white",
      "dark:from-gradient-secondary-from-dark dark:to-gradient-secondary-to-dark dark:text-black",
      "disabled:text-disabled-text-light dark:disabled:bg-disabled-bg-dark dark:disabled:text-disabled-text-dark",
      "disabled:from-disabled-bg-light disabled:to-disabled-bg-light",
      "dark:disabled:from-disabled-bg-dark dark:disabled:to-disabled-bg-dark",
      indicator &&
        "[&>.indicator]:bg-secondary-indicator-light dark:[&>.indicator]:bg-secondary-gradient-indicator-dark"
    ]
  end

  defp color_variant("default_gradient", "success", indicator) do
    [
      "bg-gradient-to-br hover:bg-gradient-to-bl",
      "from-gradient-success-from-light to-gradient-success-to-light text-white",
      "dark:from-gradient-success-from-dark dark:to-gradient-success-to-dark dark:text-black",
      "disabled:text-disabled-text-light dark:disabled:bg-disabled-bg-dark dark:disabled:text-disabled-text-dark",
      "disabled:from-disabled-bg-light disabled:to-disabled-bg-light",
      "dark:disabled:from-disabled-bg-dark dark:disabled:to-disabled-bg-dark",
      indicator &&
        "[&>.indicator]:bg-success-indicator-alt-light dark:[&>.indicator]:bg-success-gradient-indicator-dark"
    ]
  end

  defp color_variant("default_gradient", "warning", indicator) do
    [
      "bg-gradient-to-br hover:bg-gradient-to-bl",
      "from-gradient-warning-from-light to-gradient-warning-to-light text-white",
      "dark:from-gradient-warning-from-dark dark:to-gradient-warning-to-dark dark:text-black",
      "disabled:text-disabled-text-light dark:disabled:bg-disabled-bg-dark dark:disabled:text-disabled-text-dark",
      "disabled:from-disabled-bg-light disabled:to-disabled-bg-light",
      "dark:disabled:from-disabled-bg-dark dark:disabled:to-disabled-bg-dark",
      indicator &&
        "[&>.indicator]:bg-warning-indicator-alt-light dark:[&>.indicator]:bg-warning-gradient-indicator-dark"
    ]
  end

  defp color_variant("default_gradient", "danger", indicator) do
    [
      "bg-gradient-to-br hover:bg-gradient-to-bl",
      "from-gradient-danger-from-light to-gradient-danger-to-light text-white",
      "dark:from-gradient-danger-from-dark dark:to-gradient-danger-to-dark dark:text-black",
      "disabled:text-disabled-text-light dark:disabled:bg-disabled-bg-dark dark:disabled:text-disabled-text-dark",
      "disabled:from-disabled-bg-light disabled:to-disabled-bg-light",
      "dark:disabled:from-disabled-bg-dark dark:disabled:to-disabled-bg-dark",
      indicator &&
        "[&>.indicator]:bg-danger-indicator-alt-light dark:[&>.indicator]:bg-danger-gradient-indicator-dark"
    ]
  end

  defp color_variant("default_gradient", "info", indicator) do
    [
      "bg-gradient-to-br hover:bg-gradient-to-bl",
      "from-gradient-info-from-light to-gradient-info-to-light text-white",
      "dark:from-gradient-info-from-dark dark:to-gradient-info-to-dark dark:text-black",
      "disabled:text-disabled-text-light dark:disabled:bg-disabled-bg-dark dark:disabled:text-disabled-text-dark",
      "disabled:from-disabled-bg-light disabled:to-disabled-bg-light",
      "dark:disabled:from-disabled-bg-dark dark:disabled:to-disabled-bg-dark",
      indicator &&
        "[&>.indicator]:bg-info-indicator-alt-light dark:[&>.indicator]:bg-info-gradient-indicator-dark"
    ]
  end

  defp color_variant("default_gradient", "misc", indicator) do
    [
      "bg-gradient-to-br hover:bg-gradient-to-bl",
      "from-gradient-misc-from-light to-gradient-misc-to-light text-white",
      "dark:from-gradient-misc-from-dark dark:to-gradient-misc-to-dark dark:text-black",
      "disabled:text-disabled-text-light dark:disabled:bg-disabled-bg-dark dark:disabled:text-disabled-text-dark",
      "disabled:from-disabled-bg-light disabled:to-disabled-bg-light",
      "dark:disabled:from-disabled-bg-dark dark:disabled:to-disabled-bg-dark",
      indicator &&
        "[&>.indicator]:bg-misc-indicator-alt-light dark:[&>.indicator]:bg-misc-gradient-indicator-dark"
    ]
  end

  defp color_variant("default_gradient", "dawn", indicator) do
    [
      "bg-gradient-to-br hover:bg-gradient-to-bl",
      "from-gradient-dawn-from-light to-gradient-dawn-to-light text-white",
      "dark:from-gradient-dawn-from-dark dark:to-gradient-dawn-to-dark dark:text-black",
      "disabled:text-disabled-text-light dark:disabled:bg-disabled-bg-dark dark:disabled:text-disabled-text-dark",
      "disabled:from-disabled-bg-light disabled:to-disabled-bg-light",
      "dark:disabled:from-disabled-bg-dark dark:disabled:to-disabled-bg-dark",
      indicator &&
        "[&>.indicator]:bg-dawn-indicator-alt-light dark:[&>.indicator]:bg-dawn-gradient-indicator-dark"
    ]
  end

  defp color_variant("default_gradient", "silver", indicator) do
    [
      "bg-gradient-to-br hover:bg-gradient-to-bl",
      "from-gradient-silver-from-light to-gradient-silver-to-light text-white",
      "dark:from-gradient-silver-from-dark dark:to-gradient-silver-to-dark dark:text-black",
      "disabled:text-disabled-text-light dark:disabled:bg-disabled-bg-dark dark:disabled:text-disabled-text-dark",
      "disabled:from-disabled-bg-light disabled:to-disabled-bg-light",
      "dark:disabled:from-disabled-bg-dark dark:disabled:to-disabled-bg-dark",
      indicator && "[&>.indicator]:bg-natural-bg-dark dark:[&>.indicator]:bg-natural-hover-dark"
    ]
  end

  defp color_variant("outline_gradient", "natural", indicator) do
    [
      "gradient-button [&>*]:relative [&>*]:z-[1] relative bg-gradient-to-br hover:bg-gradient-to-bl",
      "from-gradient-natural-from-light to-gradient-natural-to-light text-natural-light hover:text-natural-hover-light",
      "dark:from-gradient-natural-from-dark dark:to-white dark:text-natural-dark dark:hover:text-natural-hover-dark",
      "before:bg-white dark:before:bg-bordered-dark-bg before:absolute before:inset-[2px] before:z-0",
      "disabled:from-natural-disabled-light disabled:to-natural-disabled-light disabled:text-natural-disabled-light",
      "dark:disabled:from-natural-disabled-dark dark:disabled:to-natural-disabled-dark dark:disabled:text-natural-disabled-dark",
      indicator && "[&>.indicator]:bg-black dark:[&>.indicator]:bg-white"
    ]
  end

  defp color_variant("outline_gradient", "primary", indicator) do
    [
      "gradient-button [&>*]:relative [&>*]:z-[1] relative bg-gradient-to-br hover:bg-gradient-to-bl",
      "from-gradient-primary-from-light to-gradient-primary-to-light text-primary-light hover:text-primary-hover-light",
      "dark:from-gradient-primary-from-dark dark:to-gradient-primary-to-dark dark:text-primary-dark dark:hover:text-primary-hover-dark",
      "before:bg-white dark:before:bg-bordered-dark-bg before:absolute before:inset-[2px] before:z-0",
      "disabled:from-natural-disabled-light disabled:to-natural-disabled-light disabled:text-natural-disabled-light",
      "dark:disabled:from-natural-disabled-dark dark:disabled:to-natural-disabled-dark dark:disabled:text-natural-disabled-dark",
      indicator &&
        "[&>.indicator]:bg-primary-indicator-light dark:[&>.indicator]:bg-primary-indicator-dark"
    ]
  end

  defp color_variant("outline_gradient", "secondary", indicator) do
    [
      "gradient-button [&>*]:relative [&>*]:z-[1] relative bg-gradient-to-br hover:bg-gradient-to-bl",
      "from-gradient-secondary-from-light to-gradient-secondary-to-light text-secondary-light hover:text-secondary-hover-light",
      "dark:from-gradient-secondary-from-dark dark:to-gradient-secondary-to-dark dark:text-secondary-dark dark:hover:text-secondary-hover-dark",
      "before:bg-white dark:before:bg-bordered-dark-bg before:absolute before:inset-[2px] before:z-0",
      "disabled:from-natural-disabled-light disabled:to-natural-disabled-light disabled:text-natural-disabled-light",
      "dark:disabled:from-natural-disabled-dark dark:disabled:to-natural-disabled-dark dark:disabled:text-natural-disabled-dark",
      indicator &&
        "[&>.indicator]:bg-secondary-indicator-light dark:[&>.indicator]:bg-secondary-indicator-dark"
    ]
  end

  defp color_variant("outline_gradient", "success", indicator) do
    [
      "gradient-button [&>*]:relative [&>*]:z-[1] relative bg-gradient-to-br hover:bg-gradient-to-bl",
      "from-gradient-success-from-light to-gradient-success-to-light text-success-light hover:text-success-hover-light",
      "dark:from-gradient-success-from-dark dark:to-gradient-success-to-dark dark:text-success-dark dark:hover:text-success-hover-dark",
      "before:bg-white dark:before:bg-bordered-dark-bg before:absolute before:inset-[2px] before:z-0",
      "disabled:from-natural-disabled-light disabled:to-natural-disabled-light disabled:text-natural-disabled-light",
      "dark:disabled:from-natural-disabled-dark dark:disabled:to-natural-disabled-dark dark:disabled:text-natural-disabled-dark",
      indicator &&
        "[&>.indicator]:bg-success-indicator-alt-light dark:[&>.indicator]:bg-success-indicator-dark"
    ]
  end

  defp color_variant("outline_gradient", "warning", indicator) do
    [
      "gradient-button [&>*]:relative [&>*]:z-[1] relative bg-gradient-to-br hover:bg-gradient-to-bl",
      "from-gradient-warning-from-light to-gradient-warning-to-light text-warning-light hover:text-warning-hover-light",
      "dark:from-gradient-warning-from-dark dark:to-gradient-warning-to-dark dark:text-warning-dark dark:hover:text-warning-hover-dark",
      "before:bg-white dark:before:bg-bordered-dark-bg before:absolute before:inset-[2px] before:z-0",
      "disabled:from-natural-disabled-light disabled:to-natural-disabled-light disabled:text-natural-disabled-light",
      "dark:disabled:from-natural-disabled-dark dark:disabled:to-natural-disabled-dark dark:disabled:text-natural-disabled-dark",
      indicator &&
        "[&>.indicator]:bg-warning-indicator-alt-light dark:[&>.indicator]:bg-warning-indicator-dark"
    ]
  end

  defp color_variant("outline_gradient", "danger", indicator) do
    [
      "gradient-button [&>*]:relative [&>*]:z-[1] relative bg-gradient-to-br hover:bg-gradient-to-bl",
      "from-gradient-danger-from-light to-gradient-danger-to-light text-danger-light hover:text-danger-hover-light",
      "dark:from-gradient-danger-from-dark dark:to-gradient-danger-to-dark dark:text-danger-dark dark:hover:text-danger-hover-dark",
      "before:bg-white dark:before:bg-bordered-dark-bg before:absolute before:inset-[2px] before:z-0",
      "disabled:from-natural-disabled-light disabled:to-natural-disabled-light disabled:text-natural-disabled-light",
      "dark:disabled:from-natural-disabled-dark dark:disabled:to-natural-disabled-dark dark:disabled:text-natural-disabled-dark",
      indicator &&
        "[&>.indicator]:bg-danger-indicator-alt-light dark:[&>.indicator]:bg-danger-indicator-dark"
    ]
  end

  defp color_variant("outline_gradient", "info", indicator) do
    [
      "gradient-button [&>*]:relative [&>*]:z-[1] relative bg-gradient-to-br hover:bg-gradient-to-bl",
      "from-gradient-info-from-light to-gradient-info-to-light text-info-light hover:text-info-hover-light",
      "dark:from-gradient-info-from-dark dark:to-gradient-info-to-dark dark:text-info-dark dark:hover:text-info-hover-dark",
      "before:bg-white dark:before:bg-bordered-dark-bg before:absolute before:inset-[2px] before:z-0",
      "disabled:from-natural-disabled-light disabled:to-natural-disabled-light disabled:text-natural-disabled-light",
      "dark:disabled:from-natural-disabled-dark dark:disabled:to-natural-disabled-dark dark:disabled:text-natural-disabled-dark",
      indicator &&
        "[&>.indicator]:bg-info-indicator-alt-light dark:[&>.indicator]:bg-info-indicator-dark"
    ]
  end

  defp color_variant("outline_gradient", "misc", indicator) do
    [
      "gradient-button [&>*]:relative [&>*]:z-[1] relative bg-gradient-to-br hover:bg-gradient-to-bl",
      "from-gradient-misc-from-light to-gradient-misc-to-light text-misc-light hover:text-misc-hover-light",
      "dark:from-gradient-misc-from-dark dark:to-gradient-misc-to-dark dark:text-misc-dark dark:hover:text-misc-hover-dark",
      "before:bg-white dark:before:bg-bordered-dark-bg before:absolute before:inset-[2px] before:z-0",
      "disabled:from-natural-disabled-light disabled:to-natural-disabled-light disabled:text-natural-disabled-light",
      "dark:disabled:from-natural-disabled-dark dark:disabled:to-natural-disabled-dark dark:disabled:text-natural-disabled-dark",
      indicator &&
        "[&>.indicator]:bg-misc-indicator-alt-light dark:[&>.indicator]:bg-misc-indicator-dark"
    ]
  end

  defp color_variant("outline_gradient", "dawn", indicator) do
    [
      "gradient-button [&>*]:relative [&>*]:z-[1] relative bg-gradient-to-br hover:bg-gradient-to-bl",
      "from-gradient-dawn-from-light to-gradient-dawn-to-light text-dawn-light hover:text-dawn-hover-light",
      "dark:from-gradient-dawn-from-dark dark:to-gradient-dawn-to-dark dark:text-dawn-dark dark:hover:text-dawn-dark",
      "before:bg-white dark:before:bg-bordered-dark-bg before:absolute before:inset-[2px] before:z-0",
      "disabled:from-natural-disabled-light disabled:to-natural-disabled-light disabled:text-natural-disabled-light",
      "dark:disabled:from-natural-disabled-dark dark:disabled:to-natural-disabled-dark dark:disabled:text-natural-disabled-dark",
      indicator &&
        "[&>.indicator]:bg-dawn-indicator-alt-light dark:[&>.indicator]:bg-dawn-indicator-dark"
    ]
  end

  defp color_variant("outline_gradient", "silver", indicator) do
    [
      "gradient-button [&>*]:relative [&>*]:z-[1] relative bg-gradient-to-br hover:bg-gradient-to-bl",
      "from-gradient-silver-from-light to-gradient-silver-to-light text-silver-light hover:text-silver-hover-light",
      "dark:from-gradient-silver-from-dark dark:to-gradient-silver-to-dark dark:text-silver-dark dark:hover:text-silver-hover-dark",
      "before:bg-white dark:before:bg-bordered-dark-bg before:absolute before:inset-[2px] before:z-0",
      "disabled:from-natural-disabled-light disabled:to-natural-disabled-light disabled:text-natural-disabled-light",
      "dark:disabled:from-natural-disabled-dark dark:disabled:to-natural-disabled-dark dark:disabled:text-natural-disabled-dark",
      indicator &&
        "[&>.indicator]:bg-silver-indicator-alt-light dark:[&>.indicator]:bg-silver-indicator-dark"
    ]
  end

  defp color_variant("inverted_gradient", "natural", indicator) do
    [
      "gradient-button [&>*]:relative [&>*]:z-[1] relative bg-gradient-to-br hover:bg-gradient-to-bl",
      "from-gradient-natural-from-light to-gradient-natural-to-light text-natural-light hover:text-white",
      "dark:from-gradient-natural-from-dark dark:to-white dark:text-natural-dark dark:hover:text-black",
      "before:bg-white dark:before:bg-bordered-dark-bg before:transition",
      "before:ease-in-out before:duration-100 duration before:absolute before:inset-[2px] before:z-0",
      "hover:before:bg-transparent dark:hover:before:bg-transparent",
      "disabled:from-natural-disabled-light disabled:to-natural-disabled-light disabled:text-natural-disabled-light",
      "dark:disabled:from-natural-disabled-dark dark:disabled:to-natural-disabled-dark dark:disabled:text-natural-disabled-dark",
      "hover:disabled:bg-white dark:hover:disabled:before:bg-bordered-dark-bg",
      indicator && "[&>.indicator]:bg-black dark:[&>.indicator]:bg-white",
      indicator && "[&:hover>.indicator]:bg-white dark:[&:hover>.indicator]:bg-black"
    ]
  end

  defp color_variant("inverted_gradient", "primary", indicator) do
    [
      "gradient-button [&>*]:relative [&>*]:z-[1] relative bg-gradient-to-br hover:bg-gradient-to-bl",
      "from-gradient-primary-from-light to-gradient-primary-to-light text-primary-light hover:text-white",
      "dark:from-gradient-primary-from-dark dark:to-gradient-primary-to-dark dark:text-primary-dark dark:hover:text-black",
      "before:bg-white dark:before:bg-bordered-dark-bg before:transition",
      "before:ease-in-out before:duration-100 duration before:absolute before:inset-[2px] before:z-0",
      "hover:before:bg-transparent dark:hover:before:bg-transparent",
      "disabled:from-natural-disabled-light disabled:to-natural-disabled-light disabled:text-natural-disabled-light",
      "dark:disabled:from-natural-disabled-dark dark:disabled:to-natural-disabled-dark dark:disabled:text-natural-disabled-dark",
      "hover:disabled:bg-white dark:hover:disabled:before:bg-bordered-dark-bg",
      indicator &&
        "[&>.indicator]:bg-primary-indicator-light dark:[&>.indicator]:bg-primary-inverted-gradient-indicator-dark",
      indicator &&
        "[&:hover>.indicator]:bg-primary-inverted-gradient-indicator-dark dark:[&:hover>.indicator]:bg-primary-indicator-light"
    ]
  end

  defp color_variant("inverted_gradient", "secondary", indicator) do
    [
      "gradient-button [&>*]:relative [&>*]:z-[1] relative bg-gradient-to-br hover:bg-gradient-to-bl",
      "from-gradient-secondary-from-light to-gradient-secondary-to-light text-secondary-light hover:text-white",
      "dark:from-gradient-secondary-from-dark dark:to-gradient-secondary-to-dark dark:text-secondary-dark dark:hover:text-black",
      "before:bg-white dark:before:bg-bordered-dark-bg before:transition",
      "before:ease-in-out before:duration-100 duration before:absolute before:inset-[2px] before:z-0",
      "hover:before:bg-transparent dark:hover:before:bg-transparent",
      "disabled:from-natural-disabled-light disabled:to-natural-disabled-light disabled:text-natural-disabled-light",
      "dark:disabled:from-natural-disabled-dark dark:disabled:to-natural-disabled-dark dark:disabled:text-natural-disabled-dark",
      "hover:disabled:bg-white dark:hover:disabled:before:bg-bordered-dark-bg",
      indicator &&
        "[&>.indicator]:bg-secondary-indicator-light dark:[&>.indicator]:bg-secondary-indicator-dark",
      indicator &&
        "[&:hover>.indicator]:bg-secondary-indicator-dark dark:[&:hover>.indicator]:bg-secondary-indicator-light"
    ]
  end

  defp color_variant("inverted_gradient", "success", indicator) do
    [
      "gradient-button [&>*]:relative [&>*]:z-[1] relative bg-gradient-to-br hover:bg-gradient-to-bl",
      "from-gradient-success-from-light to-gradient-success-to-light text-success-light hover:text-white",
      "dark:from-gradient-success-from-dark dark:to-gradient-success-to-dark dark:text-success-dark dark:hover:text-black",
      "before:bg-white dark:before:bg-bordered-dark-bg before:transition",
      "before:ease-in-out before:duration-100 duration before:absolute before:inset-[2px] before:z-0",
      "hover:before:bg-transparent dark:hover:before:bg-transparent",
      "disabled:from-natural-disabled-light disabled:to-natural-disabled-light disabled:text-natural-disabled-light",
      "dark:disabled:from-natural-disabled-dark dark:disabled:to-natural-disabled-dark dark:disabled:text-natural-disabled-dark",
      "hover:disabled:bg-white dark:hover:disabled:before:bg-bordered-dark-bg",
      indicator &&
        "[&>.indicator]:bg-success-indicator-alt-light dark:[&>.indicator]:bg-success-indicator-dark",
      indicator &&
        "[&:hover>.indicator]:bg-success-indicator-dark dark:[&:hover>.indicator]:bg-success-indicator-alt-light"
    ]
  end

  defp color_variant("inverted_gradient", "warning", indicator) do
    [
      "gradient-button [&>*]:relative [&>*]:z-[1] relative bg-gradient-to-br hover:bg-gradient-to-bl",
      "from-gradient-warning-from-light to-gradient-warning-to-light text-warning-light hover:text-white",
      "dark:from-gradient-warning-from-dark dark:to-gradient-warning-to-dark dark:text-warning-dark dark:hover:text-black",
      "before:bg-white dark:before:bg-bordered-dark-bg before:transition",
      "before:ease-in-out before:duration-100 duration before:absolute before:inset-[2px] before:z-0",
      "hover:before:bg-transparent dark:hover:before:bg-transparent",
      "disabled:from-natural-disabled-light disabled:to-natural-disabled-light disabled:text-natural-disabled-light",
      "dark:disabled:from-natural-disabled-dark dark:disabled:to-natural-disabled-dark dark:disabled:text-natural-disabled-dark",
      "hover:disabled:bg-white dark:hover:disabled:before:bg-bordered-dark-bg",
      indicator &&
        "[&>.indicator]:bg-warning-indicator-alt-light dark:[&>.indicator]:bg-warning-indicator-dark",
      indicator &&
        "[&:hover>.indicator]:bg-warning-indicator-dark dark:[&:hover>.indicator]:bg-warning-indicator-alt-light"
    ]
  end

  defp color_variant("inverted_gradient", "danger", indicator) do
    [
      "gradient-button [&>*]:relative [&>*]:z-[1] relative bg-gradient-to-br hover:bg-gradient-to-bl",
      "from-gradient-danger-from-light to-gradient-danger-to-light text-danger-light hover:text-white",
      "dark:from-gradient-danger-from-dark dark:to-gradient-danger-to-dark dark:text-danger-dark dark:hover:text-black",
      "before:bg-white dark:before:bg-bordered-dark-bg before:transition",
      "before:ease-in-out before:duration-100 duration before:absolute before:inset-[2px] before:z-0",
      "hover:before:bg-transparent dark:hover:before:bg-transparent",
      "disabled:from-natural-disabled-light disabled:to-natural-disabled-light disabled:text-natural-disabled-light",
      "dark:disabled:from-natural-disabled-dark dark:disabled:to-natural-disabled-dark dark:disabled:text-natural-disabled-dark",
      "hover:disabled:bg-white dark:hover:disabled:before:bg-bordered-dark-bg",
      indicator &&
        "[&>.indicator]:bg-danger-indicator-alt-light dark:[&>.indicator]:bg-danger-indicator-dark",
      indicator &&
        "[&:hover>.indicator]:bg-danger-indicator-dark dark:[&:hover>.indicator]:bg-danger-indicator-alt-light"
    ]
  end

  defp color_variant("inverted_gradient", "info", indicator) do
    [
      "gradient-button [&>*]:relative [&>*]:z-[1] relative bg-gradient-to-br hover:bg-gradient-to-bl",
      "from-gradient-info-from-light to-gradient-info-to-light text-info-light hover:text-white",
      "dark:from-gradient-info-from-dark dark:to-gradient-info-to-dark dark:text-info-dark dark:hover:text-black",
      "before:bg-white dark:before:bg-bordered-dark-bg before:transition",
      "before:ease-in-out before:duration-100 duration before:absolute before:inset-[2px] before:z-0",
      "hover:before:bg-transparent dark:hover:before:bg-transparent",
      "disabled:from-natural-disabled-light disabled:to-natural-disabled-light disabled:text-natural-disabled-light",
      "dark:disabled:from-natural-disabled-dark dark:disabled:to-natural-disabled-dark dark:disabled:text-natural-disabled-dark",
      "hover:disabled:bg-white dark:hover:disabled:before:bg-bordered-dark-bg",
      indicator &&
        "[&>.indicator]:bg-info-indicator-alt-light dark:[&>.indicator]:bg-info-indicator-dark",
      indicator &&
        "[&:hover>.indicator]:bg-info-indicator-dark dark:[&:hover>.indicator]:bg-info-indicator-alt-light"
    ]
  end

  defp color_variant("inverted_gradient", "misc", indicator) do
    [
      "gradient-button [&>*]:relative [&>*]:z-[1] relative bg-gradient-to-br hover:bg-gradient-to-bl",
      "from-gradient-misc-from-light to-gradient-misc-to-light text-misc-light hover:text-white",
      "dark:from-gradient-misc-from-dark dark:to-gradient-misc-to-dark dark:text-misc-dark dark:hover:text-black",
      "before:bg-white dark:before:bg-bordered-dark-bg before:transition",
      "before:ease-in-out before:duration-100 duration before:absolute before:inset-[2px] before:z-0",
      "hover:before:bg-transparent dark:hover:before:bg-transparent",
      "disabled:from-natural-disabled-light disabled:to-natural-disabled-light disabled:text-natural-disabled-light",
      "dark:disabled:from-natural-disabled-dark dark:disabled:to-natural-disabled-dark dark:disabled:text-natural-disabled-dark",
      "hover:disabled:bg-white dark:hover:disabled:before:bg-bordered-dark-bg",
      indicator &&
        "[&>.indicator]:bg-misc-indicator-alt-light dark:[&>.indicator]:bg-misc-indicator-dark",
      indicator &&
        "[&:hover>.indicator]:bg-misc-indicator-dark dark:[&:hover>.indicator]:bg-misc-indicator-alt-light"
    ]
  end

  defp color_variant("inverted_gradient", "dawn", indicator) do
    [
      "gradient-button [&>*]:relative [&>*]:z-[1] relative bg-gradient-to-br hover:bg-gradient-to-bl",
      "from-gradient-dawn-from-light to-gradient-dawn-to-light text-dawn-light hover:text-white",
      "dark:from-gradient-dawn-from-dark dark:to-gradient-dawn-to-dark dark:text-dawn-dark dark:hover:text-black",
      "before:bg-white dark:before:bg-bordered-dark-bg before:transition",
      "before:ease-in-out before:duration-100 duration before:absolute before:inset-[2px] before:z-0",
      "hover:before:bg-transparent dark:hover:before:bg-transparent",
      "disabled:from-natural-disabled-light disabled:to-natural-disabled-light disabled:text-natural-disabled-light",
      "dark:disabled:from-natural-disabled-dark dark:disabled:to-natural-disabled-dark dark:disabled:text-natural-disabled-dark",
      "hover:disabled:bg-white dark:hover:disabled:before:bg-bordered-dark-bg",
      indicator &&
        "[&>.indicator]:bg-dawn-indicator-alt-light dark:[&>.indicator]:bg-dawn-indicator-dark",
      indicator &&
        "[&:hover>.indicator]:bg-dawn-indicator-dark dark:[&:hover>.indicator]:bg-dawn-indicator-alt-light"
    ]
  end

  defp color_variant("inverted_gradient", "silver", indicator) do
    [
      "gradient-button [&>*]:relative [&>*]:z-[1] relative bg-gradient-to-br hover:bg-gradient-to-bl",
      "from-gradient-silver-from-light to-gradient-silver-to-light text-silver-light hover:text-white",
      "dark:from-gradient-silver-from-dark dark:to-gradient-silver-to-dark dark:text-silver-dark dark:hover:text-black",
      "before:bg-white dark:before:bg-bordered-dark-bg before:transition",
      "before:ease-in-out before:duration-100 duration before:absolute before:inset-[2px] before:z-0",
      "hover:before:bg-transparent dark:hover:before:bg-transparent",
      "disabled:from-natural-disabled-light disabled:to-natural-disabled-light disabled:text-natural-disabled-light",
      "dark:disabled:from-natural-disabled-dark dark:disabled:to-natural-disabled-dark dark:disabled:text-natural-disabled-dark",
      "hover:disabled:bg-white dark:hover:disabled:before:bg-bordered-dark-bg",
      indicator &&
        "[&>.indicator]:bg-natural-hover-dark dark:[&>.indicator]:bg-silver-indicator-dark",
      indicator &&
        "[&:hover>.indicator]:bg-silver-indicator-dark dark:[&:hover>.indicator]:bg-natural-hover-dark"
    ]
  end

  defp color_variant(params, _, _) when is_binary(params), do: params

  defp border_class("base") do
    "border-base-border-light dark:border-base-border-dark"
  end

  defp border_class("natural") do
    "border-black dark:border-white"
  end

  defp border_class("transparent") do
    "border-transparent dark:border-transparent"
  end

  defp border_class("primary") do
    "border-primary-border-light dark:border-primary-border-dark"
  end

  defp border_class("secondary") do
    "border-secondary-border-light dark:border-secondary-border-dark"
  end

  defp border_class("success") do
    "border-success-border-light dark:border-success-border-dark"
  end

  defp border_class("warning") do
    "border-warning-border-light dark:border-warning-border-dark"
  end

  defp border_class("danger") do
    "border-danger-border-light dark:border-danger-border-dark"
  end

  defp border_class("info") do
    "border-info-border-light dark:border-info-border-dark"
  end

  defp border_class("misc") do
    "border-misc-border-light dark:border-misc-border-dark"
  end

  defp border_class("dawn") do
    "border-dawn-border-light dark:border-dawn-border-dark"
  end

  defp border_class("silver") do
    "border-silver-border-light dark:border-silver-border-dark"
  end

  defp border_class(params) when is_binary(params), do: params

  defp rounded_size("extra_small"), do: "rounded-sm [&.gradient-button:before]:rounded-[1px]"

  defp rounded_size("small"), do: "rounded [&.gradient-button:before]:rounded-[2px]"

  defp rounded_size("medium"), do: "rounded-md [&.gradient-button:before]:rounded-[4px]"

  defp rounded_size("large"), do: "rounded-lg [&.gradient-button:before]:rounded-[5px]"

  defp rounded_size("extra_large"), do: "rounded-xl [&.gradient-button:before]:rounded-[9px]"

  defp rounded_size("full"), do: "rounded-full [&.gradient-button:before]:rounded-full"

  defp rounded_size("none"), do: nil

  defp rounded_size(params) when is_binary(params), do: params

  defp size_class("extra_small", circle) do
    [
      is_nil(circle) && "py-1 px-2",
      "text-[12px] [&>.indicator]:size-1",
      !is_nil(circle) && "size-6"
    ]
  end

  defp size_class("small", circle) do
    [
      is_nil(circle) && "py-1.5 px-3",
      "text-[13px] [&>.indicator]:size-1.5",
      !is_nil(circle) && "size-7"
    ]
  end

  defp size_class("medium", circle) do
    [
      is_nil(circle) && "py-2 px-4",
      "text-[14px] [&>.indicator]:size-2",
      !is_nil(circle) && "size-8"
    ]
  end

  defp size_class("large", circle) do
    [
      is_nil(circle) && "py-2.5 px-5",
      "text-[15px] [&>.indicator]:size-2.5",
      !is_nil(circle) && "size-9"
    ]
  end

  defp size_class("extra_large", circle) do
    [
      is_nil(circle) && "py-3 px-5",
      "text-[16px] [&>.indicator]:size-3",
      !is_nil(circle) && "size-10"
    ]
  end

  defp size_class(params, _circle) when is_binary(params), do: [params]

  defp icon_position(nil, _), do: false
  defp icon_position(_icon, %{left_icon: true}), do: "left"
  defp icon_position(_icon, %{right_icon: true}), do: "right"
  defp icon_position(_icon, _), do: "left"

  defp variation("horizontal") do
    "flex-row [&>*:not(:last-child)]:border-r"
  end

  defp variation("vertical") do
    "flex-col [&>*:not(:last-child)]:border-b"
  end

  defp indicator_size("extra_small"), do: "!size-2"
  defp indicator_size("small"), do: "!size-2.5"
  defp indicator_size("medium"), do: "!size-3"
  defp indicator_size("large"), do: "!size-3.5"
  defp indicator_size("extra_large"), do: "!size-4"
  defp indicator_size(params) when is_binary(params), do: params

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

  defp default_classes(:grouped, _) do
    [
      "phx-submit-loading:opacity-75 overflow-hidden flex w-fit rounded-lg border",
      "[&>*]:rounded-none [&>*]:border-0"
    ]
  end

  defp default_classes(pinging, indicator) do
    [
      "phx-submit-loading:opacity-75 cursor-pointer relative gap-2 items-center",
      "transition-all ease-in-ou duration-100 group",
      "disabled:cursor-not-allowed",
      "focus:outline-none",
      indicator &&
        "[&>.indicator]:inline-block [&>.indicator]:shrink-0 [&>.indicator]:rounded-full",
      !is_nil(pinging) && "[&>.indicator]:animate-ping"
    ]
  end

  defp drop_rest(rest) do
    all_rest =
      (["pinging", "circle", "right_icon", "left_icon"] ++ @indicator_positions)
      |> Enum.map(&if(is_binary(&1), do: String.to_atom(&1), else: &1))

    Map.drop(rest, all_rest)
  end

  defp is_indicators?(rest) do
    Enum.any?(@indicator_positions, &Map.get(rest, String.to_atom(&1)))
  end
end
