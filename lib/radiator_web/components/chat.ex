defmodule RadiatorWeb.Components.Chat do
  @moduledoc """
  `RadiatorWeb.Components.Chat` is a Phoenix LiveView component module for creating customizable chat interfaces.

  This module provides components to display chat messages with various styles, colors,
  sizes, and configurations. The main component, `chat/1`, acts as a container for chat
  messages, and `chat_section/1` is used to render individual chat messages with optional
  metadata and status information.

  **Documentation:** https://mishka.tools/chelekom/docs/chat
  """
  use Phoenix.Component
  use Gettext, backend: RadiatorWeb.Gettext

  @doc """
  The `chat` component is used to create a chat message container with customizable attributes such
  as `variant`, `color`, and `position`.

  It supports different layouts for normal and flipped chat bubbles and allows for nested content
  using an inner block for flexible message design.

  ## Examples

  ```elixir
  <.chat>
    <.avatar
      src="example.com/images/1.jpg"
      size="extra_large"
      rounded="full"
      border="small"
    />

    <.chat_section>
      <div class="flex items-center space-x-2 rtl:space-x-reverse">
        <div class="">Bonnie Green</div>
      </div>
      <p class="">
        That's awesome. I think our users will really appreciate the improvements.
      </p>
      <:status time="22:10" deliver="Delivered" />
      <:meta><div class="">Bonnie Green</div></:meta>
    </.chat_section>
    <div><.icon name="hero-ellipsis-vertical" class="size-4" /></div>
  </.chat>

  <.chat position="flipped">
    <.avatar src="https://example.com/picture.jpg" size="extra_large" rounded="full" border="small"/>

    <.chat_section>
      <div class="flex items-center space-x-2 rtl:space-x-reverse">
        <div class="">Bonnie Green</div>
      </div>
      <p class="">
        That's awesome. I think our users will really appreciate the improvements.
      </p>
      <:status time="22:10" deliver="Delivered" />
    </.chat_section>
    <div><.icon name="hero-ellipsis-vertical" class="size-4" /></div>
  </.chat>
  ```
  """
  @doc type: :component
  attr :id, :string,
    default: nil,
    doc: "A unique identifier is used to manage state and interaction"

  attr :class, :string, default: nil, doc: "Custom CSS class for additional styling"
  attr :variant, :string, default: "base", doc: "Determines the style"
  attr :color, :string, default: "natural", doc: "Determines color theme"
  attr :border, :string, default: "extra_small", doc: "Determines border style"
  attr :rounded, :string, default: "extra_large", doc: "Determines the border radius"

  attr :size, :string,
    default: "medium",
    doc:
      "Determines the overall size of the elements, including padding, font size, and other items"

  attr :space, :string, default: "extra_small", doc: "Space between items"

  attr :position, :string,
    values: ["normal", "flipped"],
    default: "normal",
    doc: "Determines the element position"

  attr :padding, :string, default: "small", doc: "Determines padding for items"

  attr :rest, :global,
    doc:
      "Global attributes can define defaults which are merged with attributes provided by the caller"

  slot :inner_block, required: false, doc: "Inner block that renders HEEx content"

  def chat(assigns) do
    ~H"""
    <div
      id={@id}
      role="log"
      aria-live="polite"
      aria-atomic="false"
      class={[
        "flex items-start gap-3",
        position_class(@position),
        rounded_size(@rounded, @position),
        border_class(@border, @variant),
        color_variant(@variant, @color),
        space_class(@space),
        padding_size(@padding),
        size_class(@size),
        @class
      ]}
      {@rest}
    >
      {render_slot(@inner_block)}
    </div>
    """
  end

  @doc """
  The `chat_section` component is used to display individual chat messages or sections with customizable
  attributes such as `font_weight` and `class`.

  It supports slots for adding status information and metadata, making it easy to create detailed
  chat message layouts.

  ## Examples

  ```elixir
  <.chat_section>
    <div class="flex items-center space-x-2 rtl:space-x-reverse">
      <div class="">Bonnie Green</div>
    </div>
    <p class="">
      That's awesome. I think our users will really appreciate the improvements.
    </p>
    <:status time="22:10" deliver="Delivered" />
    <:meta><div class="">Bonnie Green</div></:meta>
  </.chat_section>
  ```
  """
  @doc type: :component
  attr :id, :string,
    default: nil,
    doc: "A unique identifier is used to manage state and interaction"

  attr :font_weight, :string,
    default: "font-normal",
    doc: "Determines custom class for the font weight"

  attr :class, :string, default: nil, doc: "Custom CSS class for additional styling"

  attr :rest, :global,
    doc:
      "Global attributes can define defaults which are merged with attributes provided by the caller"

  slot :status, required: false, doc: "Defines a slot for displaying status information" do
    attr :time, :string, doc: "Displays the time"
    attr :deliver, :string, doc: "Indicates the delivery status"
    attr :time_class, :string, doc: "Custom classes for time"
    attr :deliver_class, :string, doc: "Custom classes for delivery status"
  end

  slot :meta,
    required: false,
    doc: "Defines a slot for adding custom metadata or additional information"

  slot :inner_block, required: false, doc: "Inner block that renders HEEx content"

  def chat_section(assigns) do
    ~H"""
    <div
      id={@id}
      role="group"
      tabindex="0"
      class={[
        "chat-section-bubble overflow-hidden",
        @font_weight,
        @class
      ]}
      {@rest}
    >
      {render_slot(@inner_block)}
      <div :for={status <- @status} class="flex items-center justify-between gap-2 text-xs">
        <div :if={status[:time]} class={status[:time_class]}>
          <span class="sr-only">{gettext("Time:")}</span>
          {status[:time]}
        </div>
        <div :if={status[:deliver]} class={["font-semibold", status[:deliver_class]]}>
          <span class="sr-only">{gettext("Status:")}</span>
          {status[:deliver]}
        </div>
      </div>

      <div :for={meta <- @meta} aria-hidden="true">{render_slot(meta)}</div>
    </div>
    """
  end

  defp position_class("normal"), do: "justify-start flex-row"
  defp position_class("flipped"), do: "justify-start flex-row-reverse"
  defp position_class(params) when is_binary(params), do: params

  defp rounded_size("extra_small", "normal") do
    [
      "[&>.chat-section-bubble]:rounded-e-sm [&>.chat-section-bubble]:rounded-es-sm"
    ]
  end

  defp rounded_size("small", "normal") do
    [
      "[&>.chat-section-bubble]:rounded-e [&>.chat-section-bubble]:rounded-es"
    ]
  end

  defp rounded_size("medium", "normal") do
    [
      "[&>.chat-section-bubble]:rounded-e-md [&>.chat-section-bubble]:rounded-es-md"
    ]
  end

  defp rounded_size("large", "normal") do
    [
      "[&>.chat-section-bubble]:rounded-e-lg [&>.chat-section-bubble]:rounded-es-lg"
    ]
  end

  defp rounded_size("extra_large", "normal") do
    [
      "[&>.chat-section-bubble]:rounded-e-xl [&>.chat-section-bubble]:rounded-es-xl"
    ]
  end

  defp rounded_size("extra_small", "flipped") do
    [
      "[&>.chat-section-bubble]:rounded-s-sm [&>.chat-section-bubble]:rounded-ee-sm"
    ]
  end

  defp rounded_size("small", "flipped") do
    [
      "[&>.chat-section-bubble]:rounded-s [&>.chat-section-bubble]:rounded-ee"
    ]
  end

  defp rounded_size("medium", "flipped") do
    [
      "[&>.chat-section-bubble]:rounded-s-md [&>.chat-section-bubble]:rounded-ee-md"
    ]
  end

  defp rounded_size("large", "flipped") do
    [
      "[&>.chat-section-bubble]:rounded-s-lg [&>.chat-section-bubble]:rounded-ee-lg"
    ]
  end

  defp rounded_size("extra_large", "flipped") do
    [
      "[&>.chat-section-bubble]:rounded-s-xl [&>.chat-section-bubble]:rounded-ee-xl"
    ]
  end

  defp rounded_size("none", _), do: nil

  defp rounded_size(params, _) when is_binary(params), do: params

  defp space_class("extra_small"), do: "[&>.chat-section-bubble]:space-y-2"

  defp space_class("small"), do: "[&>.chat-section-bubble]:space-y-3"

  defp space_class("medium"), do: "[&>.chat-section-bubble]:space-y-4"

  defp space_class("large"), do: "[&>.chat-section-bubble]:space-y-5"

  defp space_class("extra_large"), do: "[&>.chat-section-bubble]:space-y-6"

  defp space_class("none"), do: nil

  defp space_class(params) when is_binary(params), do: params

  defp padding_size("extra_small"), do: "[&>.chat-section-bubble]:p-1"

  defp padding_size("small"), do: "[&>.chat-section-bubble]:p-2"

  defp padding_size("medium"), do: "[&>.chat-section-bubble]:p-3"

  defp padding_size("large"), do: "[&>.chat-section-bubble]:p-4"

  defp padding_size("extra_large"), do: "[&>.chat-section-bubble]:p-5"

  defp padding_size(params) when is_binary(params), do: params

  defp border_class(_, variant) when variant in ["default", "shadow", "transparent", "gradient"],
    do: nil

  defp border_class("extra_small", _), do: "[&>.chat-section-bubble]:border"
  defp border_class("small", _), do: "[&>.chat-section-bubble]:border-2"
  defp border_class("medium", _), do: "[&>.chat-section-bubble]:border-[3px]"
  defp border_class("large", _), do: "[&>.chat-section-bubble]:border-4"
  defp border_class("extra_large", _), do: "[&>.chat-section-bubble]:border-[5px]"
  defp border_class("none", _), do: "[&>.chat-section-bubble]:border-0"
  defp border_class(params, _) when is_binary(params), do: params

  defp size_class("extra_small"), do: "text-xs [&>.chat-section-bubble]:max-w-[12rem]"

  defp size_class("small"), do: "text-sm [&>.chat-section-bubble]:max-w-[14rem]"

  defp size_class("medium"), do: "text-base [&>.chat-section-bubble]:max-w-[16rem]"

  defp size_class("large"), do: "text-lg [&>.chat-section-bubble]:max-w-[18rem]"

  defp size_class("extra_large"), do: "text-xl [&>.chat-section-bubble]:max-w-[20rem]"

  defp size_class(params) when is_binary(params), do: params

  defp color_variant("base", _) do
    [
      "[&>.chat-section-bubble]:bg-white [&>.chat-section-bubble]:text-base-text-light",
      "[&>.chat-section-bubble]:border-base-border-light [&>.chat-section-bubble]:shadow-sm",
      "dark:[&>.chat-section-bubble]:bg-base-bg-dark dark:[&>.chat-section-bubble]:text-base-text-dark",
      "dark:[&>.chat-section-bubble]:border-base-border-dark"
    ]
  end

  defp color_variant("default", "white") do
    [
      "[&>.chat-section-bubble]:bg-white text-black"
    ]
  end

  defp color_variant("default", "dark") do
    [
      "[&>.chat-section-bubble]:bg-default-dark-bg [&>.chat-section-bubble]:text-white"
    ]
  end

  defp color_variant("default", "natural") do
    [
      "[&>.chat-section-bubble]:bg-natural-light [&>.chat-section-bubble]:text-white",
      "dark:[&>.chat-section-bubble]:bg-natural-dark dark:[&>.chat-section-bubble]:text-black"
    ]
  end

  defp color_variant("default", "primary") do
    [
      "[&>.chat-section-bubble]:bg-primary-light [&>.chat-section-bubble]:text-white",
      "dark:[&>.chat-section-bubble]:bg-primary-dark dark:[&>.chat-section-bubble]:text-black"
    ]
  end

  defp color_variant("default", "secondary") do
    [
      "[&>.chat-section-bubble]:bg-secondary-light [&>.chat-section-bubble]:text-white",
      "dark:[&>.chat-section-bubble]:bg-secondary-dark dark:[&>.chat-section-bubble]:text-black"
    ]
  end

  defp color_variant("default", "success") do
    [
      "[&>.chat-section-bubble]:bg-success-light [&>.chat-section-bubble]:text-white",
      "dark:[&>.chat-section-bubble]:bg-success-dark dark:[&>.chat-section-bubble]:text-black"
    ]
  end

  defp color_variant("default", "warning") do
    [
      "[&>.chat-section-bubble]:bg-warning-light [&>.chat-section-bubble]:text-white",
      "dark:[&>.chat-section-bubble]:bg-warning-dark dark:[&>.chat-section-bubble]:text-black"
    ]
  end

  defp color_variant("default", "danger") do
    [
      "[&>.chat-section-bubble]:bg-danger-light [&>.chat-section-bubble]:text-white",
      "dark:[&>.chat-section-bubble]:bg-danger-dark dark:[&>.chat-section-bubble]:text-black"
    ]
  end

  defp color_variant("default", "info") do
    [
      "[&>.chat-section-bubble]:bg-info-light [&>.chat-section-bubble]:text-white",
      "dark:[&>.chat-section-bubble]:bg-info-dark dark:[&>.chat-section-bubble]:text-black"
    ]
  end

  defp color_variant("default", "misc") do
    [
      "[&>.chat-section-bubble]:bg-misc-light [&>.chat-section-bubble]:text-white",
      "dark:[&>.chat-section-bubble]:bg-misc-dark dark:[&>.chat-section-bubble]:text-black"
    ]
  end

  defp color_variant("default", "dawn") do
    [
      "[&>.chat-section-bubble]:bg-dawn-light [&>.chat-section-bubble]:text-white",
      "dark:[&>.chat-section-bubble]:bg-dawn-dark dark:[&>.chat-section-bubble]:text-black"
    ]
  end

  defp color_variant("default", "silver") do
    [
      "[&>.chat-section-bubble]:bg-silver-light [&>.chat-section-bubble]:text-white",
      "dark:[&>.chat-section-bubble]:bg-silver-dark dark:[&>.chat-section-bubble]:text-black"
    ]
  end

  defp color_variant("outline", "natural") do
    [
      "[&>.chat-section-bubble]:text-natural-light [&>.chat-section-bubble]:border-natural-light",
      "dark:[&>.chat-section-bubble]:text-natural-dark dark:[&>.chat-section-bubble]:border-natural-dark"
    ]
  end

  defp color_variant("outline", "primary") do
    [
      "[&>.chat-section-bubble]:text-primary-light [&>.chat-section-bubble]:border-primary-light",
      "dark:[&>.chat-section-bubble]:text-primary-dark dark:[&>.chat-section-bubble]:border-primary-dark"
    ]
  end

  defp color_variant("outline", "secondary") do
    [
      "[&>.chat-section-bubble]:text-secondary-light [&>.chat-section-bubble]:border-secondary-light",
      "dark:[&>.chat-section-bubble]:text-secondary-dark dark:[&>.chat-section-bubble]:border-secondary-dark"
    ]
  end

  defp color_variant("outline", "success") do
    [
      "[&>.chat-section-bubble]:text-success-light [&>.chat-section-bubble]:border-success-light",
      "dark:[&>.chat-section-bubble]:text-success-dark dark:[&>.chat-section-bubble]:border-success-dark"
    ]
  end

  defp color_variant("outline", "warning") do
    [
      "[&>.chat-section-bubble]:text-warning-light [&>.chat-section-bubble]:border-warning-light",
      "dark:[&>.chat-section-bubble]:text-warning-dark dark:[&>.chat-section-bubble]:border-warning-dark"
    ]
  end

  defp color_variant("outline", "danger") do
    [
      "[&>.chat-section-bubble]:text-danger-light [&>.chat-section-bubble]:border-danger-light",
      "dark:[&>.chat-section-bubble]:text-danger-dark dark:[&>.chat-section-bubble]:border-danger-dark"
    ]
  end

  defp color_variant("outline", "info") do
    [
      "[&>.chat-section-bubble]:text-info-light [&>.chat-section-bubble]:border-info-light",
      "dark:[&>.chat-section-bubble]:text-info-dark dark:[&>.chat-section-bubble]:border-info-dark"
    ]
  end

  defp color_variant("outline", "misc") do
    [
      "[&>.chat-section-bubble]:text-misc-light [&>.chat-section-bubble]:border-misc-light",
      "dark:[&>.chat-section-bubble]:text-misc-dark dark:[&>.chat-section-bubble]:border-misc-dark"
    ]
  end

  defp color_variant("outline", "dawn") do
    [
      "[&>.chat-section-bubble]:text-dawn-light [&>.chat-section-bubble]:border-dawn-light",
      "dark:[&>.chat-section-bubble]:text-dawn-dark dark:[&>.chat-section-bubble]:border-dawn-dark"
    ]
  end

  defp color_variant("outline", "silver") do
    [
      "[&>.chat-section-bubble]:text-silver-light [&>.chat-section-bubble]:border-silver-light",
      "dark:[&>.chat-section-bubble]:text-silver-dark dark:[&>.chat-section-bubble]:border-silver-dark"
    ]
  end

  defp color_variant("shadow", "natural") do
    [
      "[&>.chat-section-bubble]:bg-natural-light [&>.chat-section-bubble]:text-white",
      "dark:[&>.chat-section-bubble]:bg-natural-dark dark:[&>.chat-section-bubble]:text-black",
      "[&>.chat-section-bubble]:shadow-[0px_4px_6px_-4px_var(--color-shadow-natural)]",
      "[&>.chat-section-bubble]:shadow-[0px_10px_15px_-3px_var(--color-shadow-natural)] [&>.chat-section-bubble]:dark:shadow-none"
    ]
  end

  defp color_variant("shadow", "primary") do
    [
      "[&>.chat-section-bubble]:bg-primary-light [&>.chat-section-bubble]:text-white",
      "dark:[&>.chat-section-bubble]:bg-primary-dark dark:[&>.chat-section-bubble]:text-black",
      "[&>.chat-section-bubble]:shadow-[0px_4px_6px_-4px_var(--color-shadow-primary)]",
      "[&>.chat-section-bubble]:shadow-[0px_10px_15px_-3px_var(--color-shadow-primary)] [&>.chat-section-bubble]:dark:shadow-none"
    ]
  end

  defp color_variant("shadow", "secondary") do
    [
      "[&>.chat-section-bubble]:bg-secondary-light [&>.chat-section-bubble]:text-white",
      "dark:[&>.chat-section-bubble]:bg-secondary-dark dark:[&>.chat-section-bubble]:text-black",
      "[&>.chat-section-bubble]:shadow-[0px_4px_6px_-4px_var(--color-shadow-secondary)]",
      "[&>.chat-section-bubble]:shadow-[0px_10px_15px_-3px_var(--color-shadow-secondary)] [&>.chat-section-bubble]:dark:shadow-none"
    ]
  end

  defp color_variant("shadow", "success") do
    [
      "[&>.chat-section-bubble]:bg-success-light [&>.chat-section-bubble]:text-white",
      "dark:[&>.chat-section-bubble]:bg-success-dark dark:[&>.chat-section-bubble]:text-black",
      "[&>.chat-section-bubble]:shadow-[0px_4px_6px_-4px_var(--color-shadow-success)]",
      "[&>.chat-section-bubble]:shadow-[0px_10px_15px_-3px_var(--color-shadow-success)] [&>.chat-section-bubble]:dark:shadow-none"
    ]
  end

  defp color_variant("shadow", "warning") do
    [
      "[&>.chat-section-bubble]:bg-warning-light [&>.chat-section-bubble]:text-white",
      "dark:[&>.chat-section-bubble]:bg-warning-dark dark:[&>.chat-section-bubble]:text-black",
      "[&>.chat-section-bubble]:shadow-[0px_4px_6px_-4px_var(--color-shadow-warning)]",
      "[&>.chat-section-bubble]:shadow-[0px_10px_15px_-3px_var(--color-shadow-warning)] [&>.chat-section-bubble]:dark:shadow-none"
    ]
  end

  defp color_variant("shadow", "danger") do
    [
      "[&>.chat-section-bubble]:bg-danger-light [&>.chat-section-bubble]:text-white",
      "dark:[&>.chat-section-bubble]:bg-danger-dark dark:[&>.chat-section-bubble]:text-black",
      "[&>.chat-section-bubble]:shadow-[0px_4px_6px_-4px_var(--color-shadow-danger)]",
      "[&>.chat-section-bubble]:shadow-[0px_10px_15px_-3px_var(--color-shadow-danger)] [&>.chat-section-bubble]:dark:shadow-none"
    ]
  end

  defp color_variant("shadow", "info") do
    [
      "[&>.chat-section-bubble]:bg-info-light [&>.chat-section-bubble]:text-white",
      "dark:[&>.chat-section-bubble]:bg-info-dark dark:[&>.chat-section-bubble]:text-black",
      "[&>.chat-section-bubble]:shadow-[0px_4px_6px_-4px_var(--color-shadow-info)]",
      "[&>.chat-section-bubble]:shadow-[0px_10px_15px_-3px_var(--color-shadow-info)] [&>.chat-section-bubble]:dark:shadow-none"
    ]
  end

  defp color_variant("shadow", "misc") do
    [
      "[&>.chat-section-bubble]:bg-misc-light [&>.chat-section-bubble]:text-white",
      "dark:[&>.chat-section-bubble]:bg-misc-dark dark:[&>.chat-section-bubble]:text-black",
      "[&>.chat-section-bubble]:shadow-[0px_4px_6px_-4px_var(--color-shadow-misc)]",
      "[&>.chat-section-bubble]:shadow-[0px_10px_15px_-3px_var(--color-shadow-misc)] [&>.chat-section-bubble]:dark:shadow-none"
    ]
  end

  defp color_variant("shadow", "dawn") do
    [
      "[&>.chat-section-bubble]:bg-dawn-light [&>.chat-section-bubble]:text-white",
      "dark:[&>.chat-section-bubble]:bg-dawn-dark dark:[&>.chat-section-bubble]:text-black",
      "[&>.chat-section-bubble]:shadow-[0px_4px_6px_-4px_var(--color-shadow-dawn)]",
      "[&>.chat-section-bubble]:shadow-[0px_10px_15px_-3px_var(--color-shadow-dawn)] [&>.chat-section-bubble]:dark:shadow-none"
    ]
  end

  defp color_variant("shadow", "silver") do
    [
      "[&>.chat-section-bubble]:bg-silver-light [&>.chat-section-bubble]:text-white",
      "dark:[&>.chat-section-bubble]:bg-silver-dark dark:[&>.chat-section-bubble]:text-black",
      "[&>.chat-section-bubble]:shadow-[0px_4px_6px_-4px_var(--color-shadow-silver)]",
      "[&>.chat-section-bubble]:shadow-[0px_10px_15px_-3px_var(--color-shadow-silver)] [&>.chat-section-bubble]:dark:shadow-none"
    ]
  end

  defp color_variant("bordered", "white") do
    [
      "[&>.chat-section-bubble]:bg-white [&>.chat-section-bubble]:text-black [&>.chat-section-bubble]:border-bordered-white-border"
    ]
  end

  defp color_variant("bordered", "dark") do
    [
      "[&>.chat-section-bubble]:bg-bordered-dark-bg [&>.chat-section-bubble]:text-white [&>.chat-section-bubble]:border-bordered-dark-border"
    ]
  end

  defp color_variant("bordered", "natural") do
    [
      "[&>.chat-section-bubble]:text-natural-bordered-text-light [&>.chat-section-bubble]:border-natural-bordered-text-light [&>.chat-section-bubble]:bg-natural-bordered-bg-light",
      "dark:[&>.chat-section-bubble]:text-natural-bordered-text-dark dark:[&>.chat-section-bubble]:border-natural-bordered-text-dark dark:[&>.chat-section-bubble]:bg-natural-bordered-bg-dark"
    ]
  end

  defp color_variant("bordered", "primary") do
    [
      "[&>.chat-section-bubble]:text-primary-bordered-text-light [&>.chat-section-bubble]:border-primary-bordered-text-light [&>.chat-section-bubble]:bg-primary-bordered-bg-light",
      "dark:[&>.chat-section-bubble]:text-primary-bordered-text-dark dark:[&>.chat-section-bubble]:border-primary-bordered-text-dark dark:[&>.chat-section-bubble]:bg-primary-bordered-bg-dark"
    ]
  end

  defp color_variant("bordered", "secondary") do
    [
      "[&>.chat-section-bubble]:text-secondary-bordered-text-light [&>.chat-section-bubble]:border-secondary-bordered-text-light [&>.chat-section-bubble]:bg-secondary-bordered-bg-light",
      "dark:[&>.chat-section-bubble]:text-secondary-bordered-text-dark dark:[&>.chat-section-bubble]:border-secondary-bordered-text-dark dark:[&>.chat-section-bubble]:bg-secondary-bordered-bg-dark"
    ]
  end

  defp color_variant("bordered", "success") do
    [
      "[&>.chat-section-bubble]:text-success-bordered-text-light [&>.chat-section-bubble]:border-success-bordered-text-light [&>.chat-section-bubble]:bg-success-bordered-bg-light",
      "dark:[&>.chat-section-bubble]:text-success-bordered-text-dark dark:[&>.chat-section-bubble]:border-success-bordered-text-dark dark:[&>.chat-section-bubble]:bg-success-bordered-bg-dark"
    ]
  end

  defp color_variant("bordered", "warning") do
    [
      "[&>.chat-section-bubble]:text-warning-bordered-text-light [&>.chat-section-bubble]:border-warning-bordered-text-light [&>.chat-section-bubble]:bg-warning-bordered-bg-light",
      "dark:[&>.chat-section-bubble]:text-warning-bordered-text-dark dark:[&>.chat-section-bubble]:border-warning-bordered-text-dark dark:[&>.chat-section-bubble]:bg-warning-bordered-bg-dark"
    ]
  end

  defp color_variant("bordered", "danger") do
    [
      "[&>.chat-section-bubble]:text-danger-bordered-text-light [&>.chat-section-bubble]:border-danger-bordered-text-light [&>.chat-section-bubble]:bg-danger-bordered-bg-light",
      "dark:[&>.chat-section-bubble]:text-danger-bordered-text-dark dark:[&>.chat-section-bubble]:border-danger-bordered-text-dark dark:[&>.chat-section-bubble]:bg-danger-bordered-bg-dark"
    ]
  end

  defp color_variant("bordered", "info") do
    [
      "[&>.chat-section-bubble]:text-info-bordered-text-light [&>.chat-section-bubble]:border-info-bordered-text-light [&>.chat-section-bubble]:bg-info-bordered-bg-light",
      "dark:[&>.chat-section-bubble]:text-info-bordered-text-dark dark:[&>.chat-section-bubble]:border-info-bordered-text-dark dark:[&>.chat-section-bubble]:bg-info-bordered-bg-dark"
    ]
  end

  defp color_variant("bordered", "misc") do
    [
      "[&>.chat-section-bubble]:text-misc-bordered-text-light [&>.chat-section-bubble]:border-misc-bordered-text-light [&>.chat-section-bubble]:bg-misc-bordered-bg-light",
      "dark:[&>.chat-section-bubble]:text-misc-bordered-text-dark dark:[&>.chat-section-bubble]:border-misc-bordered-text-dark dark:[&>.chat-section-bubble]:bg-misc-bordered-bg-dark"
    ]
  end

  defp color_variant("bordered", "dawn") do
    [
      "[&>.chat-section-bubble]:text-dawn-bordered-text-light [&>.chat-section-bubble]:border-dawn-bordered-text-light [&>.chat-section-bubble]:bg-dawn-bordered-bg-light",
      "dark:[&>.chat-section-bubble]:text-dawn-bordered-text-dark dark:[&>.chat-section-bubble]:border-dawn-bordered-text-dark dark:[&>.chat-section-bubble]:bg-dawn-bordered-bg-dark"
    ]
  end

  defp color_variant("bordered", "silver") do
    [
      "[&>.chat-section-bubble]:text-silver-bordered-text-light [&>.chat-section-bubble]:border-silver-bordered-text-light [&>.chat-section-bubble]:bg-silver-bordered-bg-light",
      "dark:[&>.chat-section-bubble]:text-silver-bordered-text-dark dark:[&>.chat-section-bubble]:border-silver-bordered-text-dark dark:[&>.chat-section-bubble]:bg-silver-bordered-bg-dark"
    ]
  end

  defp color_variant("transparent", "natural") do
    [
      "[&>.chat-section-bubble]:text-natural-light dark:[&>.chat-section-bubble]:text-natural-dark"
    ]
  end

  defp color_variant("transparent", "primary") do
    [
      "[&>.chat-section-bubble]:text-primary-light dark:[&>.chat-section-bubble]:text-primary-dark"
    ]
  end

  defp color_variant("transparent", "secondary") do
    [
      "[&>.chat-section-bubble]:text-secondary-light dark:[&>.chat-section-bubble]:text-secondary-dark"
    ]
  end

  defp color_variant("transparent", "success") do
    [
      "[&>.chat-section-bubble]:text-success-light dark:[&>.chat-section-bubble]:text-success-dark"
    ]
  end

  defp color_variant("transparent", "warning") do
    [
      "[&>.chat-section-bubble]:text-warning-light dark:[&>.chat-section-bubble]:text-warning-dark"
    ]
  end

  defp color_variant("transparent", "danger") do
    [
      "[&>.chat-section-bubble]:text-danger-light dark:[&>.chat-section-bubble]:text-danger-dark"
    ]
  end

  defp color_variant("transparent", "info") do
    [
      "[&>.chat-section-bubble]:text-info-light dark:[&>.chat-section-bubble]:text-info-dark"
    ]
  end

  defp color_variant("transparent", "misc") do
    [
      "[&>.chat-section-bubble]:text-misc-light dark:[&>.chat-section-bubble]:text-misc-dark"
    ]
  end

  defp color_variant("transparent", "dawn") do
    [
      "[&>.chat-section-bubble]:text-dawn-light dark:[&>.chat-section-bubble]:text-dawn-dark"
    ]
  end

  defp color_variant("transparent", "silver") do
    [
      "[&>.chat-section-bubble]:text-silver-light dark:[&>.chat-section-bubble]:text-silver-dark"
    ]
  end

  defp color_variant("gradient", "natural") do
    [
      "[&>.chat-section-bubble]:bg-gradient-to-br [&>.chat-section-bubble]:from-gradient-natural-from-light [&>.chat-section-bubble]:to-gradient-natural-to-light [&>.chat-section-bubble]:text-white",
      "dark:[&>.chat-section-bubble]:from-gradient-natural-from-dark dark:[&>.chat-section-bubble]:to-white dark:[&>.chat-section-bubble]:text-black"
    ]
  end

  defp color_variant("gradient", "primary") do
    [
      "[&>.chat-section-bubble]:bg-gradient-to-br [&>.chat-section-bubble]:from-gradient-primary-from-light [&>.chat-section-bubble]:to-gradient-primary-to-light [&>.chat-section-bubble]:text-white",
      "dark:[&>.chat-section-bubble]:from-gradient-primary-from-dark dark:[&>.chat-section-bubble]:to-gradient-primary-to-dark dark:[&>.chat-section-bubble]:text-black"
    ]
  end

  defp color_variant("gradient", "secondary") do
    [
      "[&>.chat-section-bubble]:bg-gradient-to-br [&>.chat-section-bubble]:from-gradient-secondary-from-light [&>.chat-section-bubble]:to-gradient-secondary-to-light [&>.chat-section-bubble]:text-white",
      "dark:[&>.chat-section-bubble]:from-gradient-secondary-from-dark dark:[&>.chat-section-bubble]:to-gradient-secondary-to-dark dark:[&>.chat-section-bubble]:text-black"
    ]
  end

  defp color_variant("gradient", "success") do
    [
      "[&>.chat-section-bubble]:bg-gradient-to-br [&>.chat-section-bubble]:from-gradient-success-from-light [&>.chat-section-bubble]:to-gradient-success-to-light [&>.chat-section-bubble]:text-white",
      "dark:[&>.chat-section-bubble]:from-gradient-success-from-dark dark:[&>.chat-section-bubble]:to-gradient-success-to-dark dark:[&>.chat-section-bubble]:text-black"
    ]
  end

  defp color_variant("gradient", "warning") do
    [
      "[&>.chat-section-bubble]:bg-gradient-to-br [&>.chat-section-bubble]:from-gradient-warning-from-light [&>.chat-section-bubble]:to-gradient-warning-to-light [&>.chat-section-bubble]:text-white",
      "dark:[&>.chat-section-bubble]:from-gradient-warning-from-dark dark:[&>.chat-section-bubble]:to-gradient-warning-to-dark dark:[&>.chat-section-bubble]:text-black"
    ]
  end

  defp color_variant("gradient", "danger") do
    [
      "[&>.chat-section-bubble]:bg-gradient-to-br [&>.chat-section-bubble]:from-gradient-danger-from-light [&>.chat-section-bubble]:to-gradient-danger-to-light [&>.chat-section-bubble]:text-white",
      "dark:[&>.chat-section-bubble]:from-gradient-danger-from-dark dark:[&>.chat-section-bubble]:to-gradient-danger-to-dark dark:[&>.chat-section-bubble]:text-black"
    ]
  end

  defp color_variant("gradient", "info") do
    [
      "[&>.chat-section-bubble]:bg-gradient-to-br [&>.chat-section-bubble]:from-gradient-info-from-light [&>.chat-section-bubble]:to-gradient-info-to-light [&>.chat-section-bubble]:text-white",
      "dark:[&>.chat-section-bubble]:from-gradient-info-from-dark dark:[&>.chat-section-bubble]:to-gradient-info-to-dark dark:[&>.chat-section-bubble]:text-black"
    ]
  end

  defp color_variant("gradient", "misc") do
    [
      "[&>.chat-section-bubble]:bg-gradient-to-br [&>.chat-section-bubble]:from-gradient-misc-from-light [&>.chat-section-bubble]:to-gradient-misc-to-light [&>.chat-section-bubble]:text-white",
      "dark:[&>.chat-section-bubble]:from-gradient-misc-from-dark dark:[&>.chat-section-bubble]:to-gradient-misc-to-dark dark:[&>.chat-section-bubble]:text-black"
    ]
  end

  defp color_variant("gradient", "dawn") do
    [
      "[&>.chat-section-bubble]:bg-gradient-to-br [&>.chat-section-bubble]:from-gradient-dawn-from-light [&>.chat-section-bubble]:to-gradient-dawn-to-light [&>.chat-section-bubble]:text-white",
      "dark:[&>.chat-section-bubble]:from-gradient-dawn-from-dark dark:[&>.chat-section-bubble]:to-gradient-dawn-to-dark dark:[&>.chat-section-bubble]:text-black"
    ]
  end

  defp color_variant("gradient", "silver") do
    [
      "[&>.chat-section-bubble]:bg-gradient-to-br [&>.chat-section-bubble]:from-gradient-silver-from-light [&>.chat-section-bubble]:to-gradient-silver-to-light [&>.chat-section-bubble]:text-white",
      "dark:[&>.chat-section-bubble]:from-gradient-silver-from-dark dark:[&>.chat-section-bubble]:to-gradient-silver-to-dark dark:[&>.chat-section-bubble]:text-black"
    ]
  end

  defp color_variant(params, _) when is_binary(params), do: params
end
