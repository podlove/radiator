defmodule RadiatorWeb.Components.Layout do
  @moduledoc """
  The `RadiatorWeb.Components.Layout` module provides powerful and customizable layout components
  for building responsive user interfaces using Tailwind CSS utilities.

  It includes two core components: `flex` and `grid`, which abstract common layout patterns in a
  declarative and consistent way. These components are ideal for building dynamic and responsive
  layouts across all screen sizes.

  ### Key Features:

  - **Flex and Grid Layout Support:** Easily implement Tailwind’s Flexbox and Grid utilities
    with a simple interface using Phoenix LiveView components.
  - **Fully Configurable Props:** Customize direction, alignment, spacing, order, wrapping,
    and sizing via intuitive props.
  - **Dark Mode Ready:** Compatible with Tailwind's dark mode utilities out of the box.
  - **Slot-Based Composition:** Supports inner content slots for nesting arbitrary elements.
  - **Clean Code Integration:** Simplifies your markup while keeping full control of layout logic.

  The `Layout` component is designed to give developers complete flexibility with minimal boilerplate.

  **Documentation:** https://mishka.tools/chelekom/docs/layout
  """

  use Phoenix.Component

  @doc """
  Renders a `flex` container component that wraps Tailwind’s Flexbox utilities
  with a clean and consistent interface.

  You can control direction, alignment, spacing, and other flex-related behaviors
  through simple props.

  ## Examples

  ```elixir
  <.flex direction="col" gap="medium">
    <div>Item 1</div>
    <div>Item 2</div>
  </.flex>

  <.flex justify="center" align="center" class="h-32 bg-gray-100">
    <div class="bg-pink-300 p-2 rounded">Centered</div>
  </.flex>
  """
  @doc type: :component

  attr :id, :string,
    default: nil,
    doc: "A unique identifier for the root element of the component"

  attr :direction, :string,
    default: "row",
    doc: "Sets the flex direction of the container"

  attr :justify, :string,
    default: "start",
    doc: "Controls alignment of items along the main axis"

  attr :align, :string,
    default: "stretch",
    doc: "Controls alignment of items along the cross axis"

  attr :align_self, :string,
    default: "",
    doc: "Controls alignment for a single item, overriding the container's align setting"

  attr :gap, :string,
    default: "",
    doc: "Sets the space between child elements"

  attr :wrap, :string,
    default: "wrap",
    doc: "Controls wrapping behavior of flex items"

  attr :grow, :string,
    default: "",
    doc: "Determines whether flex items grow to fill available space"

  attr :shrink, :string,
    default: "",
    doc: "Determines whether flex items shrink if needed"

  attr :basis, :string,
    default: "",
    doc: "Sets the initial main size of a flex item"

  attr :order, :string,
    default: "",
    doc: "Controls the visual order of an item within a flex or grid container"

  attr :class, :string,
    default: "",
    doc: "Additional CSS classes to apply to the container"

  attr :rest, :global,
    doc: "Any valid global HTML attributes passed to the component (e.g. aria, data-*)"

  slot :inner_block,
    required: false,
    doc: "The inner content to render inside the component"

  def flex(assigns) do
    ~H"""
    <div
      id={@id}
      class={[
        "flex",
        direction_class(@direction),
        justify_class(@justify),
        align_class(@align),
        align_self_class(@align_self),
        wrap_class(@wrap),
        shrink_class(@shrink),
        grow_class(@grow),
        basis_class(@basis),
        gap_class(@gap),
        order_class(@order),
        @class
      ]}
      {@rest}
    >
      {render_slot(@inner_block)}
    </div>
    """
  end

  @doc """
  Renders a `grid` container component that wraps Tailwind's Grid utilities
  with a clean and consistent interface.

  You can control columns, rows, gaps, and other grid-related behaviors
  through simple props.

  ## Examples

  ```elixir
  <.grid cols="three" gap="medium">
    <div>Item 1</div>
    <div>Item 2</div>
    <div>Item 3</div>
  </.grid>

  <.grid cols="two" rows="two" class="h-32 bg-gray-100">
    <div class="bg-pink-300 p-2 rounded">Grid Item</div>
    <div class="bg-blue-300 p-2 rounded">Grid Item</div>
    <div class="bg-green-300 p-2 rounded">Grid Item</div>
    <div class="bg-yellow-300 p-2 rounded">Grid Item</div>
  </.grid>
  """

  @doc type: :component
  attr :id, :string,
    default: nil,
    doc: "A unique identifier for the root element of the component"

  attr :cols, :string,
    default: "twelve",
    doc: "Defines the number of columns in the grid"

  attr :rows, :string,
    default: "",
    doc: "Defines the number of rows in the grid"

  attr :auto_cols, :string,
    default: "",
    doc: "Sets the size for implicitly created columns"

  attr :auto_rows, :string,
    default: "",
    doc: "Sets the size for implicitly created rows"

  attr :auto_flow, :string,
    default: "",
    doc: "Controls how auto-placed items are inserted into the grid"

  attr :justify_items, :string,
    default: "",
    doc: "Controls how grid items are aligned along the row axis"

  attr :justify_self, :string,
    default: "",
    doc: "Overrides alignment for a single grid item along the row axis"

  attr :gap, :string,
    default: "",
    doc: "Sets the space between child elements"

  attr :align_content, :string,
    default: "",
    doc: "Controls how multiple rows are aligned within the grid container"

  attr :place_content, :string,
    default: "",
    doc: "Shorthand for setting both align-content and justify-content"

  attr :order, :string,
    default: "",
    doc: "Controls the visual order of an item within a flex or grid container"

  attr :place_items, :string,
    default: "",
    doc: "Shorthand to align items along both axes in the grid container"

  attr :place_self, :string,
    default: "",
    doc: "Shorthand to align a single item along both axes"

  attr :class, :string,
    default: "",
    doc: "Additional CSS classes to apply to the container"

  attr :rest, :global,
    doc: "Any valid global HTML attributes passed to the component (e.g. aria, data-*)"

  slot :inner_block,
    required: false,
    doc: "The inner content to render inside the component"

  def grid(assigns) do
    ~H"""
    <div
      id={@id}
      class={[
        "grid",
        cols_class(@cols),
        rows_class(@rows),
        auto_cols_class(@auto_cols),
        auto_rows_class(@auto_rows),
        auto_flow_class(@auto_flow),
        justify_self_class(@justify_self),
        align_content_class(@align_content),
        place_content_class(@place_content),
        place_items_class(@place_items),
        place_self_class(@place_self),
        gap_class(@gap),
        order_class(@order),
        @class
      ]}
      {@rest}
    >
      {render_slot(@inner_block)}
    </div>
    """
  end

  defp direction_class("row"), do: "flex-row"
  defp direction_class("row-reverse"), do: "flex-row-reverse"
  defp direction_class("col"), do: "flex-col"
  defp direction_class("col-reverse"), do: "flex-col-reverse"
  defp direction_class(param) when is_binary(param), do: param

  defp justify_class("start"), do: "justify-start"
  defp justify_class("center"), do: "justify-center"
  defp justify_class("end"), do: "justify-end"
  defp justify_class("between"), do: "justify-between"
  defp justify_class("around"), do: "justify-around"
  defp justify_class("evenly"), do: "justify-evenly"
  defp justify_class(param) when is_binary(param), do: param

  defp align_class("start"), do: "items-start"
  defp align_class("center"), do: "items-center"
  defp align_class("end"), do: "items-end"
  defp align_class("stretch"), do: "items-stretch"
  defp align_class("baseline"), do: "items-baseline"
  defp align_class(param) when is_binary(param), do: param

  defp align_self_class("auto"), do: "self-auto"
  defp align_self_class("start"), do: "self-start"
  defp align_self_class("center"), do: "self-center"
  defp align_self_class("end"), do: "self-end"
  defp align_self_class("stretch"), do: "self-stretch"
  defp align_self_class(param) when is_binary(param), do: param

  defp wrap_class("nowrap"), do: "flex-nowrap"
  defp wrap_class("wrap"), do: "flex-wrap"
  defp wrap_class("wrap-reverse"), do: "flex-wrap-reverse"
  defp wrap_class(param) when is_binary(param), do: param

  defp grow_class("grow"), do: "grow"
  defp grow_class("none"), do: "grow-0"
  defp grow_class(param) when is_binary(param), do: param

  defp shrink_class("shrink"), do: "shrink"
  defp shrink_class("none"), do: "shrink-0"
  defp shrink_class(param) when is_binary(param), do: param

  defp basis_class("extra_small"), do: "basis-1"
  defp basis_class("small"), do: "basis-2"
  defp basis_class("medium"), do: "basis-3"
  defp basis_class("large"), do: "basis-4"
  defp basis_class("extra_large"), do: "basis-5"
  defp basis_class(param) when is_binary(param), do: param

  defp gap_class("extra_small"), do: "gap-1"
  defp gap_class("small"), do: "gap-2"
  defp gap_class("medium"), do: "gap-3"
  defp gap_class("large"), do: "gap-4"
  defp gap_class("extra_large"), do: "gap-5"
  defp gap_class(param) when is_binary(param), do: param

  defp order_class("first"), do: "order-first"
  defp order_class("last"), do: "order-last"
  defp order_class("none"), do: "order-none"
  defp order_class(param) when is_binary(param), do: param

  defp cols_class("one"), do: "grid-cols-1"
  defp cols_class("two"), do: "grid-cols-2"
  defp cols_class("three"), do: "grid-cols-3"
  defp cols_class("four"), do: "grid-cols-4"
  defp cols_class("five"), do: "grid-cols-5"
  defp cols_class("six"), do: "grid-cols-6"
  defp cols_class("seven"), do: "grid-cols-7"
  defp cols_class("eight"), do: "grid-cols-8"
  defp cols_class("nine"), do: "grid-cols-9"
  defp cols_class("ten"), do: "grid-cols-10"
  defp cols_class("eleven"), do: "grid-cols-11"
  defp cols_class("twelve"), do: "grid-cols-12"
  defp cols_class("none"), do: "grid-cols-none"
  defp cols_class(param) when is_binary(param), do: param

  defp rows_class("one"), do: "grid-rows-1"
  defp rows_class("two"), do: "grid-rows-2"
  defp rows_class("three"), do: "grid-rows-3"
  defp rows_class("four"), do: "grid-rows-4"
  defp rows_class("five"), do: "grid-rows-5"
  defp rows_class("six"), do: "grid-rows-6"
  defp rows_class("none"), do: "grid-rows-none"
  defp rows_class(param) when is_binary(param), do: param

  defp auto_cols_class("auto"), do: "auto-cols-auto"
  defp auto_cols_class("min"), do: "auto-cols-min"
  defp auto_cols_class("max"), do: "auto-cols-max"
  defp auto_cols_class("fr"), do: "auto-cols-fr"
  defp auto_cols_class(param) when is_binary(param), do: param

  defp auto_rows_class("auto"), do: "auto-rows-auto"
  defp auto_rows_class("min"), do: "auto-rows-min"
  defp auto_rows_class("max"), do: "auto-rows-max"
  defp auto_rows_class("fr"), do: "auto-rows-fr"
  defp auto_rows_class(param) when is_binary(param), do: param

  defp auto_flow_class("row"), do: "grid-flow-row"
  defp auto_flow_class("col"), do: "grid-flow-col"
  defp auto_flow_class("row-dense"), do: "grid-flow-row-dense"
  defp auto_flow_class("col-dense"), do: "grid-flow-col-dense"
  defp auto_flow_class(param) when is_binary(param), do: param

  defp justify_self_class("auto"), do: "justify-self-auto"
  defp justify_self_class("start"), do: "justify-self-start"
  defp justify_self_class("end"), do: "justify-self-end"
  defp justify_self_class("center"), do: "justify-self-center"
  defp justify_self_class("stretch"), do: "justify-self-stretch"
  defp justify_self_class(param) when is_binary(param), do: param

  defp align_content_class("start"), do: "content-start"
  defp align_content_class("center"), do: "content-center"
  defp align_content_class("end"), do: "content-end"
  defp align_content_class("between"), do: "content-between"
  defp align_content_class("around"), do: "content-around"
  defp align_content_class("evenly"), do: "content-evenly"
  defp align_content_class(param) when is_binary(param), do: param

  defp place_content_class("start"), do: "place-content-start"
  defp place_content_class("center"), do: "place-content-center"
  defp place_content_class("end"), do: "place-content-end"
  defp place_content_class("between"), do: "place-content-between"
  defp place_content_class("around"), do: "place-content-around"
  defp place_content_class("evenly"), do: "place-content-evenly"
  defp place_content_class("stretch"), do: "place-content-stretch"
  defp place_content_class(param) when is_binary(param), do: param

  defp place_items_class("start"), do: "place-items-start"
  defp place_items_class("end"), do: "place-items-end"
  defp place_items_class("center"), do: "place-items-center"
  defp place_items_class("stretch"), do: "place-items-stretch"
  defp place_items_class(param) when is_binary(param), do: param

  defp place_self_class("auto"), do: "place-self-auto"
  defp place_self_class("start"), do: "place-self-start"
  defp place_self_class("end"), do: "place-self-end"
  defp place_self_class("center"), do: "place-self-center"
  defp place_self_class("stretch"), do: "place-self-stretch"
  defp place_self_class(param) when is_binary(param), do: param
end
