defmodule RadiatorWeb.Components.Toast do
  @moduledoc """
  A module for creating toast notifications in a Phoenix application.

  This module provides components for rendering toast messages, including
  options for customization such as size, color, and dismiss behavior. It
  supports a variety of visual styles and positions, allowing for
  flexible integration into any user interface.

  Toasts can be used to provide feedback to users or display
  informational messages without interrupting their workflow. The
  components defined in this module handle the presentation and
  interaction logic, enabling developers to easily implement toast
  notifications within their applications.

  > You can create a toast notification with various styles and
  > configurations to suit your application's needs.

  **Documentation:** https://mishka.tools/chelekom/docs/toast
  """
  use Phoenix.Component
  alias Phoenix.LiveView.JS
  use Gettext, backend: RadiatorWeb.Gettext
  import RadiatorWeb.Components.Icon, only: [icon: 1]

  @doc """
  The `toast` component displays temporary notifications or messages, usually at the top
  or bottom of the screen.

  It supports customization for size, color, border, and positioning, allowing you to
  style the toast as needed.

  ## Examples

  ```elixir
  <.toast id="toast-1">
    <div>Lorem ipsum dolor sit amet consectetur adipisicing elit.</div>
  </.toast>

  <.toast
    id="toast-2"
    color="success"
    content_border="small"
    border_position="end"
    horizontal="center"
    vertical_space="large"
  >
    <div>Lorem ipsum dolor sit amet consectetur adipisicing elit.</div>
  </.toast>

  <.toast
    id="toast-3"
    color="misc"
    horizontal="left"
    content_border="extra_small"
    border_position="start"
    rounded="medium"
    width="extra_large"
  >
    <div>Lorem ipsum dolor sit amet consectetur adipisicing elit.</div>
  </.toast>
  ```
  """
  @doc type: :component
  attr :id, :string,
    required: true,
    doc: "A unique identifier is used to manage state and interaction"

  attr :fixed, :boolean, default: true, doc: "Determines whether the element is fixed"
  attr :variant, :string, default: "base", doc: "Determines the style"
  attr :color, :string, default: "natural", doc: "Determines color theme"
  attr :border, :string, default: "extra_small", doc: "Determines border style"
  attr :rounded, :string, default: "medium", doc: "Determines the border radius"
  attr :width, :string, default: "medium", doc: "Determines the element width"
  attr :space, :string, default: "extra_small", doc: "Space between items"
  attr :vertical, :string, values: ["top", "bottom"], default: "top", doc: "Type of vertical"
  attr :vertical_space, :string, default: "extra_small", doc: "Space between vertical items"
  attr :z_index, :string, default: "z-50", doc: "custom z-index"

  attr :horizontal, :string,
    values: ["left", "right", "center"],
    default: "right",
    doc: "Type of horizontal"

  attr :horizontal_space, :string, default: "extra_small", doc: "Space between horizontal items"

  attr :font_weight, :string,
    default: "font-normal",
    doc: "Determines custom class for the font weight"

  attr :class, :string, default: "", doc: "Additional CSS classes to be added to the toast."

  attr :wrapper_class, :string,
    default: "",
    doc: "Additional CSS classes to be added to the toast contents."

  attr :content_wrapper_class, :string,
    default: "",
    doc: "Additional CSS classes to be added to the toast contents."

  attr :content_class, :string,
    default: "",
    doc: "Additional CSS classes to be added to the toast contents."

  attr :dismiss_class, :string,
    default: "",
    doc: "Additional CSS classes to be added to the toast contents."

  attr :dismiss_icon_class, :string,
    default: "",
    doc: "Additional CSS classes to be added to the toast contents."

  attr :params, :map,
    default: %{kind: "toast"},
    doc: "A map of additional parameters used for element configuration"

  attr :rest, :global,
    include: ~w(right_dismiss left_dismiss),
    doc:
      "Global attributes can define defaults which are merged with attributes provided by the caller"

  attr :content_border, :string, default: "none", doc: "Determines the content border style"
  attr :border_position, :string, default: "start", doc: "Determines the border position style"
  attr :row_direction, :string, default: "none", doc: "Determines row direction"
  attr :padding, :string, default: "extra_small", doc: "Determines padding for items"
  slot :inner_block, required: false, doc: "Inner block that renders HEEx content"

  def toast(assigns) do
    ~H"""
    <div
      id={@id}
      aria-atomic="true"
      tabindex="0"
      class={[
        "overflow-hidden leading-5",
        @fixed && "fixed",
        width_class(@width),
        rounded_size(@rounded),
        border_class(@border, @variant),
        color_variant(@variant, @color),
        position_class(@horizontal_space, @horizontal),
        vertical_position(@vertical_space, @vertical),
        @font_weight,
        @z_index,
        @class
      ]}
      {@rest}
    >
      <div class={[
        "toast-content-wrapper relative",
        "before:block before:absolute before:inset-y-0 before:rounded-full before:my-1",
        content_border(@content_border),
        @content_border != "none" && border_position(@border_position),
        @wrapper_class
      ]}>
        <div class={[
          "flex gap-2 items-center justify-between",
          row_direction(@row_direction),
          padding_size(@padding),
          @content_wrapper_class
        ]}>
          <div class={[space_class(@space), @content_class]}>
            {render_slot(@inner_block)}
          </div>
          <.toast_dismiss
            id={@id}
            params={@params}
            class={@dismiss_class}
            icon_class={@dismiss_icon_class}
          />
        </div>
      </div>
    </div>
    """
  end

  @doc """
  The `toast_group` component is used to group multiple `toast` elements together,
  allowing for coordinated display and positioning of toast notifications.

  ## Examples

  ```elixir
  <.toast_group vertical_space="large" horizontal_space="extra_large">
    <.toast
      id="toast-1"
      color="success"
      content_border="small"
      border_position="end"
      fixed={false}
    >
      <div>
        Lorem ipsum dolor sit amet consectetur adipisicing elit.
      </div>
    </.toast>

    <.toast
      id="toast-2"
      variant="outline"
      color="danger"
      content_border="small"
      border_position="start"
      fixed={false}
    >
      <div>
        Lorem ipsum dolor sit amet consectetur adipisicing elit.
      </div>
    </.toast>

    <.toast
      id="toast-3"
      variant="unbordered"
      color="warning"
      content_border="small"
      border_position="start"
      fixed={false}
    >
      <div>
        Lorem ipsum dolor sit amet consectetur adipisicing elit.
      </div>
    </.toast>
  </.toast_group>
  ```
  """
  @doc type: :component
  attr :id, :string,
    default: nil,
    doc: "A unique identifier is used to manage state and interaction"

  attr :space, :string, default: "small", doc: "Space between items"
  attr :vertical, :string, values: ["top", "bottom"], default: "bottom", doc: "Type of vertical"
  attr :vertical_space, :string, default: "extra_small", doc: "Space between vertical items"
  attr :z_index, :string, default: "z-50", doc: "custom z-index"

  attr :horizontal, :string,
    values: ["left", "right", "center"],
    default: "right",
    doc: "Type of horizontal"

  attr :horizontal_space, :string, default: "extra_small", doc: "Space between horizontal items"
  attr :class, :string, default: nil, doc: "Custom CSS class for additional styling"

  attr :rest, :global,
    doc:
      "Global attributes can define defaults which are merged with attributes provided by the caller"

  slot :inner_block, required: false, doc: "Inner block that renders HEEx content"

  def toast_group(assigns) do
    ~H"""
    <div
      id={@id}
      role="region"
      class={[
        "fixed",
        space_class(@space),
        position_class(@horizontal_space, @horizontal),
        vertical_position(@vertical_space, @vertical),
        @z_index,
        @class
      ]}
      {@rest}
    >
      {render_slot(@inner_block)}
    </div>
    """
  end

  @doc type: :component
  attr :id, :string,
    required: true,
    doc: "A unique identifier is used to manage state and interaction"

  attr :dismiss, :boolean,
    default: false,
    doc: "Determines if the toast should include a dismiss button"

  attr :class, :string, default: nil, doc: "Custom CSS class for additional styling"
  attr :icon_class, :string, default: nil, doc: "Custom CSS class for additional styling"

  attr :size, :string,
    default: "small",
    doc:
      "Determines the overall size of the elements, including padding, font size, and other items"

  attr :params, :map,
    default: %{kind: "toast"},
    doc: "A map of additional parameters used for element configuration"

  defp toast_dismiss(assigns) do
    ~H"""
    <button
      type="button"
      class={["shrink-0 leading-5", @class]}
      aria-label={gettext("close")}
      phx-click={JS.push("dismiss", value: Map.merge(%{id: @id}, @params)) |> hide_toast("##{@id}")}
    >
      <.icon
        name="hero-x-mark-solid"
        class={[
          "toast-icon opacity-80 group-hover:opacity-70",
          dismiss_size(@size),
          @icon_class
        ]}
      />
    </button>
    """
  end

  defp border_position("end"), do: "pe-1.5 before:end-1"
  defp border_position("start"), do: "ps-1.5 before:start-1"
  defp border_position(params) when is_binary(params), do: params

  defp content_border("extra_small"), do: "before:w-px"
  defp content_border("small"), do: "before:w-0.5"
  defp content_border("medium"), do: "before:w-[3px]"
  defp content_border("large"), do: "before:w-1"
  defp content_border("extra_large"), do: "before:w-[5px]"
  defp content_border("none"), do: "before:content-none"
  defp content_border(params) when is_binary(params), do: params

  defp row_direction("none"), do: "flex-row"
  defp row_direction("reverse"), do: "flex-row-reverse"
  defp row_direction(_), do: row_direction("none")

  defp padding_size("extra_small"), do: "p-2"

  defp padding_size("small"), do: "p-3"

  defp padding_size("medium"), do: "p-4"

  defp padding_size("large"), do: "p-5"

  defp padding_size("extra_large"), do: "p-6"

  defp padding_size("none"), do: "p-0"

  defp padding_size(params) when is_binary(params), do: params

  defp width_class("extra_small"), do: "max-w-60"
  defp width_class("small"), do: "max-w-64"
  defp width_class("medium"), do: "max-w-72"
  defp width_class("large"), do: "max-w-80"
  defp width_class("extra_large"), do: "max-w-96"
  defp width_class("full"), do: "w-[calc(100%-10px)]"
  defp width_class(params) when is_binary(params), do: params

  defp dismiss_size("extra_small"), do: "size-3.5"
  defp dismiss_size("small"), do: "size-4"
  defp dismiss_size("medium"), do: "size-5"
  defp dismiss_size("large"), do: "size-6"
  defp dismiss_size("extra_large"), do: "size-7"
  defp dismiss_size(params) when is_binary(params), do: params

  defp vertical_position("extra_small", "top"), do: "top-1"
  defp vertical_position("small", "top"), do: "top-2"
  defp vertical_position("medium", "top"), do: "top-3"
  defp vertical_position("large", "top"), do: "top-4"
  defp vertical_position("extra_large", "top"), do: "top-5"

  defp vertical_position("extra_small", "bottom"), do: "bottom-1"
  defp vertical_position("small", "bottom"), do: "bottom-2"
  defp vertical_position("medium", "bottom"), do: "bottom-3"
  defp vertical_position("large", "bottom"), do: "bottom-4"
  defp vertical_position("extra_large", "bottom"), do: "bottom-5"

  defp vertical_position(params, _) when is_binary(params), do: params

  defp position_class("extra_small", "left"), do: "left-1 ml-1"
  defp position_class("small", "left"), do: "left-2 ml-2"
  defp position_class("medium", "left"), do: "left-3 ml-3"
  defp position_class("large", "left"), do: "left-4 ml-4"
  defp position_class("extra_large", "left"), do: "left-5 ml-5"

  defp position_class("extra_small", "right"), do: "right-1 mr-1"
  defp position_class("small", "right"), do: "right-2 mr-2"
  defp position_class("medium", "right"), do: "right-3 mr-3"
  defp position_class("large", "right"), do: "right-4 mr-4"
  defp position_class("extra_large", "right"), do: "right-5 mr-5"

  defp position_class(_, "center"), do: "left-1/2 -translate-x-1/2"

  defp position_class(params, _) when is_binary(params), do: params

  defp rounded_size("extra_small"), do: "rounded-sm"

  defp rounded_size("small"), do: "rounded"

  defp rounded_size("medium"), do: "rounded-md"

  defp rounded_size("large"), do: "rounded-lg"

  defp rounded_size("extra_large"), do: "rounded-xl"

  defp rounded_size("none"), do: "rounded-none"

  defp rounded_size(params) when is_binary(params), do: params

  defp space_class("none"), do: nil

  defp space_class("extra_small"), do: "space-y-2"

  defp space_class("small"), do: "space-y-3"

  defp space_class("medium"), do: "space-y-4"

  defp space_class("large"), do: "space-y-5"

  defp space_class("extra_large"), do: "space-y-6"

  defp space_class(params) when is_binary(params), do: params

  defp border_class(_, variant) when variant in ["default", "shadow", "gradient"],
    do: nil

  defp border_class("extra_small", _), do: "border"
  defp border_class("small", _), do: "border-2"
  defp border_class("medium", _), do: "border-[3px]"
  defp border_class("large", _), do: "border-4"
  defp border_class("extra_large", _), do: "border-[5px]"
  defp border_class(params, _) when is_binary(params), do: params

  defp color_variant("base", _) do
    [
      "bg-white text-base-text-light dark:bg-base-bg-dark dark:text-base-text-dark",
      "[&>.toast-content-wrapper]:before:bg-base-text-light dark:[&>.toast-content-wrapper]:before:bg-base-text-dark",
      "border-base-border-light dark:border-base-border-dark"
    ]
  end

  defp color_variant("default", "white") do
    ["bg-white text-black [&>.toast-content-wrapper]:before:bg-black"]
  end

  defp color_variant("default", "dark") do
    ["bg-default-dark-bg text-white [&>.toast-content-wrapper]:before:bg-white"]
  end

  defp color_variant("default", "natural") do
    [
      "bg-natural-light text-white dark:bg-natural-dark dark:text-black",
      "[&>.toast-content-wrapper]:before:bg-white dark:[&>.toast-content-wrapper]:before:bg-black"
    ]
  end

  defp color_variant("default", "primary") do
    [
      "bg-primary-light text-white dark:bg-primary-dark dark:text-black",
      "[&>.toast-content-wrapper]:before:bg-white dark:[&>.toast-content-wrapper]:before:bg-black"
    ]
  end

  defp color_variant("default", "secondary") do
    [
      "bg-secondary-light text-white dark:bg-secondary-dark dark:text-black",
      "[&>.toast-content-wrapper]:before:bg-white dark:[&>.toast-content-wrapper]:before:bg-black"
    ]
  end

  defp color_variant("default", "success") do
    [
      "bg-success-light text-white dark:bg-success-dark dark:text-black",
      "[&>.toast-content-wrapper]:before:bg-white dark:[&>.toast-content-wrapper]:before:bg-black"
    ]
  end

  defp color_variant("default", "warning") do
    [
      "bg-warning-light text-white dark:bg-warning-dark dark:text-black",
      "[&>.toast-content-wrapper]:before:bg-white dark:[&>.toast-content-wrapper]:before:bg-black"
    ]
  end

  defp color_variant("default", "danger") do
    [
      "bg-danger-light text-white dark:bg-danger-dark dark:text-black",
      "[&>.toast-content-wrapper]:before:bg-white dark:[&>.toast-content-wrapper]:before:bg-black"
    ]
  end

  defp color_variant("default", "info") do
    [
      "bg-info-light text-white dark:bg-info-dark dark:text-black",
      "[&>.toast-content-wrapper]:before:bg-white dark:[&>.toast-content-wrapper]:before:bg-black"
    ]
  end

  defp color_variant("default", "misc") do
    [
      "bg-misc-light text-white dark:bg-misc-dark dark:text-black",
      "[&>.toast-content-wrapper]:before:bg-white dark:[&>.toast-content-wrapper]:before:bg-black"
    ]
  end

  defp color_variant("default", "dawn") do
    [
      "bg-dawn-light text-white dark:bg-dawn-dark dark:text-black",
      "[&>.toast-content-wrapper]:before:bg-white dark:[&>.toast-content-wrapper]:before:bg-black"
    ]
  end

  defp color_variant("default", "silver") do
    [
      "bg-silver-light text-white dark:bg-silver-dark dark:text-black",
      "[&>.toast-content-wrapper]:before:bg-white dark:[&>.toast-content-wrapper]:before:bg-black"
    ]
  end

  defp color_variant("outline", "natural") do
    [
      "text-natural-light border-natural-light",
      "dark:text-natural-dark dark:border-natural-dark",
      "[&>.toast-content-wrapper]:before:bg-natural-light dark:[&>.toast-content-wrapper]:before:bg-natural-dark"
    ]
  end

  defp color_variant("outline", "primary") do
    [
      "text-primary-light border-primary-light",
      "dark:text-primary-dark dark:border-primary-dark",
      "[&>.toast-content-wrapper]:before:bg-primary-light dark:[&>.toast-content-wrapper]:before:bg-primary-dark"
    ]
  end

  defp color_variant("outline", "secondary") do
    [
      "text-secondary-light border-secondary-light",
      "dark:text-secondary-dark dark:border-secondary-dark",
      "[&>.toast-content-wrapper]:before:bg-secondary-light dark:[&>.toast-content-wrapper]:before:bg-secondary-dark"
    ]
  end

  defp color_variant("outline", "success") do
    [
      "text-success-light border-success-light",
      "dark:text-success-dark dark:border-success-dark",
      "[&>.toast-content-wrapper]:before:bg-success-light dark:[&>.toast-content-wrapper]:before:bg-success-dark"
    ]
  end

  defp color_variant("outline", "warning") do
    [
      "text-warning-light border-warning-light",
      "dark:text-warning-dark dark:border-warning-dark",
      "[&>.toast-content-wrapper]:before:bg-warning-light dark:[&>.toast-content-wrapper]:before:bg-warning-dark"
    ]
  end

  defp color_variant("outline", "danger") do
    [
      "text-danger-light border-danger-light",
      "dark:text-danger-dark dark:border-danger-dark",
      "[&>.toast-content-wrapper]:before:bg-danger-light dark:[&>.toast-content-wrapper]:before:bg-danger-dark"
    ]
  end

  defp color_variant("outline", "info") do
    [
      "text-info-light border-info-light",
      "dark:text-info-dark dark:border-info-dark",
      "[&>.toast-content-wrapper]:before:bg-info-light dark:[&>.toast-content-wrapper]:before:bg-info-dark"
    ]
  end

  defp color_variant("outline", "misc") do
    [
      "text-misc-light border-misc-light",
      "dark:text-misc-dark dark:border-misc-dark",
      "[&>.toast-content-wrapper]:before:bg-misc-light dark:[&>.toast-content-wrapper]:before:bg-misc-dark"
    ]
  end

  defp color_variant("outline", "dawn") do
    [
      "text-dawn-light border-dawn-light",
      "dark:text-dawn-dark dark:border-dawn-dark",
      "[&>.toast-content-wrapper]:before:bg-dawn-light dark:[&>.toast-content-wrapper]:before:bg-dawn-dark"
    ]
  end

  defp color_variant("outline", "silver") do
    [
      "text-silver-light border-silver-light",
      "dark:text-silver-dark dark:border-silver-dark",
      "[&>.toast-content-wrapper]:before:bg-silver-light dark:[&>.toast-content-wrapper]:before:bg-silver-dark"
    ]
  end

  defp color_variant("shadow", "natural") do
    [
      "bg-natural-light text-white dark:bg-natural-dark dark:text-black",
      "shadow-[0px_4px_6px_-4px_var(--color-shadow-natural)] shadow-[0px_10px_15px_-3px_var(--color-shadow-natural)] dark:shadow-none",
      "[&>.toast-content-wrapper]:before:bg-white dark:[&>.toast-content-wrapper]:before:bg-black"
    ]
  end

  defp color_variant("shadow", "primary") do
    [
      "bg-primary-light text-white dark:bg-primary-dark dark:text-black",
      "shadow-[0px_4px_6px_-4px_var(--color-shadow-primary)] shadow-[0px_10px_15px_-3px_var(--color-shadow-primary)] dark:shadow-none",
      "[&>.toast-content-wrapper]:before:bg-white dark:[&>.toast-content-wrapper]:before:bg-black"
    ]
  end

  defp color_variant("shadow", "secondary") do
    [
      "bg-secondary-light text-white dark:bg-secondary-dark dark:text-black",
      "shadow-[0px_4px_6px_-4px_var(--color-shadow-secondary)] shadow-[0px_10px_15px_-3px_var(--color-shadow-secondary)] dark:shadow-none",
      "[&>.toast-content-wrapper]:before:bg-white dark:[&>.toast-content-wrapper]:before:bg-black"
    ]
  end

  defp color_variant("shadow", "success") do
    [
      "bg-success-light text-white dark:bg-success-dark dark:text-black",
      "shadow-[0px_4px_6px_-4px_var(--color-shadow-success)] shadow-[0px_10px_15px_-3px_var(--color-shadow-success)] dark:shadow-none",
      "[&>.toast-content-wrapper]:before:bg-white dark:[&>.toast-content-wrapper]:before:bg-black"
    ]
  end

  defp color_variant("shadow", "warning") do
    [
      "bg-warning-light text-white dark:bg-warning-dark dark:text-black",
      "shadow-[0px_4px_6px_-4px_var(--color-shadow-warning)] shadow-[0px_10px_15px_-3px_var(--color-shadow-warning)] dark:shadow-none",
      "[&>.toast-content-wrapper]:before:bg-white dark:[&>.toast-content-wrapper]:before:bg-black"
    ]
  end

  defp color_variant("shadow", "danger") do
    [
      "bg-danger-light text-white dark:bg-danger-dark dark:text-black",
      "shadow-[0px_4px_6px_-4px_var(--color-shadow-danger)] shadow-[0px_10px_15px_-3px_var(--color-shadow-danger)] dark:shadow-none",
      "[&>.toast-content-wrapper]:before:bg-white dark:[&>.toast-content-wrapper]:before:bg-black"
    ]
  end

  defp color_variant("shadow", "info") do
    [
      "bg-info-light text-white dark:bg-info-dark dark:text-black",
      "shadow-[0px_4px_6px_-4px_var(--color-shadow-info)] shadow-[0px_10px_15px_-3px_var(--color-shadow-info)] dark:shadow-none",
      "[&>.toast-content-wrapper]:before:bg-white dark:[&>.toast-content-wrapper]:before:bg-black"
    ]
  end

  defp color_variant("shadow", "misc") do
    [
      "bg-misc-light text-white dark:bg-misc-dark dark:text-black",
      "shadow-[0px_4px_6px_-4px_var(--color-shadow-misc)] shadow-[0px_10px_15px_-3px_var(--color-shadow-misc)] dark:shadow-none",
      "[&>.toast-content-wrapper]:before:bg-white dark:[&>.toast-content-wrapper]:before:bg-black"
    ]
  end

  defp color_variant("shadow", "dawn") do
    [
      "bg-dawn-light text-white dark:bg-dawn-dark dark:text-black",
      "shadow-[0px_4px_6px_-4px_var(--color-shadow-dawn)] shadow-[0px_10px_15px_-3px_var(--color-shadow-dawn)] dark:shadow-none",
      "[&>.toast-content-wrapper]:before:bg-white dark:[&>.toast-content-wrapper]:before:bg-black"
    ]
  end

  defp color_variant("shadow", "silver") do
    [
      "bg-silver-light text-white dark:bg-silver-dark dark:text-black",
      "shadow-[0px_4px_6px_-4px_var(--color-shadow-silver)] shadow-[0px_10px_15px_-3px_var(--color-shadow-silver)] dark:shadow-none",
      "[&>.toast-content-wrapper]:before:bg-white dark:[&>.toast-content-wrapper]:before:bg-black"
    ]
  end

  defp color_variant("bordered", "white") do
    [
      "bg-white text-black border-bordered-white-border",
      "[&>.toast-content-wrapper]:before:bg-black"
    ]
  end

  defp color_variant("bordered", "dark") do
    [
      "bg-bordered-dark-bg text-white border-bordered-dark-border",
      "[&>.toast-content-wrapper]:before:bg-white"
    ]
  end

  defp color_variant("bordered", "natural") do
    [
      "text-natural-bordered-text-light border-natural-bordered-text-light bg-natural-bordered-bg-light",
      "dark:text-natural-bordered-text-dark dark:border-natural-border-dark dark:bg-natural-bordered-bg-dark",
      "[&>.toast-content-wrapper]:before:bg-natural-bordered-text-light dark:[&>.toast-content-wrapper]:before:bg-natural-bordered-text-dark"
    ]
  end

  defp color_variant("bordered", "primary") do
    [
      "text-primary-bordered-text-light border-primary-bordered-text-light bg-primary-bordered-bg-light",
      "dark:text-primary-bordered-text-dark dark:border-primary-bordered-text-dark dark:bg-primary-bordered-bg-dark",
      "[&>.toast-content-wrapper]:before:bg-primary-bordered-text-light dark:[&>.toast-content-wrapper]:before:bg-primary-bordered-text-dark"
    ]
  end

  defp color_variant("bordered", "secondary") do
    [
      "text-secondary-bordered-text-light border-secondary-bordered-text-light bg-secondary-bordered-bg-light",
      "dark:text-secondary-bordered-text-dark dark:border-secondary-bordered-text-dark dark:bg-secondary-bordered-bg-dark",
      "[&>.toast-content-wrapper]:before:bg-secondary-bordered-text-light dark:[&>.toast-content-wrapper]:before:bg-secondary-bordered-text-dark"
    ]
  end

  defp color_variant("bordered", "success") do
    [
      "text-success-bordered-text-light border-success-bordered-text-light bg-success-bordered-bg-light",
      "dark:text-success-bordered-text-dark dark:border-success-bordered-text-dark dark:bg-success-bordered-bg-dark",
      "[&>.toast-content-wrapper]:before:bg-success-bordered-text-light dark:[&>.toast-content-wrapper]:before:bg-success-bordered-text-dark"
    ]
  end

  defp color_variant("bordered", "warning") do
    [
      "text-warning-bordered-text-light border-warning-bordered-text-light bg-warning-bordered-bg-light",
      "dark:text-warning-bordered-text-dark dark:border-warning-bordered-text-dark dark:bg-warning-bordered-bg-dark",
      "[&>.toast-content-wrapper]:before:bg-warning-bordered-text-light dark:[&>.toast-content-wrapper]:before:bg-warning-bordered-text-dark"
    ]
  end

  defp color_variant("bordered", "danger") do
    [
      "text-danger-bordered-text-light border-danger-bordered-text-light bg-danger-bordered-bg-light",
      "dark:text-danger-bordered-text-dark dark:border-danger-bordered-text-dark dark:bg-danger-bordered-bg-dark",
      "[&>.toast-content-wrapper]:before:bg-danger-bordered-text-light dark:[&>.toast-content-wrapper]:before:bg-danger-bordered-text-dark"
    ]
  end

  defp color_variant("bordered", "info") do
    [
      "text-info-bordered-text-light border-info-bordered-text-light bg-info-bordered-bg-light",
      "dark:text-info-bordered-text-dark dark:border-info-bordered-text-dark dark:bg-info-bordered-bg-dark",
      "[&>.toast-content-wrapper]:before:bg-info-bordered-text-light dark:[&>.toast-content-wrapper]:before:bg-info-bordered-text-dark"
    ]
  end

  defp color_variant("bordered", "misc") do
    [
      "text-misc-bordered-text-light border-misc-bordered-text-light bg-misc-bordered-bg-light",
      "dark:text-misc-bordered-text-dark dark:border-misc-bordered-text-dark dark:bg-misc-bordered-bg-dark",
      "[&>.toast-content-wrapper]:before:bg-misc-bordered-text-light dark:[&>.toast-content-wrapper]:before:bg-misc-bordered-text-dark"
    ]
  end

  defp color_variant("bordered", "dawn") do
    [
      "text-dawn-bordered-text-light border-dawn-bordered-text-light bg-dawn-bordered-bg-light",
      "dark:text-dawn-bordered-text-dark dark:border-dawn-bordered-text-dark dark:bg-dawn-bordered-bg-dark",
      "[&>.toast-content-wrapper]:before:bg-dawn-bordered-text-light dark:[&>.toast-content-wrapper]:before:bg-dawn-bordered-text-dark"
    ]
  end

  defp color_variant("bordered", "silver") do
    [
      "text-silver-bordered-text-light border-silver-bordered-text-light bg-silver-bordered-bg-light",
      "dark:text-silver-bordered-text-dark dark:border-silver-bordered-text-dark dark:bg-silver-bordered-bg-dark",
      "[&>.toast-content-wrapper]:before:bg-silver-bordered-text-light dark:[&>.toast-content-wrapper]:before:bg-silver-bordered-text-dark"
    ]
  end

  defp color_variant("gradient", "natural") do
    [
      "bg-gradient-to-br from-gradient-natural-from-light to-gradient-natural-to-light text-white",
      "dark:from-gradient-natural-from-dark dark:to-white dark:text-black",
      "[&>.toast-content-wrapper]:before:bg-white dark:[&>.toast-content-wrapper]:before:bg-black"
    ]
  end

  defp color_variant("gradient", "primary") do
    [
      "bg-gradient-to-br from-gradient-primary-from-light to-gradient-primary-to-light text-white",
      "dark:from-gradient-primary-from-dark dark:to-gradient-primary-to-dark dark:text-black",
      "[&>.toast-content-wrapper]:before:bg-white dark:[&>.toast-content-wrapper]:before:bg-black"
    ]
  end

  defp color_variant("gradient", "secondary") do
    [
      "bg-gradient-to-br from-gradient-secondary-from-light to-gradient-secondary-to-light text-white",
      "dark:from-gradient-secondary-from-dark dark:to-gradient-secondary-to-dark dark:text-black",
      "[&>.toast-content-wrapper]:before:bg-white dark:[&>.toast-content-wrapper]:before:bg-black"
    ]
  end

  defp color_variant("gradient", "success") do
    [
      "bg-gradient-to-br from-gradient-success-from-light to-gradient-success-to-light text-white",
      "dark:from-gradient-success-from-dark dark:to-gradient-success-to-dark dark:text-black",
      "[&>.toast-content-wrapper]:before:bg-white dark:[&>.toast-content-wrapper]:before:bg-black"
    ]
  end

  defp color_variant("gradient", "warning") do
    [
      "bg-gradient-to-br from-gradient-warning-from-light to-gradient-warning-to-light text-white",
      "dark:from-gradient-warning-from-dark dark:to-gradient-warning-to-dark dark:text-black",
      "[&>.toast-content-wrapper]:before:bg-white dark:[&>.toast-content-wrapper]:before:bg-black"
    ]
  end

  defp color_variant("gradient", "danger") do
    [
      "bg-gradient-to-br from-gradient-danger-from-light to-gradient-danger-to-light text-white",
      "dark:from-gradient-danger-from-dark dark:to-gradient-danger-to-dark dark:text-black",
      "[&>.toast-content-wrapper]:before:bg-white dark:[&>.toast-content-wrapper]:before:bg-black"
    ]
  end

  defp color_variant("gradient", "info") do
    [
      "bg-gradient-to-br from-gradient-info-from-light to-gradient-info-to-light text-white",
      "dark:from-gradient-info-from-dark dark:to-gradient-info-to-dark dark:text-black",
      "[&>.toast-content-wrapper]:before:bg-white dark:[&>.toast-content-wrapper]:before:bg-black"
    ]
  end

  defp color_variant("gradient", "misc") do
    [
      "bg-gradient-to-br from-gradient-misc-from-light to-gradient-misc-to-light text-white",
      "dark:from-gradient-misc-from-dark dark:to-gradient-misc-to-dark dark:text-black",
      "[&>.toast-content-wrapper]:before:bg-white dark:[&>.toast-content-wrapper]:before:bg-black"
    ]
  end

  defp color_variant("gradient", "dawn") do
    [
      "bg-gradient-to-br from-gradient-dawn-from-light to-gradient-dawn-to-light text-white",
      "dark:from-gradient-dawn-from-dark dark:to-gradient-dawn-to-dark dark:text-black",
      "[&>.toast-content-wrapper]:before:bg-white dark:[&>.toast-content-wrapper]:before:bg-black"
    ]
  end

  defp color_variant("gradient", "silver") do
    [
      "bg-gradient-to-br from-gradient-silver-from-light to-gradient-silver-to-light text-white",
      "dark:from-gradient-silver-from-dark dark:to-gradient-silver-to-dark dark:text-black",
      "[&>.toast-content-wrapper]:before:bg-white dark:[&>.toast-content-wrapper]:before:bg-black"
    ]
  end

  defp color_variant(params, _) when is_binary(params), do: params

  ## JS Commands

  @doc """
  Displays a toast notification.

  This function shows a toast notification by applying a specified transition effect to the
  element identified by the provided `selector`. It utilizes the `JS.show/2` function to handle
  the showing animation with a duration of 300 milliseconds.

  ## Parameters

  - `js` (optional): A `JS` struct that can be used to chain further JavaScript actions.
  - `selector`: A string representing the CSS selector for the toast element to be displayed.

  ## Example

  ```elixir
  show_toast(js, "#my-toast")
  ```

  This documentation provides a clear explanation of what the function does,
  its parameters, and an example usage.
  """
  def show_toast(js \\ %JS{}, selector) do
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
  Hides a toast notification.

  This function hides a toast notification by applying a specified transition effect to the
  element identified by the provided `selector`. It utilizes the `JS.hide/2` function to handle
  the hiding animation with a duration of 200 milliseconds.

  ## Parameters

  - `js` (optional): A `JS` struct that can be used to chain further JavaScript actions.
  - `selector`: A string representing the CSS selector for the toast element to be hidden.

  ## Example

  ```elixir
  hide_toast(js, "#my-toast")
  ```

  This documentation clearly outlines the purpose of the function, its parameters,
  and an example of how to use it.
  """
  def hide_toast(js \\ %JS{}, selector) do
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
