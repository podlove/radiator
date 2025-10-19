defmodule RadiatorWeb.Components.Pagination do
  @moduledoc """
  The `RadiatorWeb.Components.Pagination` module provides a comprehensive and highly customizable
  pagination component for Phoenix LiveView applications.

  It is designed to handle complex pagination scenarios, supporting various styles,
  sizes, colors, and interaction patterns.

  This module offers several options to tailor the pagination component's appearance and behavior,
  such as custom icons, separators, and control buttons.

  It allows for fine-tuning of the pagination layout, including sibling and boundary
  controls, as well as different visual variants like outlined, shadowed, and inverted styles.

  These features enable developers to integrate pagination seamlessly into their UI,
  enhancing user experience and interaction.

  **Documentation:** https://mishka.tools/chelekom/docs/pagination
  """

  use Phoenix.Component
  alias Phoenix.LiveView.JS
  import RadiatorWeb.Components.Icon, only: [icon: 1]
  use Gettext, backend: RadiatorWeb.Gettext

  @doc """
  Renders a `pagination` component that allows users to navigate through pages.

  The component supports various configurations such as setting the total number of pages,
  current active page, and the number of sibling and boundary pages to display.

  Custom icons or labels can be used for navigation controls, and slots are available
  for additional start and end items.

  ## Examples

  ```elixir
  <.pagination
    total={200}
    active={@posts.active}
    siblings={3}
    show_edges
    grouped
    next_label="next"
    previous_label="prev"
    first_label="first"
    last_label="last"
  />

  <.pagination total={@posts.total} active={@posts.active} siblings={3} variant="outline" show_edges grouped/>
  ```
  """
  @doc type: :component
  attr :id, :string,
    default: nil,
    doc: "A unique identifier is used to manage state and interaction"

  attr :total, :integer, required: true, doc: ""
  attr :active, :integer, default: 1, doc: ""
  attr :siblings, :integer, default: 1, doc: ""
  attr :boundaries, :integer, default: 1, doc: ""
  attr :on_select, JS, default: %JS{}, doc: "Custom JS module for on_select action"
  attr :on_first, JS, default: %JS{}, doc: "Custom JS module for on_first action"
  attr :on_last, JS, default: %JS{}, doc: "Custom JS module for on_last action"
  attr :on_next, JS, default: %JS{}, doc: "Custom JS module for on_next action"
  attr :on_previous, JS, default: %JS{}, doc: "Custom JS module for on_previous action"

  attr :size, :string,
    default: "medium",
    doc:
      "Determines the overall size of the elements, including padding, font size, and other items"

  attr :space, :string, default: "small", doc: "Space between items"
  attr :color, :string, default: "base", doc: "Determines color theme"
  attr :rounded, :string, default: "small", doc: "Determines the border radius"
  attr :border, :string, default: "extra_small", doc: "Determines the border radius"

  attr :variant, :string, default: "base", doc: "Determines the style"

  attr :separator, :map,
    default: %{type: :icon, value: "hero-ellipsis-horizontal"},
    doc: "Separator between page groups"

  attr :first_label, :map,
    default: %{type: :icon, value: "hero-chevron-double-left"},
    doc: "Label for the 'first' button"

  attr :last_label, :map,
    default: %{type: :icon, value: "hero-chevron-double-right"},
    doc: "Label for the 'last' button"

  attr :next_label, :map,
    default: %{type: :icon, value: "hero-chevron-right"},
    doc: "Label for the 'next' button"

  attr :previous_label, :map,
    default: %{type: :icon, value: "hero-chevron-left"},
    doc: "Label for the 'previous' button"

  attr :class, :string, default: nil, doc: "Custom CSS class for additional styling"

  attr :first_label_class, :string,
    default: nil,
    doc: "Custom CSS class for additional styling to first button"

  attr :next_label_class, :string,
    default: nil,
    doc: "Custom CSS class for additional styling to next button"

  attr :last_label_class, :string,
    default: nil,
    doc: "Custom CSS class for additional styling to last button"

  attr :prev_label_class, :string,
    default: nil,
    doc: "Custom CSS class for additional styling to previous button"

  attr :pages_label_class, :string,
    default: nil,
    doc: "Custom CSS class for additional styling to pages buttons"

  attr :separator_class, :string,
    default: nil,
    doc: "Custom CSS class for additional styling to pages buttons"

  attr :separator_icon_class, :string,
    default: nil,
    doc: "Custom CSS class for additional styling to icon of separator"

  attr :separator_text_class, :string,
    default: nil,
    doc: "Custom CSS class for additional styling to text of separator"

  attr :params, :map,
    default: %{},
    doc: "A map of additional parameters used for element configuration"

  slot :start_items, required: false, doc: "Determines the start items which accept heex"
  slot :end_items, required: false, doc: "Determines the end items which accept heex"

  attr :rest, :global,
    include: ~w(disabled hide_one_page show_edges hide_controls grouped),
    doc:
      "Global attributes can define defaults which are merged with attributes provided by the caller"

  def pagination(
        %{siblings: siblings, boundaries: boundaries, total: total, active: active} = assigns
      ) do
    assigns = assign(assigns, %{siblings: build_pagination(total, active, siblings, boundaries)})

    ~H"""
    <nav
      :if={show_pagination?(@rest[:hide_one_page], @total)}
      id={@id}
      class={[
        default_classes(),
        color_variant(@variant, @color),
        border_size(@border, @variant),
        rounded_size(@rounded),
        size_class(@size),
        border_class(@color),
        (!is_nil(@rest[:grouped]) && "gap-0 grouped-pagination") || space_class(@space),
        @class
      ]}
      {@rest}
    >
      {render_slot(@start_items)}

      <.item_button
        :if={@rest[:show_edges]}
        on_action={{"first", @on_first}}
        page={{nil, @active}}
        params={@params}
        label={@first_label}
        class={@first_label_class}
        aria_label={gettext("First page")}
        disabled={@active <= 1}
      />

      <.item_button
        :if={is_nil(@rest[:hide_controls])}
        on_action={{"previous", @on_previous}}
        page={{nil, @active}}
        params={@params}
        label={@previous_label}
        class={@prev_label_class}
        aria_label={gettext("Previous page")}
        disabled={@active <= 1}
      />

      <div :for={range <- @siblings.range}>
        <%= if is_integer(range) do %>
          <.item_button
            on_action={{"select", @on_select}}
            page={{range, @active}}
            params={@params}
            class={@pages_label_class}
          />
        <% else %>
          <div
            class={["pagination-separator flex justify-center items-center", @separator_class]}
            aria-hidden="true"
          >
            <.icon
              :if={Map.get(@separator, :type) == :icon}
              name={@separator.value}
              class={["pagination-icon", @separator_icon_class]}
            />
            <span
              :if={Map.get(@separator, :type) != :icon}
              class={["pagination-text", @separator_text_class]}
            >
              {@separator.value}
            </span>
          </div>
        <% end %>
      </div>

      <.item_button
        :if={is_nil(@rest[:hide_controls])}
        on_action={{"next", @on_next}}
        page={{nil, @active}}
        params={@params}
        label={@next_label}
        class={@next_label_class}
        aria_label={gettext("Next page")}
        disabled={@active >= @total}
      />

      <.item_button
        :if={@rest[:show_edges]}
        on_action={{"last", @on_last}}
        page={{nil, @active}}
        params={@params}
        label={@last_label}
        class={@last_label_class}
        aria_label={gettext("Last page")}
        disabled={@active >= @total}
      />

      {render_slot(@end_items)}
    </nav>
    """
  end

  @doc type: :component
  attr :params, :map,
    default: %{},
    doc: "A map of additional parameters used for element configuration"

  attr :page, :list, required: true, doc: "Specifies pagination pages"
  attr :on_action, JS, default: %JS{}, doc: "Custom JS module for on_action action"
  attr :label, :string, required: false, doc: "Icon displayed alongside of an item"
  attr :disabled, :boolean, required: false, doc: "Specifies whether the element is disabled"
  attr :aria_label, :string, default: nil, doc: "Accessible label for screen readers"
  attr :class, :string, default: nil, doc: "Custom class for additional styling"

  defp item_button(%{on_action: {"select", _on_action}} = assigns) do
    ~H"""
    <button
      aria-current={elem(@page, 1) == elem(@page, 0) && "page"}
      aria-label={
        if elem(@page, 1) == elem(@page, 0) do
          gettext("Page %{page}, current page", page: elem(@page, 0))
        else
          gettext("Go to page %{page}", page: elem(@page, 0))
        end
      }
      aria-disabled={elem(@page, 0) == elem(@page, 1)}
      class={[
        "pagination-button cursor-pointer",
        elem(@page, 1) == elem(@page, 0) && "active-pagination-button",
        @class
      ]}
      phx-click={
        elem(@on_action, 1)
        |> JS.push("pagination", value: Map.merge(%{action: "select", page: elem(@page, 0)}, @params))
      }
      disabled={elem(@page, 0) == elem(@page, 1)}
    >
      {elem(@page, 0)}
    </button>
    """
  end

  defp item_button(assigns) do
    ~H"""
    <button
      class={["pagination-control flex items-center justify-center cursor-pointer", @class]}
      aria-disabled={@disabled}
      aria-label={@aria_label}
      phx-click={
        elem(@on_action, 1)
        |> JS.push("pagination", value: Map.merge(%{action: elem(@on_action, 0)}, @params))
      }
      disabled={@disabled}
    >
      <.icon :if={Map.get(@label, :type) == :icon} name={@label.value} class="pagination-icon" />
      <span :if={Map.get(@label, :type) != :icon} class="pagination-text">{@label.value}</span>
    </button>
    """
  end

  # We got the original code from mantine.dev pagination hook and changed some numbers
  defp build_pagination(total, current_page, siblings, boundaries) do
    total_pages = max(total, 0)

    total_page_numbers = siblings * 2 + 3 + boundaries * 2

    pagination_range =
      if total_page_numbers >= total_pages do
        range(1, total_pages)
      else
        left_sibling_index = max(current_page - siblings, boundaries + 1)
        right_sibling_index = min(current_page + siblings, total_pages - boundaries)

        should_show_left_dots = left_sibling_index > boundaries + 2
        should_show_right_dots = right_sibling_index < total_pages - boundaries - 1

        dots = :dots

        cond do
          !should_show_left_dots and should_show_right_dots ->
            left_item_count = siblings * 2 + boundaries + 2

            range(1, left_item_count) ++
              [dots] ++ range(total_pages - boundaries + 1, total_pages)

          should_show_left_dots and not should_show_right_dots ->
            right_item_count = boundaries + 1 + 2 * siblings

            range(1, boundaries) ++
              [dots] ++ range(total_pages - right_item_count + 1, total_pages)

          true ->
            range(1, boundaries) ++
              [dots] ++
              range(left_sibling_index, right_sibling_index) ++
              [dots] ++ range(total_pages - boundaries + 1, total_pages)
        end
      end

    %{range: pagination_range(current_page, pagination_range), active: current_page}
  end

  defp pagination_range(active, range) do
    if active != 1 and (active - 1) not in range do
      index = Enum.find_index(range, &(&1 == active))
      List.insert_at(range, index, active - 1)
    else
      range
    end
  end

  defp range(start, stop) when start > stop, do: []
  defp range(start, stop), do: Enum.to_list(start..stop)

  defp space_class("extra_small"), do: "gap-2"
  defp space_class("small"), do: "gap-3"
  defp space_class("medium"), do: "gap-4"
  defp space_class("large"), do: "gap-5"
  defp space_class("extra_large"), do: "gap-6"
  defp space_class("none"), do: nil
  defp space_class(params) when is_binary(params), do: params

  defp border_size(_, variant)
       when variant in [
              "default",
              "shadow",
              "transparent",
              "subtle",
              "gradient"
            ],
       do: nil

  defp border_size("none", _), do: "[&:not(.grouped-pagination)_.pagination-button]:border-0"

  defp border_size("extra_small", _), do: "[&:not(.grouped-pagination)_.pagination-button]:border"

  defp border_size("small", _), do: "[&:not(.grouped-pagination)_.pagination-button]:border-2"

  defp border_size("medium", _),
    do: "[&:not(.grouped-pagination)_.pagination-button]:border-[3px]"

  defp border_size("large", _), do: "[&:not(.grouped-pagination)_.pagination-button]:border-4"

  defp border_size("extra_large", _),
    do: "[&:not(.grouped-pagination)_.pagination-button]:border-[5px]"

  defp border_size(params, _) when is_binary(params), do: params

  defp border_class("transparent") do
    ["[&.grouped-pagination]:border border-transparent"]
  end

  defp border_class("base") do
    [
      "[&.grouped-pagination]:border [&.grouped-pagination_.pagination-button]:border-r",
      "[&.grouped-pagination_.pagination-control:not(:last-child)]:border-r",
      "[&.grouped-pagination_.pagination-separator]:border-r",
      "border-base-border-light [&.grouped-pagination_.pagination-button]:border-base-border-light",
      "[&.grouped-pagination_.pagination-control:not(:last-child)]:border-base-border-light",
      "[&.grouped-pagination_.pagination-separator]:border-base-border-light",
      "dark:border-base-border-dark dark:[&.grouped-pagination_.pagination-button]:border-base-border-dark",
      "dark:[&.grouped-pagination_.pagination-control:not(:last-child)]:border-base-border-dark",
      "dark:[&.grouped-pagination_.pagination-separator]:border-base-border-dark"
    ]
  end

  defp border_class("natural") do
    [
      "[&.grouped-pagination]:border [&.grouped-pagination_.pagination-button]:border-r",
      "border-natural-dark [&.grouped-pagination_.pagination-button]:border-natural-dark",
      "[&.grouped-pagination_.pagination-control:not(:last-child)]:border-r",
      "[&.grouped-pagination_.pagination-control:not(:last-child)]:border-natural-dark",
      "[&.grouped-pagination_.pagination-separator]:border-r",
      "[&.grouped-pagination_.pagination-separator]:border-natural-dark"
    ]
  end

  defp border_class("primary") do
    [
      "[&.grouped-pagination]:border [&.grouped-pagination_.pagination-button]:border-r",
      "border-[var(--color-secondary-light)] [&.grouped-pagination_.pagination-button]:border-[var(--color-secondary-hover-light)]",
      "[&.grouped-pagination_.pagination-control:not(:last-child)]:border-r",
      "[&.grouped-pagination_.pagination-control:not(:last-child)]:border-[var(--color-secondary-hover-light)]",
      "[&.grouped-pagination_.pagination-separator]:border-r",
      "[&.grouped-pagination_.pagination-separator]:border-[var(--color-secondary-hover-light)]"
    ]
  end

  defp border_class("secondary") do
    [
      "[&.grouped-pagination]:border [&.grouped-pagination_.pagination-button]:border-r",
      "border-slate-500 [&.grouped-pagination_.pagination-button]:border-slate-700",
      "[&.grouped-pagination_.pagination-control:not(:last-child)]:border-r",
      "[&.grouped-pagination_.pagination-control:not(:last-child)]:border-slate-700",
      "[&.grouped-pagination_.pagination-separator]:border-r",
      "[&.grouped-pagination_.pagination-separator]:border-slate-700"
    ]
  end

  defp border_class("success") do
    [
      "[&.grouped-pagination]:border [&.grouped-pagination_.pagination-button]:border-r",
      "border-emerald-700 [&.grouped-pagination_.pagination-button]:border-emerald-700",
      "[&.grouped-pagination_.pagination-control:not(:last-child)]:border-r",
      "[&.grouped-pagination_.pagination-control:not(:last-child)]:border-emerald-700",
      "[&.grouped-pagination_.pagination-separator]:border-r",
      "[&.grouped-pagination_.pagination-separator]:border-emerald-700"
    ]
  end

  defp border_class("warning") do
    [
      "[&.grouped-pagination]:border [&.grouped-pagination_.pagination-button]:border-r",
      "border-warning-indicator-light [&.grouped-pagination_.pagination-button]:border-warning-indicator-light",
      "[&.grouped-pagination_.pagination-control:not(:last-child)]:border-r",
      "[&.grouped-pagination_.pagination-control:not(:last-child)]:border-warning-indicator-light",
      "[&.grouped-pagination_.pagination-separator]:border-r",
      "[&.grouped-pagination_.pagination-separator]:border-warning-indicator-light"
    ]
  end

  defp border_class("danger") do
    [
      "[&.grouped-pagination]:border [&.grouped-pagination_.pagination-button]:border-r",
      "border-danger-indicator-light [&.grouped-pagination_.pagination-button]:border-danger-indicator-light",
      "[&.grouped-pagination_.pagination-control:not(:last-child)]:border-r",
      "[&.grouped-pagination_.pagination-control:not(:last-child)]:border-danger-indicator-light",
      "[&.grouped-pagination_.pagination-separator]:border-r",
      "[&.grouped-pagination_.pagination-separator]:border-danger-indicator-light"
    ]
  end

  defp border_class("info") do
    [
      "[&.grouped-pagination]:border [&.grouped-pagination_.pagination-button]:border-r",
      "border-info-indicator-light [&.grouped-pagination_.pagination-button]:border-info-indicator-light",
      "[&.grouped-pagination_.pagination-control:not(:last-child)]:border-r",
      "[&.grouped-pagination_.pagination-control:not(:last-child)]:border-info-indicator-light",
      "[&.grouped-pagination_.pagination-separator]:border-r",
      "[&.grouped-pagination_.pagination-separator]:border-info-indicator-light"
    ]
  end

  defp border_class("misc") do
    [
      "[&.grouped-pagination]:border [&.grouped-pagination_.pagination-button]:border-r",
      "border-misc-indicator-light [&.grouped-pagination_.pagination-button]:border-misc-indicator-light",
      "[&.grouped-pagination_.pagination-control:not(:last-child)]:border-r",
      "[&.grouped-pagination_.pagination-control:not(:last-child)]:border-misc-indicator-light",
      "[&.grouped-pagination_.pagination-separator]:border-r",
      "[&.grouped-pagination_.pagination-separator]:border-misc-indicator-light"
    ]
  end

  defp border_class("dawn") do
    [
      "[&.grouped-pagination]:border [&.grouped-pagination_.pagination-button]:border-r",
      "border-dawn-indicator-light [&.grouped-pagination_.pagination-button]:border-dawn-indicator-light",
      "[&.grouped-pagination_.pagination-control:not(:last-child)]:border-r",
      "[&.grouped-pagination_.pagination-control:not(:last-child)]:border-dawn-indicator-light",
      "[&.grouped-pagination_.pagination-separator]:border-r",
      "[&.grouped-pagination_.pagination-separator]:border-dawn-indicator-light"
    ]
  end

  defp border_class("silver") do
    [
      "[&.grouped-pagination]:border [&.grouped-pagination_.pagination-button]:border-r",
      "border-silver-indicator-light [&.grouped-pagination_.pagination-button]:border-silver-indicator-light",
      "[&.grouped-pagination_.pagination-control:not(:last-child)]:border-r",
      "[&.grouped-pagination_.pagination-control:not(:last-child)]:border-silver-indicator-light",
      "[&.grouped-pagination_.pagination-separator]:border-r",
      "[&.grouped-pagination_.pagination-separator]:border-silver-indicator-light"
    ]
  end

  defp border_class("dark") do
    [
      "[&.grouped-pagination]:bg-default-dark-bg [&.grouped-pagination]:text-base-text-dark",
      "[&.grouped-pagination]:border [&.grouped-pagination_.pagination-button]:border-r",
      "border-base-bg-dark [&.grouped-pagination_.pagination-button]:border-bordered-dark-border",
      "[&.grouped-pagination_.pagination-control:not(:last-child)]:border-r",
      "[&.grouped-pagination_.pagination-control:not(:last-child)]:border-bordered-dark-border",
      "[&.grouped-pagination_.pagination-separator]:border-r",
      "[&.grouped-pagination_.pagination-separator]:border-bordered-dark-border"
    ]
  end

  defp border_class(params) when is_binary(params), do: params

  defp rounded_size("extra_small"),
    do:
      "[&.grouped-pagination]:rounded-sm [&:not(.grouped-pagination)_.pagination-button]:rounded-sm"

  defp rounded_size("small"),
    do: "[&.grouped-pagination]:rounded [&:not(.grouped-pagination)_.pagination-button]:rounded"

  defp rounded_size("medium"),
    do:
      "[&.grouped-pagination]:rounded-md [&:not(.grouped-pagination)_.pagination-button]:rounded-md"

  defp rounded_size("large"),
    do:
      "[&.grouped-pagination]:rounded-lg [&:not(.grouped-pagination)_.pagination-button]:rounded-lg"

  defp rounded_size("extra_large"),
    do:
      "[&.grouped-pagination]:rounded-xl [&:not(.grouped-pagination)_.pagination-button]:rounded-xl"

  defp rounded_size("full"),
    do:
      "[&.grouped-pagination]:rounded-full [&:not(.grouped-pagination)_.pagination-button]:rounded-full"

  defp rounded_size("none"),
    do:
      "[&.grouped-pagination]:rounded-none [&:not(.grouped-pagination)_.pagination-button]:rounded-none"

  defp size_class("extra_small") do
    [
      "[&.grouped-pagination_.pagination-button]:w-full [&.grouped-pagination_.pagination-button]:px-3",
      "[&:not(.grouped-pagination)_.pagination-button]:w-6",
      "[&.grouped-pagination_.pagination-button]:min-w-6 [&.grouped-pagination_.pagination-control]:min-w-6",
      "[&_.pagination-button]:h-6 [&_.pagination-control>.pagination-icon]:h-6",
      "[&_.pagination-control]:px-2",
      "[&_.pagination-separator]:h-6 text-xs",
      "[&_:not(.pagination-separator)>.pagination-icon]:size-3.5"
    ]
  end

  defp size_class("small") do
    [
      "[&.grouped-pagination_.pagination-button]:w-full [&.grouped-pagination_.pagination-button]:px-3",
      "[&:not(.grouped-pagination)_.pagination-button]:w-7",
      "[&.grouped-pagination_.pagination-button]:min-w-7 [&.grouped-pagination_.pagination-control]:min-w-7",
      "[&_.pagination-button]:h-7 [&_.pagination-control>.pagination-icon]:h-7",
      "[&_.pagination-control]:px-2",
      "[&_.pagination-separator]:w-full [&_.pagination-separator]:h-7 text-sm",
      "[&_:not(.pagination-separator)>.pagination-icon]:size-4"
    ]
  end

  defp size_class("medium") do
    [
      "[&.grouped-pagination_.pagination-button]:w-full [&.grouped-pagination_.pagination-button]:px-3",
      "[&:not(.grouped-pagination)_.pagination-button]:w-8",
      "[&.grouped-pagination_.pagination-button]:min-w-8 [&.grouped-pagination_.pagination-control]:min-w-8",
      "[&_.pagination-control]:px-2",
      "[&_.pagination-button]:h-8 [&_.pagination-control>.pagination-icon]:h-8",
      "[&_.pagination-separator]:w-full [&_.pagination-separator]:h-8 text-base",
      "[&_:not(.pagination-separator)>.pagination-icon]:size-5"
    ]
  end

  defp size_class("large") do
    [
      "[&.grouped-pagination_.pagination-button]:w-full [&.grouped-pagination_.pagination-button]:px-3",
      "[&:not(.grouped-pagination)_.pagination-button]:w-9",
      "[&.grouped-pagination_.pagination-button]:min-w-9 [&.grouped-pagination_.pagination-control]:min-w-9",
      "[&_.pagination-control]:px-2",
      "[&_.pagination-button]:h-9 [&_.pagination-control>.pagination-icon]:h-9",
      "[&_.pagination-separator]:w-full [&_.pagination-separator]:h-9 text-lg",
      "[&_:not(.pagination-separator)>.pagination-icon]:size-6"
    ]
  end

  defp size_class("extra_large") do
    [
      "[&.grouped-pagination_.pagination-button]:w-full [&.grouped-pagination_.pagination-button]:px-3",
      "[&:not(.grouped-pagination)_.pagination-button]:w-10",
      "[&.grouped-pagination_.pagination-button]:min-w-10 [&.grouped-pagination_.pagination-control]:min-w-10",
      "[&_.pagination-control]:px-2",
      "[&_.pagination-button]:h-10 [&_.pagination-control>.pagination-icon]:h-10",
      "[&_.pagination-separator]:w-full [&_.pagination-separator]:h-10 text-xl",
      "[&_:not(.pagination-separator)>.pagination-icon]:size-7"
    ]
  end

  defp size_class(params) when is_binary(params), do: params

  defp color_variant("base", _) do
    [
      "bg-white dark:bg-base-bg-dark [&_.pagination-button]:border-base-border-light [&_.pagination-button]:text-base-text-light",
      "dark:[&_.pagination-button]:border-base-border-dark dark:[&_.pagination-button]:text-base-text-dark",
      "[&_.pagination-button]:hover:bg-base-hover-light dark:[&_.pagination-button]:hover:bg-base-hover-dark",
      "[&_.pagination-button.active-pagination-button]:bg-base-hover-light dark:[&_.pagination-button.active-pagination-button]:bg-base-hover-dark"
    ]
  end

  defp color_variant("default", "white") do
    [
      "[&_.pagination-button]:bg-white [&_.pagination-button]:text-form-white-text",
      "[&_.pagination-button]:hover:bg-natural-hover-dark",
      "[&_.pagination-button.active-pagination-button]:bg-natural-hover-dark"
    ]
  end

  defp color_variant("default", "dark") do
    [
      "[&_.pagination-button]:bg-default-dark-bg [&_.pagination-button]:text-white",
      "[&_.pagination-button]:hover:bg-bordered-dark-border",
      "[&_.pagination-button.active-pagination-button]:bg-bordered-dark-border"
    ]
  end

  defp color_variant("default", "natural") do
    [
      "[&_.pagination-button]:bg-natural-light [&_.pagination-button]:text-white",
      "[&_.pagination-button]:hover:bg-natural-hover-light",
      "[&_.pagination-button.active-pagination-button]:bg-natural-hover-light",
      "dark:[&_.pagination-button]:bg-natural-dark dark:[&_.pagination-button]:text-black",
      "dark:[&_.pagination-button]:hover:bg-natural-hover-dark",
      "dark:[&_.pagination-button.active-pagination-button]:bg-natural-hover-dark"
    ]
  end

  defp color_variant("default", "primary") do
    [
      "[&_.pagination-button]:bg-primary-light [&_.pagination-button]:text-white",
      "[&_.pagination-button]:hover:bg-primary-hover-light",
      "[&_.pagination-button.active-pagination-button]:bg-primary-hover-light",
      "dark:[&_.pagination-button]:bg-primary-dark dark:[&_.pagination-button]:text-black",
      "dark:[&_.pagination-button]:hover:bg-primary-hover-dark",
      "dark:[&_.pagination-button.active-pagination-button]:bg-primary-hover-dark"
    ]
  end

  defp color_variant("default", "secondary") do
    [
      "[&_.pagination-button]:bg-secondary-light [&_.pagination-button]:text-white",
      "[&_.pagination-button]:hover:bg-secondary-hover-light",
      "[&_.pagination-button.active-pagination-button]:bg-secondary-hover-light",
      "dark:[&_.pagination-button]:bg-secondary-dark dark:[&_.pagination-button]:text-black",
      "dark:[&_.pagination-button]:hover:bg-secondary-hover-dark",
      "dark:[&_.pagination-button.active-pagination-button]:bg-secondary-hover-dark"
    ]
  end

  defp color_variant("default", "success") do
    [
      "[&_.pagination-button]:bg-success-light [&_.pagination-button]:text-white",
      "[&_.pagination-button]:hover:bg-success-hover-light",
      "[&_.pagination-button.active-pagination-button]:bg-success-hover-light",
      "dark:[&_.pagination-button]:bg-success-dark dark:[&_.pagination-button]:text-black",
      "dark:[&_.pagination-button]:hover:bg-success-hover-dark",
      "dark:[&_.pagination-button.active-pagination-button]:bg-success-hover-dark"
    ]
  end

  defp color_variant("default", "warning") do
    [
      "[&_.pagination-button]:bg-warning-light [&_.pagination-button]:text-white",
      "[&_.pagination-button]:hover:bg-warning-hover-light",
      "[&_.pagination-button.active-pagination-button]:bg-warning-hover-light",
      "dark:[&_.pagination-button]:bg-warning-dark dark:[&_.pagination-button]:text-black",
      "dark:[&_.pagination-button]:hover:bg-warning-hover-dark",
      "dark:[&_.pagination-button.active-pagination-button]:bg-warning-hover-dark"
    ]
  end

  defp color_variant("default", "danger") do
    [
      "[&_.pagination-button]:bg-danger-light [&_.pagination-button]:text-white",
      "[&_.pagination-button]:hover:bg-danger-hover-light",
      "[&_.pagination-button.active-pagination-button]:bg-danger-hover-light",
      "dark:[&_.pagination-button]:bg-danger-dark dark:[&_.pagination-button]:text-black",
      "dark:[&_.pagination-button]:hover:bg-danger-hover-dark",
      "dark:[&_.pagination-button.active-pagination-button]:bg-danger-hover-dark"
    ]
  end

  defp color_variant("default", "info") do
    [
      "[&_.pagination-button]:bg-info-light [&_.pagination-button]:text-white",
      "[&_.pagination-button]:hover:bg-info-hover-light",
      "[&_.pagination-button.active-pagination-button]:bg-info-hover-light",
      "dark:[&_.pagination-button]:bg-info-dark dark:[&_.pagination-button]:text-black",
      "dark:[&_.pagination-button]:hover:bg-info-hover-dark",
      "dark:[&_.pagination-button.active-pagination-button]:bg-info-hover-dark"
    ]
  end

  defp color_variant("default", "misc") do
    [
      "[&_.pagination-button]:bg-misc-light [&_.pagination-button]:text-white",
      "[&_.pagination-button]:hover:bg-misc-hover-light",
      "[&_.pagination-button.active-pagination-button]:bg-misc-hover-light",
      "dark:[&_.pagination-button]:bg-misc-dark dark:[&_.pagination-button]:text-black",
      "dark:[&_.pagination-button]:hover:bg-misc-hover-dark",
      "dark:[&_.pagination-button.active-pagination-button]:bg-misc-hover-dark"
    ]
  end

  defp color_variant("default", "dawn") do
    [
      "[&_.pagination-button]:bg-dawn-light [&_.pagination-button]:text-white",
      "[&_.pagination-button]:hover:bg-dawn-hover-light",
      "[&_.pagination-button.active-pagination-button]:bg-dawn-hover-light",
      "dark:[&_.pagination-button]:bg-dawn-dark dark:[&_.pagination-button]:text-black",
      "dark:[&_.pagination-button]:hover:bg-dawn-hover-dark",
      "dark:[&_.pagination-button.active-pagination-button]:bg-dawn-hover-dark"
    ]
  end

  defp color_variant("default", "silver") do
    [
      "[&_.pagination-button]:bg-silver-light [&_.pagination-button]:text-white",
      "[&_.pagination-button]:hover:bg-silver-hover-light",
      "[&_.pagination-button.active-pagination-button]:bg-silver-hover-light",
      "dark:[&_.pagination-button]:bg-silver-dark dark:[&_.pagination-button]:text-black",
      "dark:[&_.pagination-button]:hover:bg-silver-hover-dark",
      "dark:[&_.pagination-button.active-pagination-button]:bg-silver-hover-dark"
    ]
  end

  defp color_variant("outline", "natural") do
    [
      "[&_.pagination-button]:border-natural-light [&_.pagination-button]:text-natural-light",
      "[&_.pagination-button]:hover:border-natural-hover-light [&_.pagination-button]:hover:text-natural-hover-light",
      "dark:[&_.pagination-button]:border-natural-dark dark:[&_.pagination-button]:text-natural-dark",
      "dark:[&_.pagination-button]:hover:border-natural-hover-dark dark:[&_.pagination-button]:hover:text-natural-hover-dark",
      "[&_.pagination-button.active-pagination-button]:border-natural-hover-light [&_.pagination-button.active-pagination-button]:text-natural-hover-light",
      "dark:[&_.pagination-button.active-pagination-button]:border-natural-hover-dark dark:[&_.pagination-button.active-pagination-button]:text-natural-hover-dark"
    ]
  end

  defp color_variant("outline", "primary") do
    [
      "[&_.pagination-button]:border-primary-light [&_.pagination-button]:text-primary-light",
      "[&_.pagination-button]:hover:border-primary-hover-light [&_.pagination-button]:hover:text-primary-hover-light",
      "[&_.pagination-button.active-pagination-button]:border-primary-hover-light [&_.pagination-button.active-pagination-button]:text-primary-hover-light",
      "dark:[&_.pagination-button]:border-primary-dark dark:[&_.pagination-button]:text-primary-dark",
      "dark:[&_.pagination-button]:hover:border-primary-hover-dark dark:[&_.pagination-button]:hover:text-primary-hover-dark",
      "dark:[&_.pagination-button.active-pagination-button]:border-primary-hover-dark dark:[&_.pagination-button.active-pagination-button]:text-primary-hover-dark"
    ]
  end

  defp color_variant("outline", "secondary") do
    [
      "[&_.pagination-button]:border-secondary-light [&_.pagination-button]:text-secondary-light",
      "[&_.pagination-button]:hover:border-secondary-hover-light [&_.pagination-button]:hover:text-secondary-hover-light",
      "[&_.pagination-button.active-pagination-button]:border-secondary-hover-light [&_.pagination-button.active-pagination-button]:text-secondary-hover-light",
      "dark:[&_.pagination-button]:border-secondary-dark dark:[&_.pagination-button]:text-secondary-dark",
      "dark:[&_.pagination-button]:hover:border-secondary-hover-dark dark:[&_.pagination-button]:hover:text-secondary-hover-dark",
      "dark:[&_.pagination-button.active-pagination-button]:border-secondary-hover-dark dark:[&_.pagination-button.active-pagination-button]:text-secondary-hover-dark"
    ]
  end

  defp color_variant("outline", "success") do
    [
      "[&_.pagination-button]:border-success-light [&_.pagination-button]:text-success-light",
      "[&_.pagination-button]:hover:border-success-hover-light [&_.pagination-button]:hover:text-success-hover-light",
      "[&_.pagination-button.active-pagination-button]:border-success-hover-light [&_.pagination-button.active-pagination-button]:text-success-hover-light",
      "dark:[&_.pagination-button]:border-success-dark dark:[&_.pagination-button]:text-success-dark",
      "dark:[&_.pagination-button]:hover:border-success-hover-dark dark:[&_.pagination-button]:hover:text-success-hover-dark",
      "dark:[&_.pagination-button.active-pagination-button]:border-success-hover-dark dark:[&_.pagination-button.active-pagination-button]:text-success-hover-dark"
    ]
  end

  defp color_variant("outline", "warning") do
    [
      "[&_.pagination-button]:border-warning-light [&_.pagination-button]:text-warning-light",
      "[&_.pagination-button]:hover:border-warning-hover-light [&_.pagination-button]:hover:text-warning-hover-light",
      "[&_.pagination-button.active-pagination-button]:border-warning-hover-light [&_.pagination-button.active-pagination-button]:text-warning-hover-light",
      "dark:[&_.pagination-button]:border-warning-dark dark:[&_.pagination-button]:text-warning-dark",
      "dark:[&_.pagination-button]:hover:border-warning-hover-dark dark:[&_.pagination-button]:hover:text-warning-hover-dark",
      "dark:[&_.pagination-button.active-pagination-button]:border-warning-hover-dark dark:[&_.pagination-button.active-pagination-button]:text-warning-hover-dark"
    ]
  end

  defp color_variant("outline", "danger") do
    [
      "[&_.pagination-button]:border-danger-light [&_.pagination-button]:text-danger-light",
      "[&_.pagination-button]:hover:border-danger-hover-light [&_.pagination-button]:hover:text-danger-hover-light",
      "[&_.pagination-button.active-pagination-button]:border-danger-hover-light [&_.pagination-button.active-pagination-button]:text-danger-hover-light",
      "dark:[&_.pagination-button]:border-danger-dark dark:[&_.pagination-button]:text-danger-dark",
      "dark:[&_.pagination-button]:hover:border-danger-hover-dark dark:[&_.pagination-button]:hover:text-danger-hover-dark",
      "dark:[&_.pagination-button.active-pagination-button]:border-danger-hover-dark dark:[&_.pagination-button.active-pagination-button]:text-danger-hover-dark"
    ]
  end

  defp color_variant("outline", "info") do
    [
      "[&_.pagination-button]:border-info-light [&_.pagination-button]:text-info-light",
      "[&_.pagination-button]:hover:border-info-hover-light [&_.pagination-button]:hover:text-info-hover-light",
      "[&_.pagination-button.active-pagination-button]:border-info-hover-light [&_.pagination-button.active-pagination-button]:text-info-hover-light",
      "dark:[&_.pagination-button]:border-info-dark dark:[&_.pagination-button]:text-info-dark",
      "dark:[&_.pagination-button]:hover:border-info-hover-dark dark:[&_.pagination-button]:hover:text-info-hover-dark",
      "dark:[&_.pagination-button.active-pagination-button]:border-info-hover-dark dark:[&_.pagination-button.active-pagination-button]:text-info-hover-dark"
    ]
  end

  defp color_variant("outline", "misc") do
    [
      "[&_.pagination-button]:border-misc-light [&_.pagination-button]:text-misc-light",
      "[&_.pagination-button]:hover:border-misc-hover-light [&_.pagination-button]:hover:text-misc-hover-light",
      "[&_.pagination-button.active-pagination-button]:border-misc-hover-light [&_.pagination-button.active-pagination-button]:text-misc-hover-light",
      "dark:[&_.pagination-button]:border-misc-dark dark:[&_.pagination-button]:text-misc-dark",
      "dark:[&_.pagination-button]:hover:border-misc-hover-dark dark:[&_.pagination-button]:hover:text-misc-hover-dark",
      "dark:[&_.pagination-button.active-pagination-button]:border-misc-hover-dark dark:[&_.pagination-button.active-pagination-button]:text-misc-hover-dark"
    ]
  end

  defp color_variant("outline", "dawn") do
    [
      "[&_.pagination-button]:border-dawn-light [&_.pagination-button]:text-dawn-light",
      "[&_.pagination-button]:hover:border-dawn-hover-light [&_.pagination-button]:hover:text-dawn-hover-light",
      "[&_.pagination-button.active-pagination-button]:border-dawn-hover-light [&_.pagination-button.active-pagination-button]:text-dawn-hover-light",
      "dark:[&_.pagination-button]:border-dawn-dark dark:[&_.pagination-button]:text-dawn-dark",
      "dark:[&_.pagination-button]:hover:border-dawn-hover-dark dark:[&_.pagination-button]:hover:text-dawn-hover-dark",
      "dark:[&_.pagination-button.active-pagination-button]:border-dawn-hover-dark dark:[&_.pagination-button.active-pagination-button]:text-dawn-hover-dark"
    ]
  end

  defp color_variant("outline", "silver") do
    [
      "[&_.pagination-button]:border-silver-light [&_.pagination-button]:text-silver-light",
      "[&_.pagination-button]:hover:border-silver-hover-light [&_.pagination-button]:hover:text-silver-hover-light",
      "[&_.pagination-button.active-pagination-button]:border-silver-hover-light [&_.pagination-button.active-pagination-button]:text-silver-hover-light",
      "dark:[&_.pagination-button]:border-silver-dark dark:[&_.pagination-button]:text-silver-dark",
      "dark:[&_.pagination-button]:hover:border-silver-hover-dark dark:[&_.pagination-button]:hover:text-silver-hover-dark",
      "dark:[&_.pagination-button.active-pagination-button]:border-silver-hover-dark dark:[&_.pagination-button.active-pagination-button]:text-silver-hover-dark"
    ]
  end

  defp color_variant("bordered", "natural") do
    [
      "bg-white dark:bg-default-dark-bg [&_.pagination-button]:border-natural-light [&_.pagination-button]:text-natural-light",
      "[&_.pagination-button]:hover:border-natural-hover-light [&_.pagination-button]:hover:text-natural-hover-light",
      "dark:[&_.pagination-button]:border-natural-dark dark:[&_.pagination-button]:text-natural-dark",
      "dark:[&_.pagination-button]:hover:border-natural-hover-dark dark:[&_.pagination-button]:hover:text-natural-hover-dark",
      "[&_.pagination-button.active-pagination-button]:border-natural-hover-light [&_.pagination-button.active-pagination-button]:text-natural-hover-light",
      "dark:[&_.pagination-button.active-pagination-button]:border-natural-hover-dark dark:[&_.pagination-button.active-pagination-button]:text-natural-hover-dark"
    ]
  end

  defp color_variant("bordered", "primary") do
    [
      "bg-white dark:bg-default-dark-bg [&_.pagination-button]:border-primary-light [&_.pagination-button]:text-primary-light",
      "[&_.pagination-button]:hover:border-primary-hover-light [&_.pagination-button]:hover:text-primary-hover-light",
      "[&_.pagination-button.active-pagination-button]:border-primary-hover-light [&_.pagination-button.active-pagination-button]:text-primary-hover-light",
      "dark:[&_.pagination-button]:border-primary-dark dark:[&_.pagination-button]:text-primary-dark",
      "dark:[&_.pagination-button]:hover:border-primary-hover-dark dark:[&_.pagination-button]:hover:text-primary-hover-dark",
      "dark:[&_.pagination-button.active-pagination-button]:border-primary-hover-dark dark:[&_.pagination-button.active-pagination-button]:text-primary-hover-dark"
    ]
  end

  defp color_variant("bordered", "secondary") do
    [
      "bg-white dark:bg-default-dark-bg [&_.pagination-button]:border-secondary-light [&_.pagination-button]:text-secondary-light",
      "[&_.pagination-button]:hover:border-secondary-hover-light [&_.pagination-button]:hover:text-secondary-hover-light",
      "[&_.pagination-button.active-pagination-button]:border-secondary-hover-light [&_.pagination-button.active-pagination-button]:text-secondary-hover-light",
      "dark:[&_.pagination-button]:border-secondary-dark dark:[&_.pagination-button]:text-secondary-dark",
      "dark:[&_.pagination-button]:hover:border-secondary-hover-dark dark:[&_.pagination-button]:hover:text-secondary-hover-dark",
      "dark:[&_.pagination-button.active-pagination-button]:border-secondary-hover-dark dark:[&_.pagination-button.active-pagination-button]:text-secondary-hover-dark"
    ]
  end

  defp color_variant("bordered", "success") do
    [
      "bg-white dark:bg-default-dark-bg [&_.pagination-button]:border-success-light [&_.pagination-button]:text-success-light",
      "[&_.pagination-button]:hover:border-success-hover-light [&_.pagination-button]:hover:text-success-hover-light",
      "[&_.pagination-button.active-pagination-button]:border-success-hover-light [&_.pagination-button.active-pagination-button]:text-success-hover-light",
      "dark:[&_.pagination-button]:border-success-dark dark:[&_.pagination-button]:text-success-dark",
      "dark:[&_.pagination-button]:hover:border-success-hover-dark dark:[&_.pagination-button]:hover:text-success-hover-dark",
      "dark:[&_.pagination-button.active-pagination-button]:border-success-hover-dark dark:[&_.pagination-button.active-pagination-button]:text-success-hover-dark"
    ]
  end

  defp color_variant("bordered", "warning") do
    [
      "bg-white dark:bg-default-dark-bg [&_.pagination-button]:border-warning-light [&_.pagination-button]:text-warning-light",
      "[&_.pagination-button]:hover:border-warning-hover-light [&_.pagination-button]:hover:text-warning-hover-light",
      "[&_.pagination-button.active-pagination-button]:border-warning-hover-light [&_.pagination-button.active-pagination-button]:text-warning-hover-light",
      "dark:[&_.pagination-button]:border-warning-dark dark:[&_.pagination-button]:text-warning-dark",
      "dark:[&_.pagination-button]:hover:border-warning-hover-dark dark:[&_.pagination-button]:hover:text-warning-hover-dark",
      "dark:[&_.pagination-button.active-pagination-button]:border-warning-hover-dark dark:[&_.pagination-button.active-pagination-button]:text-warning-hover-dark"
    ]
  end

  defp color_variant("bordered", "danger") do
    [
      "bg-white dark:bg-default-dark-bg [&_.pagination-button]:border-danger-light [&_.pagination-button]:text-danger-light",
      "[&_.pagination-button]:hover:border-danger-hover-light [&_.pagination-button]:hover:text-danger-hover-light",
      "[&_.pagination-button.active-pagination-button]:border-danger-hover-light [&_.pagination-button.active-pagination-button]:text-danger-hover-light",
      "dark:[&_.pagination-button]:border-danger-dark dark:[&_.pagination-button]:text-danger-dark",
      "dark:[&_.pagination-button]:hover:border-danger-hover-dark dark:[&_.pagination-button]:hover:text-danger-hover-dark",
      "dark:[&_.pagination-button.active-pagination-button]:border-danger-hover-dark dark:[&_.pagination-button.active-pagination-button]:text-danger-hover-dark"
    ]
  end

  defp color_variant("bordered", "info") do
    [
      "bg-white dark:bg-default-dark-bg [&_.pagination-button]:border-info-light [&_.pagination-button]:text-info-light",
      "[&_.pagination-button]:hover:border-info-hover-light [&_.pagination-button]:hover:text-info-hover-light",
      "[&_.pagination-button.active-pagination-button]:border-info-hover-light [&_.pagination-button.active-pagination-button]:text-info-hover-light",
      "dark:[&_.pagination-button]:border-info-dark dark:[&_.pagination-button]:text-info-dark",
      "dark:[&_.pagination-button]:hover:border-info-hover-dark dark:[&_.pagination-button]:hover:text-info-hover-dark",
      "dark:[&_.pagination-button.active-pagination-button]:border-info-hover-dark dark:[&_.pagination-button.active-pagination-button]:text-info-hover-dark"
    ]
  end

  defp color_variant("bordered", "misc") do
    [
      "bg-white dark:bg-default-dark-bg [&_.pagination-button]:border-misc-light [&_.pagination-button]:text-misc-light",
      "[&_.pagination-button]:hover:border-misc-hover-light [&_.pagination-button]:hover:text-misc-hover-light",
      "[&_.pagination-button.active-pagination-button]:border-misc-hover-light [&_.pagination-button.active-pagination-button]:text-misc-hover-light",
      "dark:[&_.pagination-button]:border-misc-dark dark:[&_.pagination-button]:text-misc-dark",
      "dark:[&_.pagination-button]:hover:border-misc-hover-dark dark:[&_.pagination-button]:hover:text-misc-hover-dark",
      "dark:[&_.pagination-button.active-pagination-button]:border-misc-hover-dark dark:[&_.pagination-button.active-pagination-button]:text-misc-hover-dark"
    ]
  end

  defp color_variant("bordered", "dawn") do
    [
      "bg-white dark:bg-default-dark-bg [&_.pagination-button]:border-dawn-light [&_.pagination-button]:text-dawn-light",
      "[&_.pagination-button]:hover:border-dawn-hover-light [&_.pagination-button]:hover:text-dawn-hover-light",
      "[&_.pagination-button.active-pagination-button]:border-dawn-hover-light [&_.pagination-button.active-pagination-button]:text-dawn-hover-light",
      "dark:[&_.pagination-button]:border-dawn-dark dark:[&_.pagination-button]:text-dawn-dark",
      "dark:[&_.pagination-button]:hover:border-dawn-hover-dark dark:[&_.pagination-button]:hover:text-dawn-hover-dark",
      "dark:[&_.pagination-button.active-pagination-button]:border-dawn-hover-dark dark:[&_.pagination-button.active-pagination-button]:text-dawn-hover-dark"
    ]
  end

  defp color_variant("bordered", "silver") do
    [
      "bg-white dark:bg-default-dark-bg [&_.pagination-button]:border-silver-light [&_.pagination-button]:text-silver-light",
      "[&_.pagination-button]:hover:border-silver-hover-light [&_.pagination-button]:hover:text-silver-hover-light",
      "[&_.pagination-button.active-pagination-button]:border-silver-hover-light [&_.pagination-button.active-pagination-button]:text-silver-hover-light",
      "dark:[&_.pagination-button]:border-silver-dark dark:[&_.pagination-button]:text-silver-dark",
      "dark:[&_.pagination-button]:hover:border-silver-hover-dark dark:[&_.pagination-button]:hover:text-silver-hover-dark",
      "dark:[&_.pagination-button.active-pagination-button]:border-silver-hover-dark dark:[&_.pagination-button.active-pagination-button]:text-silver-hover-dark"
    ]
  end

  defp color_variant("transparent", "natural") do
    [
      "[&_.pagination-button]:text-natural-light [&_.pagination-button]:hover:text-natural-hover-light",
      "dark:[&_.pagination-button]:text-natural-dark dark:[&_.pagination-button]:hover:text-natural-hover-dark",
      "[&_.pagination-button.active-pagination-button]:text-natural-hover-light",
      "dark:[&_.pagination-button.active-pagination-button]:text-natural-hover-dark"
    ]
  end

  defp color_variant("transparent", "primary") do
    [
      "[&_.pagination-button]:text-primary-light [&_.pagination-button]:hover:text-primary-hover-light",
      "dark:[&_.pagination-button]:text-primary-dark dark:[&_.pagination-button]:hover:text-primary-hover-dark",
      "[&_.pagination-button.active-pagination-button]:text-primary-hover-light",
      "dark:[&_.pagination-button.active-pagination-button]:text-primary-hover-dark"
    ]
  end

  defp color_variant("transparent", "secondary") do
    [
      "[&_.pagination-button]:text-secondary-light [&_.pagination-button]:hover:text-secondary-hover-light",
      "dark:[&_.pagination-button]:text-secondary-dark dark:[&_.pagination-button]:hover:text-secondary-hover-dark",
      "[&_.pagination-button.active-pagination-button]:text-secondary-hover-light",
      "dark:[&_.pagination-button.active-pagination-button]:text-secondary-hover-dark"
    ]
  end

  defp color_variant("transparent", "success") do
    [
      "[&_.pagination-button]:text-success-light [&_.pagination-button]:hover:text-success-hover-light",
      "dark:[&_.pagination-button]:text-success-dark dark:[&_.pagination-button]:hover:text-success-hover-dark",
      "[&_.pagination-button.active-pagination-button]:text-success-hover-light",
      "dark:[&_.pagination-button.active-pagination-button]:text-success-hover-dark"
    ]
  end

  defp color_variant("transparent", "warning") do
    [
      "[&_.pagination-button]:text-warning-light [&_.pagination-button]:hover:text-warning-hover-light",
      "dark:[&_.pagination-button]:text-warning-dark dark:[&_.pagination-button]:hover:text-warning-hover-dark",
      "[&_.pagination-button.active-pagination-button]:text-warning-hover-light",
      "dark:[&_.pagination-button.active-pagination-button]:text-warning-hover-dark"
    ]
  end

  defp color_variant("transparent", "danger") do
    [
      "[&_.pagination-button]:text-danger-light [&_.pagination-button]:hover:text-danger-hover-light",
      "dark:[&_.pagination-button]:text-danger-dark dark:[&_.pagination-button]:hover:text-danger-hover-dark",
      "[&_.pagination-button.active-pagination-button]:text-danger-hover-light",
      "dark:[&_.pagination-button.active-pagination-button]:text-danger-hover-dark"
    ]
  end

  defp color_variant("transparent", "info") do
    [
      "[&_.pagination-button]:text-info-light [&_.pagination-button]:hover:text-info-hover-light",
      "dark:[&_.pagination-button]:text-info-dark dark:[&_.pagination-button]:hover:text-info-hover-dark",
      "[&_.pagination-button.active-pagination-button]:text-info-hover-light",
      "dark:[&_.pagination-button.active-pagination-button]:text-info-hover-dark"
    ]
  end

  defp color_variant("transparent", "misc") do
    [
      "[&_.pagination-button]:text-misc-light [&_.pagination-button]:hover:text-misc-hover-light",
      "dark:[&_.pagination-button]:text-misc-dark dark:[&_.pagination-button]:hover:text-misc-hover-dark",
      "[&_.pagination-button.active-pagination-button]:text-misc-hover-light",
      "dark:[&_.pagination-button.active-pagination-button]:text-misc-hover-dark"
    ]
  end

  defp color_variant("transparent", "dawn") do
    [
      "[&_.pagination-button]:text-dawn-light [&_.pagination-button]:hover:text-dawn-hover-light",
      "dark:[&_.pagination-button]:text-dawn-dark dark:[&_.pagination-button]:hover:text-dawn-hover-dark",
      "[&_.pagination-button.active-pagination-button]:text-dawn-hover-light",
      "dark:[&_.pagination-button.active-pagination-button]:text-dawn-hover-dark"
    ]
  end

  defp color_variant("transparent", "silver") do
    [
      "[&_.pagination-button]:text-silver-light [&_.pagination-button]:hover:text-silver-hover-light",
      "dark:[&_.pagination-button]:text-silver-dark dark:[&_.pagination-button]:hover:text-silver-hover-dark",
      "[&_.pagination-button.active-pagination-button]:text-silver-hover-light",
      "dark:[&_.pagination-button.active-pagination-button]:text-silver-hover-dark"
    ]
  end

  defp color_variant("subtle", "natural") do
    [
      "[&_.pagination-button]:text-natural-light [&_.pagination-button]:hover:text-natural-hover-light",
      "dark:[&_.pagination-button]:text-natural-dark dark:[&_.pagination-button]:hover:text-natural-hover-dark",
      "[&_.pagination-button.active-pagination-button]:text-natural-hover-light",
      "dark:[&_.pagination-button.active-pagination-button]:text-natural-hover-dark",
      "[&_.pagination-button]:hover:bg-natural-bg-light dark:[&_.pagination-button]:hover:bg-natural-bg-dark",
      "[&_.pagination-button.active-pagination-button]:bg-natural-bg-light",
      "dark:[&_.pagination-button.active-pagination-button]:bg-natural-bg-dark"
    ]
  end

  defp color_variant("subtle", "primary") do
    [
      "[&_.pagination-button]:text-primary-light [&_.pagination-button]:hover:text-primary-hover-light",
      "dark:[&_.pagination-button]:text-primary-dark dark:[&_.pagination-button]:hover:text-primary-hover-dark",
      "[&_.pagination-button.active-pagination-button]:text-primary-hover-light",
      "dark:[&_.pagination-button.active-pagination-button]:text-primary-hover-dark",
      "[&_.pagination-button]:hover:bg-primary-bordered-bg-light dark:[&_.pagination-button]:hover:bg-primary-bordered-bg-dark",
      "[&_.pagination-button.active-pagination-button]:bg-primary-bordered-bg-light",
      "dark:[&_.pagination-button.active-pagination-button]:bg-primary-bordered-bg-dark"
    ]
  end

  defp color_variant("subtle", "secondary") do
    [
      "[&_.pagination-button]:text-secondary-light [&_.pagination-button]:hover:text-secondary-hover-light",
      "dark:[&_.pagination-button]:text-secondary-dark dark:[&_.pagination-button]:hover:text-secondary-hover-dark",
      "[&_.pagination-button.active-pagination-button]:text-secondary-hover-light",
      "dark:[&_.pagination-button.active-pagination-button]:text-secondary-hover-dark",
      "[&_.pagination-button]:hover:bg-secondary-bordered-bg-light dark:[&_.pagination-button]:hover:bg-secondary-bordered-bg-dark",
      "[&_.pagination-button.active-pagination-button]:bg-secondary-bordered-bg-light",
      "dark:[&_.pagination-button.active-pagination-button]:bg-secondary-bordered-bg-dark"
    ]
  end

  defp color_variant("subtle", "success") do
    [
      "[&_.pagination-button]:text-success-light [&_.pagination-button]:hover:text-success-hover-light",
      "dark:[&_.pagination-button]:text-success-dark dark:[&_.pagination-button]:hover:text-success-hover-dark",
      "[&_.pagination-button.active-pagination-button]:text-success-hover-light",
      "dark:[&_.pagination-button.active-pagination-button]:text-success-hover-dark",
      "[&_.pagination-button]:hover:bg-success-bordered-bg-light dark:[&_.pagination-button]:hover:bg-success-bordered-bg-dark",
      "[&_.pagination-button.active-pagination-button]:bg-success-bordered-bg-light",
      "dark:[&_.pagination-button.active-pagination-button]:bg-success-bordered-bg-dark"
    ]
  end

  defp color_variant("subtle", "warning") do
    [
      "[&_.pagination-button]:text-warning-light [&_.pagination-button]:hover:text-warning-hover-light",
      "dark:[&_.pagination-button]:text-warning-dark dark:[&_.pagination-button]:hover:text-warning-hover-dark",
      "[&_.pagination-button.active-pagination-button]:text-warning-hover-light",
      "dark:[&_.pagination-button.active-pagination-button]:text-warning-hover-dark",
      "[&_.pagination-button]:hover:bg-warning-bordered-bg-light dark:[&_.pagination-button]:hover:bg-warning-bordered-bg-dark",
      "[&_.pagination-button.active-pagination-button]:bg-warning-bordered-bg-light",
      "dark:[&_.pagination-button.active-pagination-button]:bg-warning-bordered-bg-dark"
    ]
  end

  defp color_variant("subtle", "danger") do
    [
      "[&_.pagination-button]:text-danger-light [&_.pagination-button]:hover:text-danger-hover-light",
      "dark:[&_.pagination-button]:text-danger-dark dark:[&_.pagination-button]:hover:text-danger-hover-dark",
      "[&_.pagination-button.active-pagination-button]:text-danger-hover-light",
      "dark:[&_.pagination-button.active-pagination-button]:text-danger-hover-dark",
      "[&_.pagination-button]:hover:bg-danger-bordered-bg-light dark:[&_.pagination-button]:hover:bg-danger-bordered-bg-dark",
      "[&_.pagination-button.active-pagination-button]:bg-danger-bordered-bg-light",
      "dark:[&_.pagination-button.active-pagination-button]:bg-danger-bordered-bg-dark"
    ]
  end

  defp color_variant("subtle", "info") do
    [
      "[&_.pagination-button]:text-info-light [&_.pagination-button]:hover:text-info-hover-light",
      "dark:[&_.pagination-button]:text-info-dark dark:[&_.pagination-button]:hover:text-info-hover-dark",
      "[&_.pagination-button.active-pagination-button]:text-info-hover-light",
      "dark:[&_.pagination-button.active-pagination-button]:text-info-hover-dark",
      "[&_.pagination-button]:hover:bg-info-bordered-bg-light dark:[&_.pagination-button]:hover:bg-info-bordered-bg-dark",
      "[&_.pagination-button.active-pagination-button]:bg-info-bordered-bg-light",
      "dark:[&_.pagination-button.active-pagination-button]:bg-info-bordered-bg-dark"
    ]
  end

  defp color_variant("subtle", "misc") do
    [
      "[&_.pagination-button]:text-misc-light [&_.pagination-button]:hover:text-misc-hover-light",
      "dark:[&_.pagination-button]:text-misc-dark dark:[&_.pagination-button]:hover:text-misc-hover-dark",
      "[&_.pagination-button.active-pagination-button]:text-misc-hover-light",
      "dark:[&_.pagination-button.active-pagination-button]:text-misc-hover-dark",
      "[&_.pagination-button]:hover:bg-misc-bordered-bg-light dark:[&_.pagination-button]:hover:bg-misc-bordered-bg-dark",
      "[&_.pagination-button.active-pagination-button]:bg-misc-bordered-bg-light",
      "dark:[&_.pagination-button.active-pagination-button]:bg-misc-bordered-bg-dark"
    ]
  end

  defp color_variant("subtle", "dawn") do
    [
      "[&_.pagination-button]:text-dawn-light [&_.pagination-button]:hover:text-dawn-hover-light",
      "dark:[&_.pagination-button]:text-dawn-dark dark:[&_.pagination-button]:hover:text-dawn-hover-dark",
      "[&_.pagination-button.active-pagination-button]:text-dawn-hover-light",
      "dark:[&_.pagination-button.active-pagination-button]:text-dawn-hover-dark",
      "[&_.pagination-button]:hover:bg-dawn-bordered-bg-light dark:[&_.pagination-button]:hover:bg-dawn-bordered-bg-dark",
      "[&_.pagination-button.active-pagination-button]:bg-dawn-bordered-bg-light",
      "dark:[&_.pagination-button.active-pagination-button]:bg-dawn-bordered-bg-dark"
    ]
  end

  defp color_variant("subtle", "silver") do
    [
      "[&_.pagination-button]:text-silver-light [&_.pagination-button]:hover:text-silver-hover-light",
      "dark:[&_.pagination-button]:text-silver-dark dark:[&_.pagination-button]:hover:text-silver-hover-dark",
      "[&_.pagination-button.active-pagination-button]:text-silver-hover-light",
      "dark:[&_.pagination-button.active-pagination-button]:text-silver-hover-dark",
      "[&_.pagination-button]:hover:bg-silver-bordered-bg-light dark:[&_.pagination-button]:hover:bg-silver-bordered-bg-dark",
      "[&_.pagination-button.active-pagination-button]:bg-silver-bordered-bg-light",
      "dark:[&_.pagination-button.active-pagination-button]:bg-silver-bordered-bg-dark"
    ]
  end

  defp color_variant("shadow", "natural") do
    [
      "[&_.pagination-button]:bg-natural-light [&_.pagination-button]:text-white",
      "[&_.pagination-button]:hover:bg-natural-hover-light",
      "[&_.pagination-button.active-pagination-button]:bg-natural-hover-light",
      "dark:[&_.pagination-button]:bg-natural-dark dark:[&_.pagination-button]:text-black",
      "dark:[&_.pagination-button]:hover:bg-natural-hover-dark",
      "dark:[&_.pagination-button.active-pagination-button]:bg-natural-hover-dark",
      "[&_.pagination-button]:shadow-[0px_4px_6px_-4px_var(--color-shadow-natural)] [&_.pagination-button]:shadow-[0px_10px_15px_-3px_var(--color-shadow-natural)]",
      "dark:[&_.pagination-button]:shadow-none"
    ]
  end

  defp color_variant("shadow", "primary") do
    [
      "[&_.pagination-button]:bg-primary-light [&_.pagination-button]:text-white",
      "[&_.pagination-button]:hover:bg-primary-hover-light",
      "[&_.pagination-button.active-pagination-button]:bg-primary-hover-light",
      "dark:[&_.pagination-button]:bg-primary-dark dark:[&_.pagination-button]:text-black",
      "dark:[&_.pagination-button]:hover:bg-primary-hover-dark",
      "dark:[&_.pagination-button.active-pagination-button]:bg-primary-hover-dark",
      "[&_.pagination-button]:shadow-[0px_4px_6px_-4px_var(--color-shadow-primary)] [&_.pagination-button]:shadow-[0px_10px_15px_-3px_var(--color-shadow-primary)]",
      "dark:[&_.pagination-button]:shadow-none"
    ]
  end

  defp color_variant("shadow", "secondary") do
    [
      "[&_.pagination-button]:bg-secondary-light [&_.pagination-button]:text-white",
      "[&_.pagination-button]:hover:bg-secondary-hover-light",
      "[&_.pagination-button.active-pagination-button]:bg-secondary-hover-light",
      "dark:[&_.pagination-button]:bg-secondary-dark dark:[&_.pagination-button]:text-black",
      "dark:[&_.pagination-button]:hover:bg-secondary-hover-dark",
      "dark:[&_.pagination-button.active-pagination-button]:bg-secondary-hover-dark",
      "[&_.pagination-button]:shadow-[0px_4px_6px_-4px_var(--color-shadow-secondary)] [&_.pagination-button]:shadow-[0px_10px_15px_-3px_var(--color-shadow-secondary)]",
      "dark:[&_.pagination-button]:shadow-none"
    ]
  end

  defp color_variant("shadow", "success") do
    [
      "[&_.pagination-button]:bg-success-light [&_.pagination-button]:text-white",
      "[&_.pagination-button]:hover:bg-success-hover-light",
      "[&_.pagination-button.active-pagination-button]:bg-success-hover-light",
      "dark:[&_.pagination-button]:bg-success-dark dark:[&_.pagination-button]:text-black",
      "dark:[&_.pagination-button]:hover:bg-success-hover-dark",
      "dark:[&_.pagination-button.active-pagination-button]:bg-success-hover-dark",
      "[&_.pagination-button]:shadow-[0px_4px_6px_-4px_var(--color-shadow-success)] [&_.pagination-button]:shadow-[0px_10px_15px_-3px_var(--color-shadow-success)]",
      "dark:[&_.pagination-button]:shadow-none"
    ]
  end

  defp color_variant("shadow", "warning") do
    [
      "[&_.pagination-button]:bg-warning-light [&_.pagination-button]:text-white",
      "[&_.pagination-button]:hover:bg-warning-hover-light",
      "[&_.pagination-button.active-pagination-button]:bg-warning-hover-light",
      "dark:[&_.pagination-button]:bg-warning-dark dark:[&_.pagination-button]:text-black",
      "dark:[&_.pagination-button]:hover:bg-warning-hover-dark",
      "dark:[&_.pagination-button.active-pagination-button]:bg-warning-hover-dark",
      "[&_.pagination-button]:shadow-[0px_4px_6px_-4px_var(--color-shadow-warning)] [&_.pagination-button]:shadow-[0px_10px_15px_-3px_var(--color-shadow-warning)]",
      "dark:[&_.pagination-button]:shadow-none"
    ]
  end

  defp color_variant("shadow", "danger") do
    [
      "[&_.pagination-button]:bg-danger-light [&_.pagination-button]:text-white",
      "[&_.pagination-button]:hover:bg-danger-hover-light",
      "[&_.pagination-button.active-pagination-button]:bg-danger-hover-light",
      "dark:[&_.pagination-button]:bg-danger-dark dark:[&_.pagination-button]:text-black",
      "dark:[&_.pagination-button]:hover:bg-danger-hover-dark",
      "dark:[&_.pagination-button.active-pagination-button]:bg-danger-hover-dark",
      "[&_.pagination-button]:shadow-[0px_4px_6px_-4px_var(--color-shadow-danger)] [&_.pagination-button]:shadow-[0px_10px_15px_-3px_var(--color-shadow-danger)]",
      "dark:[&_.pagination-button]:shadow-none"
    ]
  end

  defp color_variant("shadow", "info") do
    [
      "[&_.pagination-button]:bg-info-light [&_.pagination-button]:text-white",
      "[&_.pagination-button]:hover:bg-info-hover-light",
      "[&_.pagination-button.active-pagination-button]:bg-info-hover-light",
      "dark:[&_.pagination-button]:bg-info-dark dark:[&_.pagination-button]:text-black",
      "dark:[&_.pagination-button]:hover:bg-info-hover-dark",
      "dark:[&_.pagination-button.active-pagination-button]:bg-info-hover-dark",
      "[&_.pagination-button]:shadow-[0px_4px_6px_-4px_var(--color-shadow-info)] [&_.pagination-button]:shadow-[0px_10px_15px_-3px_var(--color-shadow-info)]",
      "dark:[&_.pagination-button]:shadow-none"
    ]
  end

  defp color_variant("shadow", "misc") do
    [
      "[&_.pagination-button]:bg-misc-light [&_.pagination-button]:text-white",
      "[&_.pagination-button]:hover:bg-misc-hover-light",
      "[&_.pagination-button.active-pagination-button]:bg-misc-hover-light",
      "dark:[&_.pagination-button]:bg-misc-dark dark:[&_.pagination-button]:text-black",
      "dark:[&_.pagination-button]:hover:bg-misc-hover-dark",
      "dark:[&_.pagination-button.active-pagination-button]:bg-misc-hover-dark",
      "[&_.pagination-button]:shadow-[0px_4px_6px_-4px_var(--color-shadow-misc)] [&_.pagination-button]:shadow-[0px_10px_15px_-3px_var(--color-shadow-misc)]",
      "dark:[&_.pagination-button]:shadow-none"
    ]
  end

  defp color_variant("shadow", "dawn") do
    [
      "[&_.pagination-button]:bg-dawn-light [&_.pagination-button]:text-white",
      "[&_.pagination-button]:hover:bg-dawn-hover-light",
      "[&_.pagination-button.active-pagination-button]:bg-dawn-hover-light",
      "dark:[&_.pagination-button]:bg-dawn-dark dark:[&_.pagination-button]:text-black",
      "dark:[&_.pagination-button]:hover:bg-dawn-hover-dark",
      "dark:[&_.pagination-button.active-pagination-button]:bg-dawn-hover-dark",
      "[&_.pagination-button]:shadow-[0px_4px_6px_-4px_var(--color-shadow-dawn)] [&_.pagination-button]:shadow-[0px_10px_15px_-3px_var(--color-shadow-dawn)]",
      "dark:[&_.pagination-button]:shadow-none"
    ]
  end

  defp color_variant("shadow", "silver") do
    [
      "[&_.pagination-button]:bg-silver-light [&_.pagination-button]:text-white",
      "[&_.pagination-button]:hover:bg-silver-hover-light",
      "[&_.pagination-button.active-pagination-button]:bg-silver-hover-light",
      "dark:[&_.pagination-button]:bg-silver-dark dark:[&_.pagination-button]:text-black",
      "dark:[&_.pagination-button]:hover:bg-silver-hover-dark",
      "dark:[&_.pagination-button.active-pagination-button]:bg-silver-hover-dark",
      "[&_.pagination-button]:shadow-[0px_4px_6px_-4px_var(--color-shadow-silver)] [&_.pagination-button]:shadow-[0px_10px_15px_-3px_var(--color-shadow-silver)]",
      "dark:[&_.pagination-button]:shadow-none"
    ]
  end

  defp color_variant("inverted", "natural") do
    [
      "[&_.pagination-button]:border-natural-light [&_.pagination-button]:text-natural-light",
      "[&_.pagination-button]:hover:border-natural-hover-light [&_.pagination-button]:hover:text-natural-hover-light",
      "dark:[&_.pagination-button]:border-natural-dark dark:[&_.pagination-button]:text-natural-dark",
      "dark:[&_.pagination-button]:hover:border-natural-hover-dark dark:[&_.pagination-button]:hover:text-natural-hover-dark",
      "[&_.pagination-button.active-pagination-button]:border-natural-hover-light [&_.pagination-button.active-pagination-button]:text-natural-hover-light",
      "dark:[&_.pagination-button.active-pagination-button]:border-natural-hover-dark dark:[&_.pagination-button.active-pagination-button]:text-natural-hover-dark",
      "[&_.pagination-button]:hover:bg-natural-bg-light dark:[&_.pagination-button]:hover:bg-natural-bg-dark",
      "[&_.pagination-button.active-pagination-button]:bg-natural-bg-light dark:[&_.pagination-button.active-pagination-button]:bg-natural-bg-dark"
    ]
  end

  defp color_variant("inverted", "primary") do
    [
      "[&_.pagination-button]:border-primary-light [&_.pagination-button]:text-primary-light",
      "[&_.pagination-button]:hover:border-primary-hover-light [&_.pagination-button]:hover:text-primary-hover-light",
      "[&_.pagination-button.active-pagination-button]:border-primary-hover-light [&_.pagination-button.active-pagination-button]:text-primary-hover-light",
      "dark:[&_.pagination-button]:border-primary-dark dark:[&_.pagination-button]:text-primary-dark",
      "dark:[&_.pagination-button]:hover:border-primary-hover-dark dark:[&_.pagination-button]:hover:text-primary-hover-dark",
      "dark:[&_.pagination-button.active-pagination-button]:border-primary-hover-dark dark:[&_.pagination-button.active-pagination-button]:text-primary-hover-dark",
      "[&_.pagination-button]:hover:bg-primary-bordered-bg-light dark:[&_.pagination-button]:hover:bg-primary-bordered-bg-dark",
      "[&_.pagination-button.active-pagination-button]:bg-primary-bordered-bg-light dark:[&_.pagination-button.active-pagination-button]:bg-primary-bordered-bg-dark"
    ]
  end

  defp color_variant("inverted", "secondary") do
    [
      "[&_.pagination-button]:border-secondary-light [&_.pagination-button]:text-secondary-light",
      "[&_.pagination-button]:hover:border-secondary-hover-light [&_.pagination-button]:hover:text-secondary-hover-light",
      "[&_.pagination-button.active-pagination-button]:border-secondary-hover-light [&_.pagination-button.active-pagination-button]:text-secondary-hover-light",
      "dark:[&_.pagination-button]:border-secondary-dark dark:[&_.pagination-button]:text-secondary-dark",
      "dark:[&_.pagination-button]:hover:border-secondary-hover-dark dark:[&_.pagination-button]:hover:text-secondary-hover-dark",
      "dark:[&_.pagination-button.active-pagination-button]:border-secondary-hover-dark dark:[&_.pagination-button.active-pagination-button]:text-secondary-hover-dark",
      "[&_.pagination-button]:hover:bg-secondary-bordered-bg-light dark:[&_.pagination-button]:hover:bg-secondary-bordered-bg-dark",
      "[&_.pagination-button.active-pagination-button]:bg-secondary-bordered-bg-light dark:[&_.pagination-button.active-pagination-button]:bg-secondary-bordered-bg-dark"
    ]
  end

  defp color_variant("inverted", "success") do
    [
      "[&_.pagination-button]:border-success-light [&_.pagination-button]:text-success-light",
      "[&_.pagination-button]:hover:border-success-hover-light [&_.pagination-button]:hover:text-success-hover-light",
      "[&_.pagination-button.active-pagination-button]:border-success-hover-light [&_.pagination-button.active-pagination-button]:text-success-hover-light",
      "dark:[&_.pagination-button]:border-success-dark dark:[&_.pagination-button]:text-success-dark",
      "dark:[&_.pagination-button]:hover:border-success-hover-dark dark:[&_.pagination-button]:hover:text-success-hover-dark",
      "dark:[&_.pagination-button.active-pagination-button]:border-success-hover-dark dark:[&_.pagination-button.active-pagination-button]:text-success-hover-dark",
      "[&_.pagination-button]:hover:bg-success-bordered-bg-light dark:[&_.pagination-button]:hover:bg-success-bordered-bg-dark",
      "[&_.pagination-button.active-pagination-button]:bg-success-bordered-bg-light dark:[&_.pagination-button.active-pagination-button]:bg-success-bordered-bg-dark"
    ]
  end

  defp color_variant("inverted", "warning") do
    [
      "[&_.pagination-button]:border-warning-light [&_.pagination-button]:text-warning-light",
      "[&_.pagination-button]:hover:border-warning-hover-light [&_.pagination-button]:hover:text-warning-hover-light",
      "[&_.pagination-button.active-pagination-button]:border-warning-hover-light [&_.pagination-button.active-pagination-button]:text-warning-hover-light",
      "dark:[&_.pagination-button]:border-warning-dark dark:[&_.pagination-button]:text-warning-dark",
      "dark:[&_.pagination-button]:hover:border-warning-hover-dark dark:[&_.pagination-button]:hover:text-warning-hover-dark",
      "dark:[&_.pagination-button.active-pagination-button]:border-warning-hover-dark dark:[&_.pagination-button.active-pagination-button]:text-warning-hover-dark",
      "[&_.pagination-button]:hover:bg-warning-bordered-bg-light dark:[&_.pagination-button]:hover:bg-warning-bordered-bg-dark",
      "[&_.pagination-button.active-pagination-button]:bg-warning-bordered-bg-light dark:[&_.pagination-button.active-pagination-button]:bg-warning-bordered-bg-dark"
    ]
  end

  defp color_variant("inverted", "danger") do
    [
      "[&_.pagination-button]:border-danger-light [&_.pagination-button]:text-danger-light",
      "[&_.pagination-button]:hover:border-danger-hover-light [&_.pagination-button]:hover:text-danger-hover-light",
      "[&_.pagination-button.active-pagination-button]:border-danger-hover-light [&_.pagination-button.active-pagination-button]:text-danger-hover-light",
      "dark:[&_.pagination-button]:border-danger-dark dark:[&_.pagination-button]:text-danger-dark",
      "dark:[&_.pagination-button]:hover:border-danger-hover-dark dark:[&_.pagination-button]:hover:text-danger-hover-dark",
      "dark:[&_.pagination-button.active-pagination-button]:border-danger-hover-dark dark:[&_.pagination-button.active-pagination-button]:text-danger-hover-dark",
      "[&_.pagination-button]:hover:bg-danger-bordered-bg-light dark:[&_.pagination-button]:hover:bg-danger-bordered-bg-dark",
      "[&_.pagination-button.active-pagination-button]:bg-danger-bordered-bg-light dark:[&_.pagination-button.active-pagination-button]:bg-danger-bordered-bg-dark"
    ]
  end

  defp color_variant("inverted", "info") do
    [
      "[&_.pagination-button]:border-info-light [&_.pagination-button]:text-info-light",
      "[&_.pagination-button]:hover:border-info-hover-light [&_.pagination-button]:hover:text-info-hover-light",
      "[&_.pagination-button.active-pagination-button]:border-info-hover-light [&_.pagination-button.active-pagination-button]:text-info-hover-light",
      "dark:[&_.pagination-button]:border-info-dark dark:[&_.pagination-button]:text-info-dark",
      "dark:[&_.pagination-button]:hover:border-info-hover-dark dark:[&_.pagination-button]:hover:text-info-hover-dark",
      "dark:[&_.pagination-button.active-pagination-button]:border-info-hover-dark dark:[&_.pagination-button.active-pagination-button]:text-info-hover-dark",
      "[&_.pagination-button]:hover:bg-info-bordered-bg-light dark:[&_.pagination-button]:hover:bg-info-bordered-bg-dark",
      "[&_.pagination-button.active-pagination-button]:bg-info-bordered-bg-light dark:[&_.pagination-button.active-pagination-button]:bg-info-bordered-bg-dark"
    ]
  end

  defp color_variant("inverted", "misc") do
    [
      "[&_.pagination-button]:border-misc-light [&_.pagination-button]:text-misc-light",
      "[&_.pagination-button]:hover:border-misc-hover-light [&_.pagination-button]:hover:text-misc-hover-light",
      "[&_.pagination-button.active-pagination-button]:border-misc-hover-light [&_.pagination-button.active-pagination-button]:text-misc-hover-light",
      "dark:[&_.pagination-button]:border-misc-dark dark:[&_.pagination-button]:text-misc-dark",
      "dark:[&_.pagination-button]:hover:border-misc-hover-dark dark:[&_.pagination-button]:hover:text-misc-hover-dark",
      "dark:[&_.pagination-button.active-pagination-button]:border-misc-hover-dark dark:[&_.pagination-button.active-pagination-button]:text-misc-hover-dark",
      "[&_.pagination-button]:hover:bg-misc-bordered-bg-light dark:[&_.pagination-button]:hover:bg-misc-bordered-bg-dark",
      "[&_.pagination-button.active-pagination-button]:bg-misc-bordered-bg-light dark:[&_.pagination-button.active-pagination-button]:bg-misc-bordered-bg-dark"
    ]
  end

  defp color_variant("inverted", "dawn") do
    [
      "[&_.pagination-button]:border-dawn-light [&_.pagination-button]:text-dawn-light",
      "[&_.pagination-button]:hover:border-dawn-hover-light [&_.pagination-button]:hover:text-dawn-hover-light",
      "[&_.pagination-button.active-pagination-button]:border-dawn-hover-light [&_.pagination-button.active-pagination-button]:text-dawn-hover-light",
      "dark:[&_.pagination-button]:border-dawn-dark dark:[&_.pagination-button]:text-dawn-dark",
      "dark:[&_.pagination-button]:hover:border-dawn-hover-dark dark:[&_.pagination-button]:hover:text-dawn-hover-dark",
      "dark:[&_.pagination-button.active-pagination-button]:border-dawn-hover-dark dark:[&_.pagination-button.active-pagination-button]:text-dawn-hover-dark",
      "[&_.pagination-button]:hover:bg-dawn-bordered-bg-light dark:[&_.pagination-button]:hover:bg-dawn-bordered-bg-dark",
      "[&_.pagination-button.active-pagination-button]:bg-dawn-bordered-bg-light dark:[&_.pagination-button.active-pagination-button]:bg-dawn-bordered-bg-dark"
    ]
  end

  defp color_variant("inverted", "silver") do
    [
      "[&_.pagination-button]:border-silver-light [&_.pagination-button]:text-silver-light",
      "[&_.pagination-button]:hover:border-silver-hover-light [&_.pagination-button]:hover:text-silver-hover-light",
      "[&_.pagination-button.active-pagination-button]:border-silver-hover-light [&_.pagination-button.active-pagination-button]:text-silver-hover-light",
      "dark:[&_.pagination-button]:border-silver-dark dark:[&_.pagination-button]:text-silver-dark",
      "dark:[&_.pagination-button]:hover:border-silver-hover-dark dark:[&_.pagination-button]:hover:text-silver-hover-dark",
      "dark:[&_.pagination-button.active-pagination-button]:border-silver-hover-dark dark:[&_.pagination-button.active-pagination-button]:text-silver-hover-dark",
      "[&_.pagination-button]:hover:bg-silver-bordered-bg-light dark:[&_.pagination-button]:hover:bg-silver-bordered-bg-dark",
      "[&_.pagination-button.active-pagination-button]:bg-silver-bordered-bg-light dark:[&_.pagination-button.active-pagination-button]:bg-silver-bordered-bg-dark"
    ]
  end

  defp color_variant("gradient", "natural") do
    [
      "[&_.pagination-button]:bg-gradient-to-br [&_.pagination-button]:hover:bg-gradient-to-bl",
      "[&_.pagination-button]:from-[var(--gradient-natural-from-light)] [&_.pagination-button]:to-[var(--gradient-natural-to-light)] [&_.pagination-button]:text-white",
      "dark:[&_.pagination-button]:from-[var(--gradient-natural-from-dark)] dark:[&_.pagination-button]:to-white dark:[&_.pagination-button]:text-black",
      "[&_.pagination-button.active-pagination-button]:bg-gradient-to-bl"
    ]
  end

  defp color_variant("gradient", "primary") do
    [
      "[&_.pagination-button]:bg-gradient-to-br [&_.pagination-button]:hover:bg-gradient-to-bl",
      "[&_.pagination-button]:from-[var(--gradient-primary-from-light)] [&_.pagination-button]:to-[var(--gradient-primary-to-light)] [&_.pagination-button]:text-white",
      "dark:[&_.pagination-button]:from-[var(--gradient-primary-from-dark)] dark:[&_.pagination-button]:to-[var(--gradient-primary-to-dark)] dark:[&_.pagination-button]:text-white",
      "[&_.pagination-button.active-pagination-button]:bg-gradient-to-bl"
    ]
  end

  defp color_variant("gradient", "secondary") do
    [
      "[&_.pagination-button]:bg-gradient-to-br [&_.pagination-button]:hover:bg-gradient-to-bl",
      "[&_.pagination-button]:from-[var(--gradient-secondary-from-light)] [&_.pagination-button]:to-[var(--gradient-secondary-to-light)] [&_.pagination-button]:text-white",
      "dark:[&_.pagination-button]:from-[var(--gradient-secondary-from-dark)] dark:[&_.pagination-button]:to-[var(--gradient-secondary-to-dark)] dark:[&_.pagination-button]:text-white",
      "[&_.pagination-button.active-pagination-button]:bg-gradient-to-bl"
    ]
  end

  defp color_variant("gradient", "success") do
    [
      "[&_.pagination-button]:bg-gradient-to-br [&_.pagination-button]:hover:bg-gradient-to-bl",
      "[&_.pagination-button]:from-[var(--gradient-success-from-light)] [&_.pagination-button]:to-[var(--gradient-success-to-light)] [&_.pagination-button]:text-white",
      "dark:[&_.pagination-button]:from-[var(--gradient-success-from-dark)] dark:[&_.pagination-button]:to-[var(--gradient-success-to-dark)] dark:[&_.pagination-button]:text-white",
      "[&_.pagination-button.active-pagination-button]:bg-gradient-to-bl"
    ]
  end

  defp color_variant("gradient", "warning") do
    [
      "[&_.pagination-button]:bg-gradient-to-br [&_.pagination-button]:hover:bg-gradient-to-bl",
      "[&_.pagination-button]:from-[var(--gradient-warning-from-light)] [&_.pagination-button]:to-[var(--gradient-warning-to-light)] [&_.pagination-button]:text-black",
      "dark:[&_.pagination-button]:from-[var(--gradient-warning-from-dark)] dark:[&_.pagination-button]:to-[var(--gradient-warning-to-dark)] dark:[&_.pagination-button]:text-black",
      "[&_.pagination-button.active-pagination-button]:bg-gradient-to-bl"
    ]
  end

  defp color_variant("gradient", "danger") do
    [
      "[&_.pagination-button]:bg-gradient-to-br [&_.pagination-button]:hover:bg-gradient-to-bl",
      "[&_.pagination-button]:from-[var(--gradient-danger-from-light)] [&_.pagination-button]:to-[var(--gradient-danger-to-light)] [&_.pagination-button]:text-white",
      "dark:[&_.pagination-button]:from-[var(--gradient-danger-from-dark)] dark:[&_.pagination-button]:to-[var(--gradient-danger-to-dark)] dark:[&_.pagination-button]:text-white",
      "[&_.pagination-button.active-pagination-button]:bg-gradient-to-bl"
    ]
  end

  defp color_variant("gradient", "info") do
    [
      "[&_.pagination-button]:bg-gradient-to-br [&_.pagination-button]:hover:bg-gradient-to-bl",
      "[&_.pagination-button]:from-[var(--gradient-info-from-light)] [&_.pagination-button]:to-[var(--gradient-info-to-light)] [&_.pagination-button]:text-white",
      "dark:[&_.pagination-button]:from-[var(--gradient-info-from-dark)] dark:[&_.pagination-button]:to-[var(--gradient-info-to-dark)] dark:[&_.pagination-button]:text-white",
      "[&_.pagination-button.active-pagination-button]:bg-gradient-to-bl"
    ]
  end

  defp color_variant("gradient", "misc") do
    [
      "[&_.pagination-button]:bg-gradient-to-br [&_.pagination-button]:hover:bg-gradient-to-bl",
      "[&_.pagination-button]:from-[var(--gradient-misc-from-light)] [&_.pagination-button]:to-[var(--gradient-misc-to-light)] [&_.pagination-button]:text-white",
      "dark:[&_.pagination-button]:from-[var(--gradient-misc-from-dark)] dark:[&_.pagination-button]:to-[var(--gradient-misc-to-dark)] dark:[&_.pagination-button]:text-white",
      "[&_.pagination-button.active-pagination-button]:bg-gradient-to-bl"
    ]
  end

  defp color_variant("gradient", "dawn") do
    [
      "[&_.pagination-button]:bg-gradient-to-br [&_.pagination-button]:hover:bg-gradient-to-bl",
      "[&_.pagination-button]:from-[var(--gradient-dawn-from-light)] [&_.pagination-button]:to-[var(--gradient-dawn-to-light)] [&_.pagination-button]:text-white",
      "dark:[&_.pagination-button]:from-[var(--gradient-dawn-from-dark)] dark:[&_.pagination-button]:to-[var(--gradient-dawn-to-dark)] dark:[&_.pagination-button]:text-white",
      "[&_.pagination-button.active-pagination-button]:bg-gradient-to-bl"
    ]
  end

  defp color_variant("gradient", "silver") do
    [
      "[&_.pagination-button]:bg-gradient-to-br [&_.pagination-button]:hover:bg-gradient-to-bl",
      "[&_.pagination-button]:from-[var(--gradient-silver-from-light)] [&_.pagination-button]:to-[var(--gradient-silver-to-light)] [&_.pagination-button]:text-white",
      "dark:[&_.pagination-button]:from-[var(--gradient-silver-from-dark)] dark:[&_.pagination-button]:to-[var(--gradient-silver-to-dark)] dark:[&_.pagination-button]:text-white",
      "[&_.pagination-button.active-pagination-button]:bg-gradient-to-bl"
    ]
  end

  defp color_variant(params, _) when is_binary(params), do: params

  defp default_classes() do
    [
      "w-fit flex [&.grouped-pagination>*]::flex-1 [&:not(.grouped-pagination)]:justify-start [&:not(.grouped-pagination)]:items-center [&:not(.grouped-pagination)]:flex-wrap  [&_.pagination-button.active-pagination-button]:font-medium [&.grouped-pagination]:overflow-hidden"
    ]
  end

  defp show_pagination?(nil, _total), do: true
  defp show_pagination?(true, total) when total <= 1, do: false
  defp show_pagination?(_, total) when total > 1, do: true
  defp show_pagination?(_, _), do: false
end
