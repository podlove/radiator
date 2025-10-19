defmodule RadiatorWeb.Components.Accordion do
  @moduledoc """
  The `RadiatorWeb.Components.Accordion` module provides a flexible and customizable accordion
  component for Phoenix LiveView applications.

  It supports a variety of configuration options including size, variant, color, padding,
  and border styles.

  **Documentation:** https://mishka.tools/chelekom/docs/accordion
  """
  use Phoenix.Component
  import Phoenix.LiveView.Utils, only: [random_id: 0]
  import RadiatorWeb.Components.Icon, only: [icon: 1]

  @doc type: :component
  attr :id, :string,
    required: true,
    doc: "A unique identifier for the accordion"

  attr :class, :string, default: nil, doc: "Custom CSS class for additional styling"
  attr :multiple, :boolean, default: false, doc: "Allow multiple panels open simultaneously"
  attr :collapsible, :boolean, default: true, doc: "Allow all panels to be closed"
  attr :duration, :integer, default: 200, doc: "Animation duration in milliseconds"
  attr :keep_mounted, :boolean, default: false, doc: "Keep content mounted after first open"
  attr :server_events, :boolean, default: false, doc: "Send open/close events to LiveView"
  attr :event_handler, :string, default: nil, doc: "Specify event handler for accordion events"
  attr :initial_open, :list, default: [], doc: "List of initially open item IDs"

  attr :variant, :string, default: "base", doc: "Visual style variant"
  attr :color, :string, default: "natural", doc: "Color theme"
  attr :size, :string, default: "medium", doc: "Overall size"
  attr :rounded, :string, default: "medium", doc: "Border radius"
  attr :border, :string, default: "extra_small", doc: "Border style"
  attr :space, :string, default: "small", doc: "Space between separated items"
  attr :media_size, :string, default: "small", doc: "Size of media elements like icons and images"
  attr :padding, :string, default: "small", doc: "Padding for accordion items"

  attr :chevron_icon, :string, default: "hero-chevron-down", doc: "Chevron icon"
  attr :chevron_position, :string, default: "right", doc: "Chevron position (left/right)"
  attr :left_chevron, :boolean, default: false, doc: "Position chevron on the left"
  attr :right_chevron, :boolean, default: false, doc: "Position chevron on the right"
  attr :hide_chevron, :boolean, default: false, doc: "Hide the chevron icon"
  attr :chevron_class, :string, default: nil, doc: "Additional CSS classes for the chevron"

  slot :item, required: false, doc: "Accordion items as slots" do
    attr :id, :string,
      required: false,
      doc: "Unique identifier for the item (auto-generated if not provided)"

    attr :title, :string, required: true, doc: "Title of the accordion item"
    attr :description, :string, doc: "Optional description/subtitle"
    attr :icon, :string, doc: "Optional icon name"
    attr :icon_class, :string, doc: "Additional CSS classes for the item icon"
    attr :icon_wrapper_class, :string, doc: "Additional CSS classes for the item icon wrapper"
    attr :image, :string, doc: "Optional image source URL"
    attr :image_class, :string, doc: "Additional CSS classes for the image"
    attr :trigger_class, :string, doc: "Additional CSS classes for the trigger"
    attr :content_class, :string, doc: "Additional CSS classes for the content"
    attr :open, :boolean, doc: "Whether this item should be initially open"
  end

  def accordion(assigns) do
    assigns = assigns |> assign_new(:id, fn -> "accordion-#{random_id()}" end)

    ~H"""
    <div
      id={@id}
      phx-hook="Collapsible"
      data-multiple={@multiple}
      data-collapsible={to_string(@collapsible)}
      data-duration={@duration}
      data-keep-mounted={to_string(@keep_mounted)}
      data-server-events={to_string(@server_events)}
      data-event-handler={@event_handler}
      data-initial-open={format_initial_open(@initial_open, @item)}
      class={[
        "overflow-hidden w-full h-fit",
        color_variant(@variant, @color),
        space_class(@space, @variant),
        size_class(@size),
        rounded_class(@rounded, @variant),
        border_class(@border, @variant),
        media_size(@media_size),
        padding_size(@padding),
        @class
      ]}
    >
      <div
        :for={{item, index} <- Enum.with_index(@item, 1)}
        class={["accordion-item overflow-hidden"]}
      >
        <button
          data-collapsible-trigger={item[:id] || "#{@id}-item-#{index + 1}"}
          class={[
            "accordion-trigger cursor-pointer w-full text-left flex items-center justify-between",
            "transition-colors duration-200 focus:outline-none overflow-hidden",
            item[:trigger_class]
          ]}
        >
          <.icon
            :if={chevron_visible?(assigns) && chevron_position(assigns) == "left"}
            name={@chevron_icon}
            class={chevron_classes(assigns)}
          />
          <div class="flex items-center space-x-3">
            <div :if={item[:icon]} class={["shrink-0", item[:icon_wrapper_class]]}>
              <.icon name={item[:icon]} class={item[:icon_class] || "accordion-icon"} />
            </div>

            <img
              :if={!is_nil(item[:image])}
              class={["accordion-title-media shrink-0", item[:image_class]]}
              src={item[:image]}
            />

            <div class="flex-1">
              <div class="accordion-title">{item[:title]}</div>
              <div :if={item[:description]} class="accordion-description">
                {item[:description]}
              </div>
            </div>
          </div>

          <.icon
            :if={chevron_visible?(assigns) && chevron_position(assigns) == "right"}
            name={@chevron_icon}
            class={chevron_classes(assigns)}
          />
        </button>

        <div data-collapsible-panel={item[:id] || "#{@id}-item-#{index + 1}"} class="overflow-hidden">
          <div
            data-collapsible-content
            class={["transition-[max-height] max-h-0", "duration-#{@duration}"]}
          >
            <div class={["accordion-panel-content", item[:content_class]]}>
              {render_slot(item)}
            </div>
          </div>
        </div>
      </div>
    </div>
    """
  end

  defp format_initial_open(initial_open, items) do
    slot_open_items =
      items
      |> Enum.filter(&(&1[:open] == true))
      |> Enum.map(& &1.id)

    cond do
      length(initial_open) > 0 -> Enum.join(initial_open, ",")
      length(slot_open_items) > 0 -> Enum.join(slot_open_items, ",")
      true -> ""
    end
  end

  defp color_variant("base", _) do
    [
      "text-base-text-light border-base-border-light bg-white",
      "dark:text-base-text-dark dark:border-base-border-dark dark:bg-base-bg-dark",
      "[&>.accordion-item>.accordion-trigger]:hover:bg-base-hover-light dark:[&>.accordion-item>.accordion-trigger]:hover:bg-base-hover-dark",
      "[&>.accordion-item:not(:first-child)]:border-t-base-border-light",
      "dark:[&>.accordion-item:not(:first-child)]:border-t-base-border-dark"
    ]
  end

  defp color_variant("base_separated", _) do
    [
      "text-base-text-light [&>.accordion-item]:border-base-border-light",
      "[&>.accordion-item]:bg-white",
      "dark:text-base-text-dark dark:[&>.accordion-item]:border-base-border-dark",
      "dark:[&>.accordion-item]:bg-base-bg-dark",
      "[&>.accordion-item>.accordion-trigger]:hover:bg-base-hover-light dark:[&>.accordion-item>.accordion-trigger]:hover:bg-base-hover-dark"
    ]
  end

  defp color_variant("default", "natural") do
    [
      "bg-natural-light text-white dark:bg-natural-dark dark:text-black",
      "[&>.accordion-item>.accordion-trigger]:hover:bg-natural-hover-light",
      "dark:[&>.accordion-item>.accordion-trigger]:hover:bg-natural-hover-dark"
    ]
  end

  defp color_variant("default", "primary") do
    [
      "bg-primary-light text-white dark:bg-primary-dark dark:text-black",
      "[&>.accordion-item>.accordion-trigger]:hover:bg-primary-hover-light",
      "dark:[&>.accordion-item>.accordion-trigger]:hover:bg-primary-hover-dark"
    ]
  end

  defp color_variant("default", "secondary") do
    [
      "bg-secondary-light text-white dark:bg-secondary-dark dark:text-black",
      "[&>.accordion-item>.accordion-trigger]:hover:bg-secondary-hover-light",
      "dark:[&>.accordion-item>.accordion-trigger]:hover:bg-secondary-hover-dark"
    ]
  end

  defp color_variant("default", "success") do
    [
      "bg-success-light text-white dark:bg-success-dark dark:text-black",
      "[&>.accordion-item>.accordion-trigger]:hover:bg-success-hover-light",
      "dark:[&>.accordion-item>.accordion-trigger]:hover:bg-success-hover-dark"
    ]
  end

  defp color_variant("default", "warning") do
    [
      "bg-warning-light text-white dark:bg-warning-dark dark:text-black",
      "[&>.accordion-item>.accordion-trigger]:hover:bg-warning-hover-light",
      "dark:[&>.accordion-item>.accordion-trigger]:hover:bg-warning-hover-dark"
    ]
  end

  defp color_variant("default", "danger") do
    [
      "bg-danger-light text-white dark:bg-danger-dark dark:text-black",
      "[&>.accordion-item>.accordion-trigger]:hover:bg-danger-hover-light",
      "dark:[&>.accordion-item>.accordion-trigger]:hover:bg-danger-hover-dark"
    ]
  end

  defp color_variant("default", "info") do
    [
      "bg-info-light text-white dark:bg-info-dark dark:text-black",
      "[&>.accordion-item>.accordion-trigger]:hover:bg-info-hover-light",
      "dark:[&>.accordion-item>.accordion-trigger]:hover:bg-info-hover-dark"
    ]
  end

  defp color_variant("default", "misc") do
    [
      "bg-misc-light text-white dark:bg-misc-dark dark:text-black",
      "[&>.accordion-item>.accordion-trigger]:hover:bg-misc-hover-light",
      "dark:[&>.accordion-item>.accordion-trigger]:hover:bg-misc-hover-dark"
    ]
  end

  defp color_variant("default", "dawn") do
    [
      "bg-dawn-light text-white dark:bg-dawn-dark dark:text-black",
      "[&>.accordion-item>.accordion-trigger]:hover:bg-dawn-hover-light",
      "dark:[&>.accordion-item>.accordion-trigger]:hover:bg-dawn-hover-dark"
    ]
  end

  defp color_variant("default", "silver") do
    [
      "bg-silver-light text-white dark:bg-silver-dark dark:text-black",
      "[&>.accordion-item>.accordion-trigger]:hover:bg-silver-hover-light",
      "dark:[&>.accordion-item>.accordion-trigger]:hover:bg-silver-hover-dark"
    ]
  end

  defp color_variant("default", "white") do
    [
      "bg-white text-black",
      "[&>.accordion-item>.accordion-trigger]:hover:bg-natural-disabled-light",
      "dark:[&>.accordion-item>.accordion-trigger]:hover:bg-natural-disabled-light"
    ]
  end

  defp color_variant("default", "dark") do
    [
      "bg-default-dark-bg text-white",
      "[&>.accordion-item>.accordion-trigger]:hover:bg-natural-bg-dark",
      "dark:[&>.accordion-item>.accordion-trigger]:hover:bg-natural-bg-dark"
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

  defp color_variant("outline", "natural") do
    [
      "border-natural-light dark:border-natural-dark text-natural-light dark:text-natural-dark",
      "[&>.accordion-item>.accordion-trigger]:hover:text-natural-hover-light dark:[&>.accordion-item>.accordion-trigger]:hover:text-natural-hover-dark",
      "[&>.accordion-item:not(:first-child)]:border-t-natural-light",
      "dark:[&>.accordion-item:not(:first-child)]:border-t-natural-dark"
    ]
  end

  defp color_variant("outline", "primary") do
    [
      "border-primary-light dark:border-primary-dark text-primary-light dark:text-primary-dark",
      "[&>.accordion-item>.accordion-trigger]:hover:text-primary-hover-light dark:[&>.accordion-item>.accordion-trigger]:hover:text-primary-hover-dark",
      "[&>.accordion-item:not(:first-child)]:border-t-primary-light",
      "dark:[&>.accordion-item:not(:first-child)]:border-t-primary-dark"
    ]
  end

  defp color_variant("outline", "secondary") do
    [
      "border-secondary-light dark:border-secondary-dark text-secondary-light dark:text-secondary-dark",
      "[&>.accordion-item>.accordion-trigger]:hover:text-secondary-hover-light dark:[&>.accordion-item>.accordion-trigger]:hover:text-secondary-hover-dark",
      "[&>.accordion-item:not(:first-child)]:border-t-secondary-light",
      "dark:[&>.accordion-item:not(:first-child)]:border-t-secondary-dark"
    ]
  end

  defp color_variant("outline", "success") do
    [
      "border-success-light dark:border-success-dark text-success-light dark:text-success-dark",
      "[&>.accordion-item>.accordion-trigger]:hover:text-success-hover-light dark:[&>.accordion-item>.accordion-trigger]:hover:text-success-hover-dark",
      "[&>.accordion-item:not(:first-child)]:border-t-success-light",
      "dark:[&>.accordion-item:not(:first-child)]:border-t-success-dark"
    ]
  end

  defp color_variant("outline", "warning") do
    [
      "border-warning-light dark:border-warning-dark text-warning-light dark:text-warning-dark",
      "[&>.accordion-item>.accordion-trigger]:hover:text-warning-hover-light dark:[&>.accordion-item>.accordion-trigger]:hover:text-warning-hover-dark",
      "[&>.accordion-item:not(:first-child)]:border-t-warning-light",
      "dark:[&>.accordion-item:not(:first-child)]:border-t-warning-dark"
    ]
  end

  defp color_variant("outline", "danger") do
    [
      "border-danger-light dark:border-danger-dark text-danger-light dark:text-danger-dark",
      "[&>.accordion-item>.accordion-trigger]:hover:text-danger-hover-light dark:[&>.accordion-item>.accordion-trigger]:hover:text-danger-hover-dark",
      "[&>.accordion-item:not(:first-child)]:border-t-danger-light",
      "dark:[&>.accordion-item:not(:first-child)]:border-t-danger-dark"
    ]
  end

  defp color_variant("outline", "info") do
    [
      "border-info-light dark:border-info-dark text-info-light dark:text-info-dark",
      "[&>.accordion-item>.accordion-trigger]:hover:text-info-hover-light dark:[&>.accordion-item>.accordion-trigger]:hover:text-info-hover-dark",
      "[&>.accordion-item:not(:first-child)]:border-t-info-light",
      "dark:[&>.accordion-item:not(:first-child)]:border-t-info-dark"
    ]
  end

  defp color_variant("outline", "misc") do
    [
      "border-misc-light dark:border-misc-dark text-misc-light dark:text-misc-dark",
      "[&>.accordion-item>.accordion-trigger]:hover:text-misc-hover-light dark:[&>.accordion-item>.accordion-trigger]:hover:text-misc-hover-dark",
      "[&>.accordion-item:not(:first-child)]:border-t-misc-light",
      "dark:[&>.accordion-item:not(:first-child)]:border-t-misc-dark"
    ]
  end

  defp color_variant("outline", "dawn") do
    [
      "border-dawn-light dark:border-dawn-dark text-dawn-light dark:text-dawn-dark",
      "[&>.accordion-item>.accordion-trigger]:hover:text-dawn-hover-light dark:[&>.accordion-item>.accordion-trigger]:hover:text-dawn-hover-dark",
      "[&>.accordion-item:not(:first-child)]:border-t-dawn-light",
      "dark:[&>.accordion-item:not(:first-child)]:border-t-dawn-dark"
    ]
  end

  defp color_variant("outline", "silver") do
    [
      "border-silver-light dark:border-silver-dark text-silver-light dark:text-silver-dark",
      "[&>.accordion-item>.accordion-trigger]:hover:text-silver-hover-light dark:[&>.accordion-item>.accordion-trigger]:hover:text-silver-hover-dark",
      "[&>.accordion-item:not(:first-child)]:border-t-silver-light",
      "dark:[&>.accordion-item:not(:first-child)]:border-t-silver-dark"
    ]
  end

  defp color_variant("bordered", "white") do
    [
      "bg-white text-black border-bordered-white-border",
      "[&>.accordion-item>.accordion-trigger]:hover:bg-bordered-white-border"
    ]
  end

  defp color_variant("bordered", "dark") do
    [
      "bg-bordered-dark-bg text-white border-bordered-dark-border",
      "[&>.accordion-item>.accordion-trigger]:hover:bg-bordered-dark-border"
    ]
  end

  defp color_variant("bordered", "natural") do
    [
      "text-natural-bordered-text-light border-natural-border-light bg-natural-bordered-bg-light",
      "dark:text-natural-bordered-text-dark dark:border-natural-border-dark dark:bg-natural-bordered-bg-dark",
      "[&>.accordion-item>.accordion-trigger]:hover:bg-natural-bordered-hover-light dark:[&>.accordion-item>.accordion-trigger]:hover:bg-natural-bordered-hover-dark",
      "[&>.accordion-item:not(:first-child)]:border-t-natural-border-light",
      "dark:[&>.accordion-item:not(:first-child)]:border-t-natural-border-dark"
    ]
  end

  defp color_variant("bordered", "primary") do
    [
      "text-primary-bordered-text-light border-primary-border-light bg-primary-bordered-bg-light",
      "dark:text-primary-bordered-text-dark dark:border-primary-border-dark dark:bg-primary-bordered-bg-dark",
      "[&>.accordion-item>.accordion-trigger]:hover:bg-primary-bordered-hover-light dark:[&>.accordion-item>.accordion-trigger]:hover:bg-primary-bordered-hover-dark",
      "[&>.accordion-item:not(:first-child)]:border-t-primary-border-light",
      "dark:[&>.accordion-item:not(:first-child)]:border-t-primary-border-dark"
    ]
  end

  defp color_variant("bordered", "secondary") do
    [
      "text-secondary-bordered-text-light border-secondary-border-light bg-secondary-bordered-bg-light",
      "dark:text-secondary-bordered-text-dark dark:border-secondary-border-dark dark:bg-secondary-bordered-bg-dark",
      "[&>.accordion-item>.accordion-trigger]:hover:bg-secondary-bordered-hover-light dark:[&>.accordion-item>.accordion-trigger]:hover:bg-secondary-bordered-hover-dark",
      "[&>.accordion-item:not(:first-child)]:border-t-secondary-border-light",
      "dark:[&>.accordion-item:not(:first-child)]:border-t-secondary-border-dark"
    ]
  end

  defp color_variant("bordered", "success") do
    [
      "text-success-bordered-text-light border-success-border-light bg-success-bordered-bg-light",
      "dark:text-success-bordered-text-dark dark:border-success-border-dark dark:bg-success-bordered-bg-dark",
      "[&>.accordion-item>.accordion-trigger]:hover:bg-success-bordered-hover-light dark:[&>.accordion-item>.accordion-trigger]:hover:bg-success-bordered-hover-dark",
      "[&>.accordion-item:not(:first-child)]:border-t-success-border-light",
      "dark:[&>.accordion-item:not(:first-child)]:border-t-success-border-dark"
    ]
  end

  defp color_variant("bordered", "warning") do
    [
      "text-warning-bordered-text-light border-warning-border-light bg-warning-bordered-bg-light",
      "dark:text-warning-bordered-text-dark dark:border-warning-border-dark dark:bg-warning-bordered-bg-dark",
      "[&>.accordion-item>.accordion-trigger]:hover:bg-warning-bordered-hover-light dark:[&>.accordion-item>.accordion-trigger]:hover:bg-warning-bordered-hover-dark",
      "[&>.accordion-item:not(:first-child)]:border-t-warning-border-light",
      "dark:[&>.accordion-item:not(:first-child)]:border-t-warning-border-dark"
    ]
  end

  defp color_variant("bordered", "danger") do
    [
      "text-danger-bordered-text-light border-danger-border-light bg-danger-bordered-bg-light",
      "dark:text-danger-bordered-text-dark dark:border-danger-border-dark dark:bg-danger-bordered-bg-dark",
      "[&>.accordion-item>.accordion-trigger]:hover:bg-danger-bordered-hover-light dark:[&>.accordion-item>.accordion-trigger]:hover:bg-danger-bordered-hover-dark",
      "[&>.accordion-item:not(:first-child)]:border-t-danger-border-light",
      "dark:[&>.accordion-item:not(:first-child)]:border-t-danger-border-dark"
    ]
  end

  defp color_variant("bordered", "info") do
    [
      "text-info-bordered-text-light border-info-border-light bg-info-bordered-bg-light",
      "dark:text-info-bordered-text-dark dark:border-info-border-dark dark:bg-info-bordered-bg-dark",
      "[&>.accordion-item>.accordion-trigger]:hover:bg-info-bordered-hover-light dark:[&>.accordion-item>.accordion-trigger]:hover:bg-info-bordered-hover-dark",
      "[&>.accordion-item:not(:first-child)]:border-t-info-border-light",
      "dark:[&>.accordion-item:not(:first-child)]:border-t-info-border-dark"
    ]
  end

  defp color_variant("bordered", "misc") do
    [
      "text-misc-bordered-text-light border-misc-border-light bg-misc-bordered-bg-light",
      "dark:text-misc-bordered-text-dark dark:border-misc-border-dark dark:bg-misc-bordered-bg-dark",
      "[&>.accordion-item>.accordion-trigger]:hover:bg-misc-bordered-hover-light dark:[&>.accordion-item>.accordion-trigger]:hover:bg-misc-bordered-hover-dark",
      "[&>.accordion-item:not(:first-child)]:border-t-misc-border-light",
      "dark:[&>.accordion-item:not(:first-child)]:border-t-misc-border-dark"
    ]
  end

  defp color_variant("bordered", "dawn") do
    [
      "text-dawn-bordered-text-light border-dawn-border-light bg-dawn-bordered-bg-light",
      "dark:text-dawn-bordered-text-dark dark:border-dawn-border-dark dark:bg-dawn-bordered-bg-dark",
      "[&>.accordion-item>.accordion-trigger]:hover:bg-dawn-bordered-hover-light dark:[&>.accordion-item>.accordion-trigger]:hover:bg-dawn-bordered-hover-dark",
      "[&>.accordion-item:not(:first-child)]:border-t-dawn-border-light",
      "dark:[&>.accordion-item:not(:first-child)]:border-t-dawn-border-dark"
    ]
  end

  defp color_variant("bordered", "silver") do
    [
      "text-silver-bordered-text-light border-silver-border-light bg-silver-bordered-bg-light",
      "dark:text-silver-bordered-text-dark dark:border-silver-border-dark dark:bg-silver-bordered-bg-dark",
      "[&>.accordion-item>.accordion-trigger]:hover:bg-silver-bordered-hover-light dark:[&>.accordion-item>.accordion-trigger]:hover:bg-silver-bordered-hover-dark",
      "[&>.accordion-item:not(:first-child)]:border-t-silver-border-light",
      "dark:[&>.accordion-item:not(:first-child)]:border-t-silver-border-dark"
    ]
  end

  defp color_variant("bordered_separated", "natural") do
    [
      "text-natural-bordered-text-light [&>.accordion-item]:border-natural-border-light",
      "[&>.accordion-item]:bg-natural-bordered-bg-light",
      "dark:text-natural-bordered-text-dark dark:[&>.accordion-item]:border-natural-border-dark",
      "dark:[&>.accordion-item]:bg-natural-bordered-bg-dark",
      "[&>.accordion-item>.accordion-trigger]:hover:bg-natural-bordered-hover-light dark:[&>.accordion-item>.accordion-trigger]:hover:bg-natural-bordered-hover-dark"
    ]
  end

  defp color_variant("bordered_separated", "white") do
    [
      "bg-white text-black [&>.accordion-item]:border-bordered-white-border",
      "[&>.accordion-item>.accordion-trigger]:hover:bg-bordered-white-border"
    ]
  end

  defp color_variant("bordered_separated", "dark") do
    [
      "[&>.accordion-item]:bg-bordered-dark-bg text-white [&>.accordion-item]:border-bordered-dark-border",
      "[&>.accordion-item>.accordion-trigger]:hover:bg-bordered-dark-border"
    ]
  end

  defp color_variant("bordered_separated", "primary") do
    [
      "text-primary-bordered-text-light [&>.accordion-item]:border-primary-border-light",
      "[&>.accordion-item]:bg-primary-bordered-bg-light",
      "dark:text-primary-bordered-text-dark dark:[&>.accordion-item]:border-primary-border-dark",
      "dark:[&>.accordion-item]:bg-primary-bordered-bg-dark",
      "[&>.accordion-item>.accordion-trigger]:hover:bg-primary-bordered-hover-light dark:[&>.accordion-item>.accordion-trigger]:hover:bg-primary-bordered-hover-dark"
    ]
  end

  defp color_variant("bordered_separated", "secondary") do
    [
      "text-secondary-bordered-text-light [&>.accordion-item]:border-secondary-border-light",
      "[&>.accordion-item]:bg-secondary-bordered-bg-light",
      "dark:text-secondary-bordered-text-dark dark:[&>.accordion-item]:border-secondary-border-dark",
      "dark:[&>.accordion-item]:bg-secondary-bordered-bg-dark",
      "[&>.accordion-item>.accordion-trigger]:hover:bg-secondary-bordered-hover-light dark:[&>.accordion-item>.accordion-trigger]:hover:bg-secondary-bordered-hover-dark"
    ]
  end

  defp color_variant("bordered_separated", "success") do
    [
      "text-success-bordered-text-light [&>.accordion-item]:border-success-border-light",
      "[&>.accordion-item]:bg-success-bordered-bg-light",
      "dark:text-success-bordered-text-dark dark:[&>.accordion-item]:border-success-border-dark",
      "dark:[&>.accordion-item]:bg-success-bordered-bg-dark",
      "[&>.accordion-item>.accordion-trigger]:hover:bg-success-bordered-hover-light dark:[&>.accordion-item>.accordion-trigger]:hover:bg-success-bordered-hover-dark"
    ]
  end

  defp color_variant("bordered_separated", "warning") do
    [
      "text-warning-bordered-text-light [&>.accordion-item]:border-warning-border-light",
      "[&>.accordion-item]:bg-warning-bordered-bg-light",
      "dark:text-warning-bordered-text-dark dark:[&>.accordion-item]:border-warning-border-dark",
      "dark:[&>.accordion-item]:bg-warning-bordered-bg-dark",
      "[&>.accordion-item>.accordion-trigger]:hover:bg-warning-bordered-hover-light dark:[&>.accordion-item>.accordion-trigger]:hover:bg-warning-bordered-hover-dark"
    ]
  end

  defp color_variant("bordered_separated", "danger") do
    [
      "text-danger-bordered-text-light [&>.accordion-item]:border-danger-border-light",
      "[&>.accordion-item]:bg-danger-bordered-bg-light",
      "dark:text-danger-bordered-text-dark dark:[&>.accordion-item]:border-danger-border-dark",
      "dark:[&>.accordion-item]:bg-danger-bordered-bg-dark",
      "[&>.accordion-item>.accordion-trigger]:hover:bg-danger-bordered-hover-light dark:[&>.accordion-item>.accordion-trigger]:hover:bg-danger-bordered-hover-dark"
    ]
  end

  defp color_variant("bordered_separated", "info") do
    [
      "text-info-bordered-text-light [&>.accordion-item]:border-info-border-light",
      "[&>.accordion-item]:bg-info-bordered-bg-light",
      "dark:text-info-bordered-text-dark dark:[&>.accordion-item]:border-info-border-dark",
      "dark:[&>.accordion-item]:bg-info-bordered-bg-dark",
      "[&>.accordion-item>.accordion-trigger]:hover:bg-info-bordered-hover-light dark:[&>.accordion-item>.accordion-trigger]:hover:bg-info-bordered-hover-dark"
    ]
  end

  defp color_variant("bordered_separated", "misc") do
    [
      "text-misc-bordered-text-light [&>.accordion-item]:border-misc-border-light",
      "[&>.accordion-item]:bg-misc-bordered-bg-light",
      "dark:text-misc-bordered-text-dark dark:[&>.accordion-item]:border-misc-border-dark",
      "dark:[&>.accordion-item]:bg-misc-bordered-bg-dark",
      "[&>.accordion-item>.accordion-trigger]:hover:bg-misc-bordered-hover-light dark:[&>.accordion-item>.accordion-trigger]:hover:bg-misc-bordered-hover-dark"
    ]
  end

  defp color_variant("bordered_separated", "dawn") do
    [
      "text-dawn-bordered-text-light [&>.accordion-item]:border-dawn-border-light",
      "[&>.accordion-item]:bg-dawn-bordered-bg-light",
      "dark:text-dawn-bordered-text-dark dark:[&>.accordion-item]:border-dawn-border-dark",
      "dark:[&>.accordion-item]:bg-dawn-bordered-bg-dark",
      "[&>.accordion-item>.accordion-trigger]:hover:bg-dawn-bordered-hover-light dark:[&>.accordion-item>.accordion-trigger]:hover:bg-dawn-bordered-hover-dark"
    ]
  end

  defp color_variant("bordered_separated", "silver") do
    [
      "text-silver-bordered-text-light [&>.accordion-item]:border-silver-border-light",
      "[&>.accordion-item]:bg-silver-bordered-bg-light",
      "dark:text-silver-bordered-text-dark dark:[&>.accordion-item]:border-silver-border-dark",
      "dark:[&>.accordion-item]:bg-silver-bordered-bg-dark",
      "[&>.accordion-item>.accordion-trigger]:hover:bg-silver-bordered-hover-light dark:[&>.accordion-item>.accordion-trigger]:hover:bg-silver-bordered-hover-dark"
    ]
  end

  defp color_variant("outline_separated", "natural") do
    [
      "text-natural-light [&>.accordion-item]:border-natural-light",
      "dark:text-natural-dark dark:[&>.accordion-item]:border-natural-dark",
      "[&>.accordion-item>.accordion-trigger]:hover:text-natural-hover-light dark:[&>.accordion-item>.accordion-trigger]:hover:text-natural-hover-dark"
    ]
  end

  defp color_variant("outline_separated", "primary") do
    [
      "text-primary-light [&>.accordion-item]:border-primary-light",
      "dark:text-primary-dark dark:[&>.accordion-item]:border-primary-dark",
      "[&>.accordion-item>.accordion-trigger]:hover:text-primary-hover-light dark:[&>.accordion-item>.accordion-trigger]:hover:text-primary-hover-dark"
    ]
  end

  defp color_variant("outline_separated", "secondary") do
    [
      "text-secondary-light [&>.accordion-item]:border-secondary-light",
      "dark:text-secondary-dark dark:[&>.accordion-item]:border-secondary-dark",
      "[&>.accordion-item>.accordion-trigger]:hover:text-secondary-hover-light dark:[&>.accordion-item>.accordion-trigger]:hover:text-secondary-hover-dark"
    ]
  end

  defp color_variant("outline_separated", "success") do
    [
      "text-success-light [&>.accordion-item]:border-success-light",
      "dark:text-success-dark dark:[&>.accordion-item]:border-success-dark",
      "[&>.accordion-item>.accordion-trigger]:hover:text-success-hover-light dark:[&>.accordion-item>.accordion-trigger]:hover:text-success-hover-dark"
    ]
  end

  defp color_variant("outline_separated", "warning") do
    [
      "text-warning-light [&>.accordion-item]:border-warning-light",
      "dark:text-warning-dark dark:[&>.accordion-item]:border-warning-dark",
      "[&>.accordion-item>.accordion-trigger]:hover:text-warning-hover-light dark:[&>.accordion-item>.accordion-trigger]:hover:text-warning-hover-dark"
    ]
  end

  defp color_variant("outline_separated", "danger") do
    [
      "text-danger-light [&>.accordion-item]:border-danger-light",
      "dark:text-danger-dark dark:[&>.accordion-item]:border-danger-dark",
      "[&>.accordion-item>.accordion-trigger]:hover:text-danger-hover-light dark:[&>.accordion-item>.accordion-trigger]:hover:text-danger-hover-dark"
    ]
  end

  defp color_variant("outline_separated", "info") do
    [
      "text-info-light [&>.accordion-item]:border-info-light",
      "dark:text-info-dark dark:[&>.accordion-item]:border-info-dark",
      "[&>.accordion-item>.accordion-trigger]:hover:text-info-hover-light dark:[&>.accordion-item>.accordion-trigger]:hover:text-info-hover-dark"
    ]
  end

  defp color_variant("outline_separated", "misc") do
    [
      "text-misc-light [&>.accordion-item]:border-misc-light",
      "dark:text-misc-dark dark:[&>.accordion-item]:border-misc-dark",
      "[&>.accordion-item>.accordion-trigger]:hover:text-misc-hover-light dark:[&>.accordion-item>.accordion-trigger]:hover:text-misc-hover-dark"
    ]
  end

  defp color_variant("outline_separated", "dawn") do
    [
      "text-dawn-light [&>.accordion-item]:border-dawn-light",
      "dark:text-dawn-dark dark:[&>.accordion-item]:border-dawn-dark",
      "[&>.accordion-item>.accordion-trigger]:hover:text-dawn-hover-light dark:[&>.accordion-item>.accordion-trigger]:hover:text-dawn-hover-dark"
    ]
  end

  defp color_variant("outline_separated", "silver") do
    [
      "text-silver-light [&>.accordion-item]:border-silver-light",
      "dark:text-silver-dark dark:[&>.accordion-item]:border-silver-dark",
      "[&>.accordion-item>.accordion-trigger]:hover:text-silver-hover-light dark:[&>.accordion-item>.accordion-trigger]:hover:text-silver-hover-dark"
    ]
  end

  defp color_variant("shadow", "natural") do
    [
      "bg-natural-light text-white dark:bg-natural-dark dark:text-black",
      "[&>.accordion-item>.accordion-trigger]:hover:bg-natural-hover-light",
      "dark:[&>.accordion-item>.accordion-trigger]:hover:bg-natural-hover-dark",
      "shadow-[0px_4px_6px_-4px_var(--color-shadow-natural)] shadow-[0px_10px_15px_-3px_var(--color-shadow-natural)] dark:shadow-none"
    ]
  end

  defp color_variant("shadow", "primary") do
    [
      "bg-primary-light text-white dark:bg-primary-dark dark:text-black",
      "[&>.accordion-item>.accordion-trigger]:hover:bg-primary-hover-light",
      "dark:[&>.accordion-item>.accordion-trigger]:hover:bg-primary-hover-dark",
      "shadow-[0px_4px_6px_-4px_var(--color-shadow-primary)] shadow-[0px_10px_15px_-3px_var(--color-shadow-primary)] dark:shadow-none"
    ]
  end

  defp color_variant("shadow", "secondary") do
    [
      "bg-secondary-light text-white dark:bg-secondary-dark dark:text-black",
      "[&>.accordion-item>.accordion-trigger]:hover:bg-secondary-hover-light",
      "dark:[&>.accordion-item>.accordion-trigger]:hover:bg-secondary-hover-dark",
      "shadow-[0px_4px_6px_-4px_var(--color-shadow-secondary)] shadow-[0px_10px_15px_-3px_var(--color-shadow-secondary)] dark:shadow-none"
    ]
  end

  defp color_variant("shadow", "success") do
    [
      "bg-success-light text-white dark:bg-success-dark dark:text-black",
      "[&>.accordion-item>.accordion-trigger]:hover:bg-success-hover-light",
      "dark:[&>.accordion-item>.accordion-trigger]:hover:bg-success-hover-dark",
      "shadow-[0px_4px_6px_-4px_var(--color-shadow-success)] shadow-[0px_10px_15px_-3px_var(--color-shadow-success)] dark:shadow-none"
    ]
  end

  defp color_variant("shadow", "warning") do
    [
      "bg-warning-light text-white dark:bg-warning-dark dark:text-black",
      "[&>.accordion-item>.accordion-trigger]:hover:bg-warning-hover-light",
      "dark:[&>.accordion-item>.accordion-trigger]:hover:bg-warning-hover-dark",
      "shadow-[0px_4px_6px_-4px_var(--color-shadow-warning)] shadow-[0px_10px_15px_-3px_var(--color-shadow-warning)] dark:shadow-none"
    ]
  end

  defp color_variant("shadow", "danger") do
    [
      "bg-danger-light text-white dark:bg-danger-dark dark:text-black",
      "[&>.accordion-item>.accordion-trigger]:hover:bg-danger-hover-light",
      "dark:[&>.accordion-item>.accordion-trigger]:hover:bg-danger-hover-dark",
      "shadow-[0px_4px_6px_-4px_var(--color-shadow-danger)] shadow-[0px_10px_15px_-3px_var(--color-shadow-danger)] dark:shadow-none"
    ]
  end

  defp color_variant("shadow", "info") do
    [
      "bg-info-light text-white dark:bg-info-dark dark:text-black",
      "[&>.accordion-item>.accordion-trigger]:hover:bg-info-hover-light",
      "dark:[&>.accordion-item>.accordion-trigger]:hover:bg-info-hover-dark",
      "shadow-[0px_4px_6px_-4px_var(--color-shadow-info)] shadow-[0px_10px_15px_-3px_var(--color-shadow-info)] dark:shadow-none"
    ]
  end

  defp color_variant("shadow", "misc") do
    [
      "bg-misc-light text-white dark:bg-misc-dark dark:text-black",
      "[&>.accordion-item>.accordion-trigger]:hover:bg-misc-hover-light",
      "dark:[&>.accordion-item>.accordion-trigger]:hover:bg-misc-hover-dark",
      "shadow-[0px_4px_6px_-4px_var(--color-shadow-misc)] shadow-[0px_10px_15px_-3px_var(--color-shadow-misc)] dark:shadow-none"
    ]
  end

  defp color_variant("shadow", "dawn") do
    [
      "bg-dawn-light text-white dark:bg-dawn-dark dark:text-black",
      "[&>.accordion-item>.accordion-trigger]:hover:bg-dawn-hover-light",
      "dark:[&>.accordion-item>.accordion-trigger]:hover:bg-dawn-hover-dark",
      "shadow-[0px_4px_6px_-4px_var(--color-shadow-dawn)] shadow-[0px_10px_15px_-3px_var(--color-shadow-dawn)] dark:shadow-none"
    ]
  end

  defp color_variant("shadow", "silver") do
    [
      "bg-silver-light text-white dark:bg-silver-dark dark:text-black",
      "[&>.accordion-item>.accordion-trigger]:hover:bg-silver-hover-light",
      "dark:[&>.accordion-item>.accordion-trigger]:hover:bg-silver-hover-dark",
      "shadow-[0px_4px_6px_-4px_var(--color-shadow-silver)] shadow-[0px_10px_15px_-3px_var(--color-shadow-silver)] dark:shadow-none"
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

  defp space_class(_, variant)
       when variant not in ["base_separated", "outline_separated", "bordered_separated"],
       do: nil

  defp space_class("extra_small", _), do: "space-y-1"

  defp space_class("small", _), do: "space-y-2"

  defp space_class("medium", _), do: "space-y-3"

  defp space_class("large", _), do: "space-y-4"

  defp space_class("extra_large", _), do: "space-y-6"

  defp space_class(params, _) when is_binary(params), do: params

  defp border_class("none", _), do: nil

  defp border_class("extra_small", variant)
       when variant in ["base_separated", "outline_separated", "bordered_separated"] do
    "[&>.accordion-item]:border"
  end

  defp border_class("extra_small", variant) when variant in ["base", "outline", "bordered"] do
    [
      "border",
      "[&>.accordion-item:not(:first-child)]:border-t"
    ]
  end

  defp border_class("small", variant)
       when variant in ["base_separated", "outline_separated", "bordered_separated"] do
    "[&>.accordion-item]:border-2"
  end

  defp border_class("small", variant) when variant in ["base", "outline", "bordered"] do
    [
      "border-2",
      "[&>.accordion-item:not(:first-child)]:border-t-2"
    ]
  end

  defp border_class("medium", variant)
       when variant in ["base_separated", "outline_separated", "bordered_separated"] do
    "[&>.accordion-item]:border-[3px]"
  end

  defp border_class("medium", variant) when variant in ["base", "outline", "bordered"] do
    [
      "border-[3px]",
      "[&>.accordion-item:not(:first-child)]:border-t-[3px]"
    ]
  end

  defp border_class("large", variant)
       when variant in ["base_separated", "outline_separated", "bordered_separated"] do
    "[&>.accordion-item]:border-4"
  end

  defp border_class("large", variant) when variant in ["base", "outline", "bordered"] do
    [
      "border-4",
      "[&>.accordion-item:not(:first-child)]:border-t-4"
    ]
  end

  defp border_class("extra_large", variant)
       when variant in ["base_separated", "outline_separated", "bordered_separated"] do
    "[&>.accordion-item]:border-[5px]"
  end

  defp border_class("extra_large", variant) when variant in ["base", "outline", "bordered"] do
    [
      "border-[5px]",
      "[&>.accordion-item:not(:first-child)]:border-t-[5px]"
    ]
  end

  defp border_class(params, _) when is_binary(params), do: params
  defp border_class(_, _), do: nil

  defp rounded_class("none", variant)
       when variant in ["base_separated", "outline_separated", "bordered_separated"],
       do: nil

  defp rounded_class("extra_small", variant)
       when variant in ["base_separated", "outline_separated", "bordered_separated"] do
    "[&>.accordion-item]:rounded-sm"
  end

  defp rounded_class("small", variant)
       when variant in ["base_separated", "outline_separated", "bordered_separated"] do
    "[&>.accordion-item]:rounded"
  end

  defp rounded_class("medium", variant)
       when variant in ["base_separated", "outline_separated", "bordered_separated"] do
    "[&>.accordion-item]:rounded-lg"
  end

  defp rounded_class("large", variant)
       when variant in ["base_separated", "outline_separated", "bordered_separated"] do
    "[&>.accordion-item]:rounded-xl"
  end

  defp rounded_class("extra_large", variant)
       when variant in ["base_separated", "outline_separated", "bordered_separated"] do
    "[&>.accordion-item]:rounded-2xl"
  end

  defp rounded_class("none", _), do: nil

  defp rounded_class("extra_small", _), do: "rounded-sm"

  defp rounded_class("small", _), do: "rounded"

  defp rounded_class("medium", _), do: "rounded-lg"

  defp rounded_class("large", _), do: "rounded-xl"

  defp rounded_class("extra_large", _), do: "rounded-2xl"

  defp rounded_class(params, _) when is_binary(params), do: params

  defp media_size("extra_small"),
    do: "[&>.accordion-item>.accordion-trigger_.accordion-title-media]:size-12"

  defp media_size("small"),
    do: "[&>.accordion-item>.accordion-trigger_.accordion-title-media]:size-14"

  defp media_size("medium"),
    do: "[&>.accordion-item>.accordion-trigger_.accordion-title-media]:size-16"

  defp media_size("large"),
    do: "[&>.accordion-item>.accordion-trigger_.accordion-title-media]:size-20"

  defp media_size("extra_large"),
    do: "[&>.accordion-item>.accordion-trigger_.accordion-title-media]:size-24"

  defp media_size(params) when is_binary(params), do: params

  defp padding_size("extra_small") do
    [
      "[&>.accordion-item>.accordion-trigger]:p-1",
      "[&>.accordion-item_.accordion-panel-content]:p-1"
    ]
  end

  defp padding_size("small") do
    [
      "[&>.accordion-item>.accordion-trigger]:p-2",
      "[&>.accordion-item_.accordion-panel-content]:p-2"
    ]
  end

  defp padding_size("medium") do
    [
      "[&>.accordion-item>.accordion-trigger]:p-3",
      "[&>.accordion-item_.accordion-panel-content]:p-3"
    ]
  end

  defp padding_size("large") do
    [
      "[&>.accordion-item>.accordion-trigger]:p-4",
      "[&>.accordion-item_.accordion-panel-content]:p-4"
    ]
  end

  defp padding_size("extra_large") do
    [
      "[&>.accordion-item>.accordion-trigger]:p-5",
      "[&>.accordion-item_.accordion-panel-content]:p-5"
    ]
  end

  defp padding_size(params) when is_binary(params), do: params

  defp size_class("extra_small") do
    [
      "text-[10px]",
      "[&>.accordion-item>.accordion-trigger_.accordion-chevron]:size-3",
      "[&>.accordion-item>.accordion-trigger_.accordion-icon]:size-3",
      "[&>.accordion-item>.accordion-trigger_.accordion-title]:text-[10px]",
      "[&>.accordion-item>.accordion-trigger_.accordion-description]:text-[8px]"
    ]
  end

  defp size_class("small") do
    [
      "text-[12px]",
      "[&>.accordion-item>.accordion-trigger_.accordion-chevron]:size-4",
      "[&>.accordion-item>.accordion-trigger_.accordion-icon]:size-4",
      "[&>.accordion-item>.accordion-trigger_.accordion-title]:text-[12px]",
      "[&>.accordion-item>.accordion-trigger_.accordion-description]:text-[10px]"
    ]
  end

  defp size_class("medium") do
    [
      "text-[14px]",
      "[&>.accordion-item>.accordion-trigger_.accordion-chevron]:size-5",
      "[&>.accordion-item>.accordion-trigger_.accordion-icon]:size-5",
      "[&>.accordion-item>.accordion-trigger_.accordion-title]:text-[14px]",
      "[&>.accordion-item>.accordion-trigger_.accordion-description]:text-[12px]"
    ]
  end

  defp size_class("large") do
    [
      "text-[16px]",
      "[&>.accordion-item>.accordion-trigger_.accordion-chevron]:size-6",
      "[&>.accordion-item>.accordion-trigger_.accordion-icon]:size-6",
      "[&>.accordion-item>.accordion-trigger_.accordion-title]:text-[16px]",
      "[&>.accordion-item>.accordion-trigger_.accordion-description]:text-[14px]"
    ]
  end

  defp size_class("extra_large") do
    [
      "text-[18px]",
      "[&>.accordion-item>.accordion-trigger_.accordion-chevron]:size-7",
      "[&>.accordion-item>.accordion-trigger_.accordion-icon]:size-7",
      "[&>.accordion-item>.accordion-trigger_.accordion-title]:text-[18px]",
      "[&>.accordion-item>.accordion-trigger_.accordion-description]:text-[16px]"
    ]
  end

  defp size_class(params) when is_binary(params), do: params

  defp chevron_visible?(assigns) do
    !assigns.hide_chevron
  end

  defp chevron_position(assigns) do
    cond do
      assigns.left_chevron -> "left"
      assigns.right_chevron -> "right"
      true -> assigns.chevron_position
    end
  end

  defp chevron_classes(assigns) do
    [
      "accordion-chevron transform transition-transform duration-200",
      "group-aria-expanded:rotate-180",
      assigns.chevron_class
    ]
  end
end
