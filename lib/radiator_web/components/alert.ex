defmodule RadiatorWeb.Components.Alert do
  @moduledoc """
  RadiatorWeb.Components.Alert module provides collection of alert components and helper functions for managing and displaying alerts
  in a **Phoenix LiveView** application.

  This module provides a set of customizable components for rendering various types of alerts,
  such as information, warning, and error messages. It also includes functions to show and hide
  alerts with smooth transition effects.

  ## Components

    - `flash/1`: Renders a flash notice with support for different styles and sizes.
    - `flash_group/1`: Renders a group of flash messages with predefined content.
    - `alert/1`: Renders a generic alert component with customizable styles and icons.

  ## Functions

    - `show_alert/2`: Displays an alert element using a defined transition effect.
    - `hide_alert/2`: Hides an alert element using a defined transition effect.

  ## Configuration

  The module offers various configuration options through attributes and slots to allow
  fine-grained control over the appearance and behavior of alerts. Attributes like `variant`,
  `kind`, `position`, and `rounded` can be used to modify the styling, while slots provide
  flexibility in rendering custom content within alerts.

  **Documentation:** https://mishka.tools/chelekom/docs/alert
  """
  use Phoenix.Component
  use Gettext, backend: RadiatorWeb.Gettext
  alias Phoenix.LiveView.JS
  import RadiatorWeb.Components.Icon, only: [icon: 1]
  import Phoenix.LiveView.Utils, only: [random_id: 0]

  @doc type: :component
  @doc """
  The `flash` component is used to display flash messages with various styling options.
  It supports customizable attributes such as `kind`, `variant`, and `position` for tailored appearance.

  ## Examples

  ```elixir
  <.flash kind={:info} title="This is info title" width="full" size="large">
    <p>This is info Description</p>
  </.flash>

  <.flash kind={:error} title="This is misc title" width="large" size="large" flash={@flash} />

  <.flash_group flash={@flash} />

  <.flash kind={:info} phx-mounted={show("#flash")}>Welcome Back!</.flash>
  ```
  """
  attr :id, :string, doc: "A unique identifier is used to manage state and interaction"
  attr :flash, :map, default: %{}, doc: "the map of flash messages to display"
  attr :title, :string, default: nil, doc: "Specifies the title of the element"
  attr :kind, :atom, default: :natural, doc: "used for styling and flash lookup"

  attr :rest, :global,
    doc:
      "Global attributes can define defaults which are merged with attributes provided by the caller"

  attr :variant, :string, default: "base", doc: "Determines the style"
  attr :position, :string, default: "", doc: "Determines the element position"
  attr :width, :string, default: "full", doc: "Determines the element width"
  attr :border, :string, default: "extra_small", doc: "Determines the element border width"
  attr :z_index, :string, default: "z-50", doc: "custom z-index"
  attr :padding, :string, default: "small", doc: "Determines the element padding size"

  attr :size, :string,
    default: "medium",
    doc:
      "Determines the overall size of the elements, including padding, font size, and other items"

  attr :rounded, :string, default: "small", doc: "Determines the border radius"

  attr :font_weight, :string,
    default: "font-normal",
    doc: "Determines custom class for the font weight"

  attr :icon, :any,
    default: "hero-chat-bubble-bottom-center-text",
    doc: "Icon displayed alongside of an item"

  attr :class, :string, default: nil, doc: "Custom CSS class for additional styling"

  attr :content_class, :string,
    default: nil,
    doc: "Custom CSS class for additional styling for content"

  attr :title_class, :string,
    default: "flex items-center gap-1.5 leading-6 font-semibold mb-1",
    doc: "Custom CSS class for additional styling to title"

  attr :button_class, :string,
    default: "p-2",
    doc: "Custom CSS class for additional styling to title"

  slot :inner_block, doc: "Inner block that renders HEEx content"

  def flash(assigns) do
    assigns = assign_new(assigns, :id, fn -> "flash-#{assigns.variant}-#{assigns.kind}" end)

    ~H"""
    <div
      :if={msg = render_slot(@inner_block) || Phoenix.Flash.get(@flash, @kind)}
      id={@id}
      phx-click={JS.push("lv:clear-flash", value: %{key: @kind}) |> hide_alert("##{@id}")}
      role="alert"
      aria-live="assertive"
      aria-labelledby={@title && @id && "#{@id}-title"}
      class={[
        "flash-alert leading-5",
        border_class(@border, @variant),
        color_variant(@variant, @kind),
        position_class(@position),
        rounded_size(@rounded),
        width_class(@width),
        padding_size(@padding),
        content_size(@size),
        @font_weight,
        @z_index,
        @class
      ]}
      {@rest}
    >
      <div class="flex items-center justify-between gap-2">
        <div>
          <div :if={@title} class={@title_class} id={@id && "#{@id}-title"}>
            <.icon :if={!is_nil(@icon)} name={@icon} class="alert-icon" aria-hidden="true" /> {@title}
          </div>

          <div class={@content_class}>{msg}</div>
        </div>

        <button type="button" class={["group shrink-0", @button_class]} aria-label={gettext("close")}>
          <.icon name="hero-x-mark-solid" class="alert-icon opacity-40 group-hover:opacity-70" />
        </button>
      </div>
    </div>
    """
  end

  @doc """
  Shows the flash group with standard titles and content.

  ## Example
  ```
  <.flash_group flash={@flash} />
  ```
  """
  @doc type: :component
  attr :id, :string,
    default: "flash-group",
    doc: "A unique identifier is used to manage state and interaction"

  attr :variant, :string, default: "bordered", doc: "Determines the style"
  attr :position, :string, default: "top_right", doc: "Position of flashes"
  attr :class, :string, default: nil, doc: "Custom classes"
  attr :z_index, :string, default: "z-50", doc: "custom z-index"
  attr :flash, :map, required: true, doc: "the map of flash messages"

  attr :rest, :global,
    doc:
      "Global attributes can define defaults which are merged with attributes provided by the caller"

  def flash_group(assigns) do
    ~H"""
    <div
      id={@id}
      class={["[&_.flash-alert:not(:first-child)]:mt-3", position_class(@position), @z_index, @class]}
      {@rest}
    >
      <.flash
        kind={:info}
        title={gettext("Success!")}
        flash={@flash}
        variant={@variant}
        width="medium"
      />
      <.flash
        kind={:error}
        title={gettext("Error!")}
        flash={@flash}
        variant={@variant}
        width="medium"
      />
      <.flash
        id="client-error"
        kind={:error}
        variant={@variant}
        title={gettext("We can't find the internet")}
        phx-disconnected={show_alert(".phx-client-error #client-error")}
        phx-connected={hide_alert("#client-error")}
        width="medium"
        hidden
      >
        {gettext("Attempting to reconnect")}
        <.icon name="hero-arrow-path" class="ms-1 h-3 w-3 animate-spin" />
      </.flash>

      <.flash
        id="server-error"
        kind={:error}
        variant={@variant}
        title={gettext("Something went wrong!")}
        phx-disconnected={show_alert(".phx-server-error #server-error")}
        phx-connected={hide_alert("#server-error")}
        width="medium"
        hidden
      >
        {gettext("Hang in there while we get back on track")}
        <.icon name="hero-arrow-path" class="ms-1 h-3 w-3 animate-spin" />
      </.flash>
    </div>
    """
  end

  @doc """
  The `alert` component is used to display alert messages with various styling options.
  It supports attributes like `kind`, `variant`, and `position` to control its appearance and behavior.

  ## Examples

  ```elixir
  <.alert kind={:info} title="This is info title" width="full" size="large">
    <p>This is info Description</p>
  </.alert>

  <.alert kind={:misc} title="This is misc title" width="full" />

  <.alert kind={:danger} title="This is title" width="large" size="extra_small" rounded="extra_large">
    This is Danger
  </.alert>

  <.alert kind={:success} title="This is success title" size="extra_large" icon={nil}>
    This is Success
  </.alert>

  <.alert kind={:primary}>This is Primary</.alert>
  ```
  """
  @doc type: :component
  attr :id, :string,
    default: nil,
    doc: "A unique identifier is used to manage state and interaction"

  attr :title, :string, default: nil, doc: "Specifies the title of the element"
  attr :kind, :atom, default: :natural, doc: "used for styling and flash lookup"
  attr :variant, :string, default: "default", doc: "Determines the style"
  attr :position, :string, default: "", doc: "Determines the element position"
  attr :width, :string, default: "full", doc: "Determines the element width"
  attr :border, :string, default: "extra_small", doc: "Determines the element border width"
  attr :padding, :string, default: "small", doc: "Determines the element padding size"
  attr :z_index, :string, default: "z-50", doc: "custom z-index"

  attr :size, :string,
    default: "medium",
    doc:
      "Determines the overall size of the elements, including padding, font size, and other items"

  attr :rounded, :string, default: "small", doc: "Determines the border radius"

  attr :font_weight, :string,
    default: "font-normal",
    doc: "Determines custom class for the font weight"

  attr :icon, :any,
    default: "hero-chat-bubble-bottom-center-text",
    doc: "Icon displayed alongside of an item"

  attr :class, :string, default: nil, doc: "Custom CSS class for additional styling"

  attr :title_class, :string,
    default: "flex items-center gap-1.5 leading-6 font-semibold mb-1",
    doc: "Custom CSS class for additional styling to title"

  attr :icon_class, :string,
    default: nil,
    doc: "Custom CSS class for additional styling to icon"

  slot :inner_block, doc: "Inner block that renders HEEx content"

  attr :rest, :global,
    doc:
      "Global attributes can define defaults which are merged with attributes provided by the caller"

  def alert(assigns) do
    assigns = assigns |> assign_new(:id, fn -> "alert-#{random_id()}" end)

    ~H"""
    <div
      id={@id}
      role="alert"
      aria-live="assertive"
      aria-labelledby={@title && @id && "#{@id}-title"}
      class={[
        border_class(@border, @variant),
        color_variant(@variant, @kind),
        position_class(@position),
        rounded_size(@rounded),
        width_class(@width),
        padding_size(@padding),
        content_size(@size),
        @font_weight,
        @z_index,
        @class
      ]}
      {@rest}
    >
      <div :if={@title} class={@title_class} id={@id && "#{@id}-title"}>
        <.icon
          :if={!is_nil(@icon)}
          name={@icon}
          class={["alert-icon", @icon_class]}
          aria-hidden="true"
        /> {@title}
      </div>

      {render_slot(@inner_block)}
    </div>
    """
  end

  defp padding_size("extra_small"), do: "p-2"

  defp padding_size("small"), do: "p-3"

  defp padding_size("medium"), do: "p-4"

  defp padding_size("large"), do: "p-5"

  defp padding_size("extra_large"), do: "p-6"

  defp padding_size("none"), do: nil

  defp padding_size(params) when is_binary(params), do: params

  defp rounded_size("extra_small"), do: "rounded-sm"

  defp rounded_size("small"), do: "rounded"

  defp rounded_size("medium"), do: "rounded-md"

  defp rounded_size("large"), do: "rounded-lg"

  defp rounded_size("extra_large"), do: "rounded-xl"

  defp rounded_size("full"), do: "rounded-full"

  defp rounded_size("none"), do: nil

  defp rounded_size(params) when is_binary(params), do: params

  defp width_class("extra_small"), do: "w-60"
  defp width_class("small"), do: "w-64"
  defp width_class("medium"), do: "w-72"
  defp width_class("large"), do: "w-80"
  defp width_class("extra_large"), do: "w-96"
  defp width_class("full"), do: "w-full"
  defp width_class("fit"), do: "w-fit"
  defp width_class(params) when is_binary(params), do: params

  defp content_size("extra_small"), do: "text-[12px] [&_.alert-icon]:size-3.5"

  defp content_size("small"), do: "text-[13px] [&_.alert-icon]:size-4"

  defp content_size("medium"), do: "text-[14px] [&_.alert-icon]:size-5"

  defp content_size("large"), do: "text-[15px] [&_.alert-icon]:size-6"

  defp content_size("extra_large"), do: "text-[16px] [&_.alert-icon]:size-7"

  defp content_size(params) when is_binary(params), do: params

  defp position_class("top_left"), do: "fixed top-2 left-0 ml-2"
  defp position_class("top_right"), do: "fixed top-2 right-0 mr-2"
  defp position_class("bottom_left"), do: "fixed bottom-2 left-0 ml-2"
  defp position_class("bottom_right"), do: "fixed bottom-2 right-0 mr-2"
  defp position_class(params) when is_binary(params), do: params

  defp border_class(_, variant)
       when variant in [
              "default",
              "shadow",
              "gradient"
            ],
       do: nil

  defp border_class("none", _), do: nil
  defp border_class("extra_small", _), do: "border"
  defp border_class("small", _), do: "border-2"
  defp border_class("medium", _), do: "border-[3px]"
  defp border_class("large", _), do: "border-4"
  defp border_class("extra_large", _), do: "border-[5px]"
  defp border_class(params, _) when is_binary(params), do: params

  defp color_variant("base", _) do
    [
      "bg-white text-base-text-light border-base-border-light shadow-sm",
      "dark:bg-base-bg-dark dark:text-base-text-dark dark:border-base-border-dark"
    ]
  end

  defp color_variant("default", :white) do
    ["bg-white text-black"]
  end

  defp color_variant("default", :dark) do
    ["bg-default-dark-bg text-white"]
  end

  defp color_variant("default", :natural) do
    ["bg-natural-light text-white dark:bg-natural-dark dark:text-black"]
  end

  defp color_variant("default", :primary) do
    ["bg-primary-light text-white dark:bg-primary-dark dark:text-black"]
  end

  defp color_variant("default", :secondary) do
    ["bg-secondary-light text-white dark:bg-secondary-dark dark:text-black"]
  end

  defp color_variant("default", :success) do
    ["bg-success-light text-white dark:bg-success-dark dark:text-black"]
  end

  defp color_variant("default", :warning) do
    ["bg-warning-light text-white dark:bg-warning-dark dark:text-black"]
  end

  defp color_variant("default", type) when type in [:error, :danger] do
    ["bg-danger-light text-white dark:bg-danger-dark dark:text-black"]
  end

  defp color_variant("default", :info) do
    ["bg-info-light text-white dark:bg-info-dark dark:text-black"]
  end

  defp color_variant("default", :misc) do
    ["bg-misc-light text-white dark:bg-misc-dark dark:text-black"]
  end

  defp color_variant("default", :dawn) do
    ["bg-dawn-light text-white dark:bg-dawn-dark dark:text-black"]
  end

  defp color_variant("default", :silver) do
    ["bg-silver-light text-white dark:bg-silver-dark dark:text-black"]
  end

  defp color_variant("outline", :natural) do
    [
      "text-natural-light border-natural-light",
      "dark:text-natural-dark dark:border-natural-dark"
    ]
  end

  defp color_variant("outline", :primary) do
    [
      "text-primary-light border-primary-light",
      "dark:text-primary-dark dark:border-primary-dark"
    ]
  end

  defp color_variant("outline", :secondary) do
    [
      "text-secondary-light border-secondary-light",
      "dark:text-secondary-dark dark:border-secondary-dark"
    ]
  end

  defp color_variant("outline", :success) do
    [
      "text-success-light border-success-light",
      "dark:text-success-dark dark:border-success-dark"
    ]
  end

  defp color_variant("outline", :warning) do
    [
      "text-warning-light border-warning-light",
      "dark:text-warning-dark dark:border-warning-dark"
    ]
  end

  defp color_variant("outline", type) when type in [:error, :danger] do
    [
      "text-danger-light border-danger-light",
      "dark:text-danger-dark dark:border-danger-dark"
    ]
  end

  defp color_variant("outline", :info) do
    [
      "text-info-light border-info-light",
      "dark:text-info-dark dark:border-info-dark"
    ]
  end

  defp color_variant("outline", :misc) do
    [
      "text-misc-light border-misc-light",
      "dark:text-misc-dark dark:border-misc-dark"
    ]
  end

  defp color_variant("outline", :dawn) do
    [
      "text-dawn-light border-dawn-light",
      "dark:text-dawn-dark dark:border-dawn-dark"
    ]
  end

  defp color_variant("outline", :silver) do
    [
      "text-silver-light border-silver-light",
      "dark:text-silver-dark dark:border-silver-dark"
    ]
  end

  defp color_variant("shadow", :natural) do
    [
      "bg-natural-light text-white dark:bg-natural-dark dark:text-black",
      "shadow-[0px_4px_6px_-4px_var(--color-shadow-natural)] shadow-[0px_10px_15px_-3px_var(--color-shadow-natural)] dark:shadow-none"
    ]
  end

  defp color_variant("shadow", :primary) do
    [
      "bg-primary-light text-white dark:bg-primary-dark dark:text-black",
      "shadow-[0px_4px_6px_-4px_var(--color-shadow-primary)] shadow-[0px_10px_15px_-3px_var(--color-shadow-primary)] dark:shadow-none"
    ]
  end

  defp color_variant("shadow", :secondary) do
    [
      "bg-secondary-light text-white dark:bg-secondary-dark dark:text-black",
      "shadow-[0px_4px_6px_-4px_var(--color-shadow-secondary)] shadow-[0px_10px_15px_-3px_var(--color-shadow-secondary)] dark:shadow-none"
    ]
  end

  defp color_variant("shadow", :success) do
    [
      "bg-success-light text-white dark:bg-success-dark dark:text-black",
      "shadow-[0px_4px_6px_-4px_var(--color-shadow-success)] shadow-[0px_10px_15px_-3px_var(--color-shadow-success)] dark:shadow-none"
    ]
  end

  defp color_variant("shadow", :warning) do
    [
      "bg-warning-light text-white dark:bg-warning-dark dark:text-black",
      "shadow-[0px_4px_6px_-4px_var(--color-shadow-warning)] shadow-[0px_10px_15px_-3px_var(--color-shadow-warning)] dark:shadow-none"
    ]
  end

  defp color_variant("shadow", type) when type in [:error, :danger] do
    [
      "bg-danger-light text-white dark:bg-danger-dark dark:text-black",
      "shadow-[0px_4px_6px_-4px_var(--color-shadow-danger)] shadow-[0px_10px_15px_-3px_var(--color-shadow-danger)] dark:shadow-none"
    ]
  end

  defp color_variant("shadow", :info) do
    [
      "bg-info-light text-white dark:bg-info-dark dark:text-black",
      "shadow-[0px_4px_6px_-4px_var(--color-shadow-info)] shadow-[0px_10px_15px_-3px_var(--color-shadow-info)] dark:shadow-none"
    ]
  end

  defp color_variant("shadow", :misc) do
    [
      "bg-misc-light text-white dark:bg-misc-dark dark:text-black",
      "shadow-[0px_4px_6px_-4px_var(--color-shadow-misc)] shadow-[0px_10px_15px_-3px_var(--color-shadow-misc)] dark:shadow-none"
    ]
  end

  defp color_variant("shadow", :dawn) do
    [
      "bg-dawn-light text-white dark:bg-dawn-dark dark:text-black",
      "shadow-[0px_4px_6px_-4px_var(--color-shadow-dawn)] shadow-[0px_10px_15px_-3px_var(--color-shadow-dawn)] dark:shadow-none"
    ]
  end

  defp color_variant("shadow", :silver) do
    [
      "bg-silver-light text-white dark:bg-silver-dark dark:text-black",
      "shadow-[0px_4px_6px_-4px_var(--color-shadow-silver)] shadow-[0px_10px_15px_-3px_var(--color-shadow-silver)] dark:shadow-none"
    ]
  end

  defp color_variant("bordered", :white) do
    ["bg-white text-black border-bordered-white-border"]
  end

  defp color_variant("bordered", :dark) do
    ["bg-bordered-dark-bg text-white border-bordered-dark-border"]
  end

  defp color_variant("bordered", :natural) do
    [
      "text-natural-bordered-text-light border-natural-border-light bg-natural-bordered-bg-light",
      "dark:text-natural-bordered-text-dark dark:border-natural-border-dark dark:bg-natural-bordered-bg-dark"
    ]
  end

  defp color_variant("bordered", :primary) do
    [
      "text-primary-bordered-text-light border-primary-bordered-text-light bg-primary-bordered-bg-light",
      "dark:text-primary-bordered-text-dark dark:border-primary-bordered-text-dark dark:bg-primary-bordered-bg-dark"
    ]
  end

  defp color_variant("bordered", :secondary) do
    [
      "text-secondary-bordered-text-light border-secondary-bordered-text-light bg-secondary-bordered-bg-light",
      "dark:text-secondary-bordered-text-dark dark:border-secondary-bordered-text-dark dark:bg-secondary-bordered-bg-dark"
    ]
  end

  defp color_variant("bordered", :success) do
    [
      "text-success-bordered-text-light border-success-bordered-text-light bg-success-bordered-bg-light",
      "dark:text-success-bordered-text-dark dark:border-success-bordered-text-dark dark:bg-success-bordered-bg-dark"
    ]
  end

  defp color_variant("bordered", :warning) do
    [
      "text-warning-bordered-text-light border-warning-bordered-text-light bg-warning-bordered-bg-light",
      "dark:text-warning-bordered-text-dark dark:border-warning-bordered-text-dark dark:bg-warning-bordered-bg-dark"
    ]
  end

  defp color_variant("bordered", type) when type in [:error, :danger] do
    [
      "text-danger-bordered-text-light border-danger-bordered-text-light bg-danger-bordered-bg-light",
      "dark:text-danger-bordered-text-dark dark:border-danger-bordered-text-dark dark:bg-danger-bordered-bg-dark"
    ]
  end

  defp color_variant("bordered", :info) do
    [
      "text-info-bordered-text-light border-info-bordered-text-light bg-info-bordered-bg-light",
      "dark:text-info-bordered-text-dark dark:border-info-bordered-text-dark dark:bg-info-bordered-bg-dark"
    ]
  end

  defp color_variant("bordered", :misc) do
    [
      "text-misc-bordered-text-light border-misc-bordered-text-light bg-misc-bordered-bg-light",
      "dark:text-misc-bordered-text-dark dark:border-misc-bordered-text-dark dark:bg-misc-bordered-bg-dark"
    ]
  end

  defp color_variant("bordered", :dawn) do
    [
      "text-dawn-bordered-text-light border-dawn-bordered-text-light bg-dawn-bordered-bg-light",
      "dark:text-dawn-bordered-text-dark dark:border-dawn-bordered-text-dark dark:bg-dawn-bordered-bg-dark"
    ]
  end

  defp color_variant("bordered", :silver) do
    [
      "text-silver-bordered-text-light border-silver-bordered-text-light bg-silver-bordered-bg-light",
      "dark:text-silver-bordered-text-dark dark:border-silver-bordered-text-dark dark:bg-silver-bordered-bg-dark"
    ]
  end

  defp color_variant("gradient", :natural) do
    [
      "bg-gradient-to-br from-gradient-natural-from-light to-gradient-natural-to-light text-white",
      "dark:from-gradient-natural-from-dark dark:to-white dark:text-black"
    ]
  end

  defp color_variant("gradient", :primary) do
    [
      "bg-gradient-to-br from-gradient-primary-from-light to-gradient-primary-to-light text-white",
      "dark:from-gradient-primary-from-dark dark:to-gradient-primary-to-dark dark:text-black"
    ]
  end

  defp color_variant("gradient", :secondary) do
    [
      "bg-gradient-to-br from-gradient-secondary-from-light to-gradient-secondary-to-light text-white",
      "dark:from-gradient-secondary-from-dark dark:to-gradient-secondary-to-dark dark:text-black"
    ]
  end

  defp color_variant("gradient", :success) do
    [
      "bg-gradient-to-br from-gradient-success-from-light to-gradient-success-to-light text-white",
      "dark:from-gradient-success-from-dark dark:to-gradient-success-to-dark dark:text-black"
    ]
  end

  defp color_variant("gradient", :warning) do
    [
      "bg-gradient-to-br from-gradient-warning-from-light to-gradient-warning-to-light text-white",
      "dark:from-gradient-warning-from-dark dark:to-gradient-warning-to-dark dark:text-black"
    ]
  end

  defp color_variant("gradient", type) when type in [:error, :danger] do
    [
      "bg-gradient-to-br from-gradient-danger-from-light to-gradient-danger-to-light text-white",
      "dark:from-gradient-danger-from-dark dark:to-gradient-danger-to-dark dark:text-black"
    ]
  end

  defp color_variant("gradient", :info) do
    [
      "bg-gradient-to-br from-gradient-info-from-light to-gradient-info-to-light text-white",
      "dark:from-gradient-info-from-dark dark:to-gradient-info-to-dark dark:text-black"
    ]
  end

  defp color_variant("gradient", :misc) do
    [
      "bg-gradient-to-br from-gradient-misc-from-light to-gradient-misc-to-light text-white",
      "dark:from-gradient-misc-from-dark dark:to-gradient-misc-to-dark dark:text-black"
    ]
  end

  defp color_variant("gradient", :dawn) do
    [
      "bg-gradient-to-br from-gradient-dawn-from-light to-gradient-dawn-to-light text-white",
      "dark:from-gradient-dawn-from-dark dark:to-gradient-dawn-to-dark dark:text-black"
    ]
  end

  defp color_variant("gradient", :silver) do
    [
      "bg-gradient-to-br from-gradient-silver-from-light to-gradient-silver-to-light text-white",
      "dark:from-gradient-silver-from-dark dark:to-gradient-silver-to-dark dark:text-black"
    ]
  end

  defp color_variant(params, _) when is_binary(params), do: params

  ## JS Commands

  @doc """
  Displays an alert element by applying a transition effect.

  ## Parameters

    - `js`: (optional) An existing `Phoenix.LiveView.JS` structure to apply transformations on.
    Defaults to a new `%JS{}`.
    - `selector`: A string representing the CSS selector of the alert element to be shown.

  ## Returns

    - A `Phoenix.LiveView.JS` structure with commands to show the alert element with a
    smooth transition effect.

  ## Transition Details

    - The element transitions from an initial state of reduced opacity and scale
    (`opacity-0 translate-y-4 sm:translate-y-0 sm:scale-95`) to full opacity and scale
    (`opacity-100 translate-y-0 sm:scale-100`) over a duration of 300 milliseconds.

  ## Example

    ```elixir
    show_alert(%JS{}, "#alert-box")
    ```

  This example will show the alert element with the ID `alert-box` using the defined transition effect.
  """

  def show_alert(js \\ %JS{}, selector) do
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
  Hides an alert element by applying a transition effect.

  ## Parameters

    - `js`: (optional) An existing `Phoenix.LiveView.JS` structure to apply transformations on.
    Defaults to a new `%JS{}`.
    - `selector`: A string representing the CSS selector of the alert element to be hidden.

  ## Returns

    - A `Phoenix.LiveView.JS` structure with commands to hide the alert element with
    a smooth transition effect.

  ## Transition Details

    - The element transitions from full opacity and scale (`opacity-100 translate-y-0 sm:scale-100`)
    to reduced opacity and scale (`opacity-0 translate-y-4 sm:translate-y-0 sm:scale-95`)
    over a duration of 200 milliseconds.

  ## Example

    ```elixir
    hide_alert(%JS{}, "#alert-box")
    ```

  This example will hide the alert element with the ID `alert-box` using the defined transition effect.
  """

  def hide_alert(js \\ %JS{}, selector) do
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
