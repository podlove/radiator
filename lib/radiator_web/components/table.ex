defmodule RadiatorWeb.Components.Table do
  @moduledoc """
  `RadiatorWeb.Components.Table` is a versatile component for creating customizable tables in a
  Phoenix LiveView application. This module offers a wide range of configurations to tailor table
  presentations, including options for styling, borders, text alignment, padding, and various visual variants.

  It provides components for table structure (`table/1`), headers (`th/1`), rows (`tr/1`), and cells
  (`td/1`). These elements can be easily customized to fit different design requirements,
  such as fixed layouts, border styles, and hover effects.

  By utilizing slots, the module allows for the inclusion of dynamic content in the table's header and
  footer sections, with the ability to embed icons and custom classes for a polished and interactive interface.

  **Documentation:** https://mishka.tools/chelekom/docs/table
  """

  use Phoenix.Component
  use Gettext, backend: RadiatorWeb.Gettext
  import RadiatorWeb.Components.Icon, only: [icon: 1]

  @doc """
  Renders a customizable `table` component that supports custom styling for rows, columns,
  and table headers. This component allows for specifying borders, padding, rounded corners,
  and text alignment.

  It also supports fixed layout and various configurations for headers, footers, and cells.

  ## Examples

  ```elixir
  <.table>
    <:header>Name</:header>
    <:header>Age</:header>
    <:header>Address</:header>
    <:header>Email</:header>
    <:header>Job</:header>
    <:header>Action</:header>

    <.tr>
      <.td>Jim Emerald</.td>
      <.td>27</.td>
      <.td>London No. 1 Lake Park</.td>
      <.td>test@mail.com</.td>
      <.td>Frontend Developer</.td>
      <.td><.rating select={3} count={5} /></.td>
    </.tr>

    <.tr>
      <.td>Alex Brown</.td>
      <.td>32</.td>
      <.td>New York No. 2 River Park</.td>
      <.td>alex@mail.com</.td>
      <.td>Backend Developer</.td>
      <.td><.rating select={4} count={5} /></.td>
    </.tr>

    <.tr>
      <.td>John Doe</.td>
      <.td>28</.td>
      <.td>Los Angeles No. 3 Sunset Boulevard</.td>
      <.td>john@mail.com</.td>
      <.td>UI/UX Designer</.td>
      <.td><.rating select={5} count={5} /></.td>
    </.tr>

    <:footer>Total</:footer>
    <:footer>3 Employees</:footer>
  </.table>


  <.table id="users" rows={@users}>
    <:col :let={user} label="id">{user.id}</:col>
    <:col :let={user} label="username">{user.username}</:col>
  </.table>
  ```
  """
  @doc type: :component
  attr :id, :string,
    default: nil,
    doc: "A unique identifier is used to manage state and interaction"

  attr :class, :string, default: nil, doc: "Custom CSS class for additional styling"
  attr :main_wrapper_class, :string, default: nil, doc: "Custom CSS class"
  attr :inner_wrapper_class, :string, default: nil, doc: "Custom CSS class"
  attr :table_wrapper_class, :string, default: nil, doc: "Custom CSS class"
  attr :table_body_class, :string, default: nil, doc: "Custom CSS class"
  attr :variant, :string, default: "base", doc: "Determines the style"
  attr :rounded, :string, default: "", doc: "Determines the border radius"
  attr :padding, :string, default: "small", doc: "Determines padding for items"
  attr :text_size, :string, default: "small", doc: "Determines text size"
  attr :color, :string, default: "natural", doc: "Determines color theme"
  attr :border, :string, default: "extra_small", doc: "Determines border style"
  attr :header_border, :string, default: "", doc: "Sets the border style for the table header"
  attr :rows_border, :string, default: "", doc: "Sets the border style for rows in the table"
  attr :cols_border, :string, default: "", doc: "Sets the border style for columns in the table"
  attr :thead_class, :string, default: nil, doc: "Adds custom CSS classes to the table header"
  attr :footer_class, :string, default: nil, doc: "Adds custom CSS classes to the table footer"
  attr :table_fixed, :boolean, default: false, doc: "Enables or disables the table's fixed layout"
  attr :text_position, :string, default: "left", doc: "Determines the element's text position"
  attr :space, :string, default: "medium", doc: "Determines the table row spaces"

  attr :rest, :global,
    doc:
      "Global attributes can define defaults which are merged with attributes provided by the caller"

  slot :inner_block, required: false, doc: "Inner block that renders HEEx content"

  slot :header do
    attr :class, :any, doc: "Custom CSS class for additional styling"
    attr :icon, :any, doc: "Icon displayed alongside of an item"
    attr :icon_class, :any, doc: "Determines custom class for the icon"
  end

  slot :footer do
    attr :class, :any, doc: "Custom CSS class for additional styling"
    attr :icon, :any, doc: "Icon displayed alongside of an item"
    attr :icon_class, :any, doc: "Determines custom class for the icon"
  end

  attr :rows, :list, default: []
  attr :row_id, :any, default: nil, doc: "the function for generating the row id"
  attr :row_click, :any, default: nil, doc: "the function for handling phx-click on each row"

  attr :row_item, :any,
    default: &Function.identity/1,
    doc: "the function for mapping each row before calling the :col and :action slots"

  slot :col, required: false do
    attr :label, :string
    attr :label_class, :string
  end

  slot :action, doc: "the slot for showing user actions in the last table column"

  def table(assigns) do
    assigns =
      with %{rows: %Phoenix.LiveView.LiveStream{}} <- assigns do
        assign(assigns, row_id: assigns.row_id || fn {id, _item} -> id end)
      end

    ~H"""
    <div class={["-m-1.5 overflow-x-auto", @main_wrapper_class]}>
      <div class={["p-1.5 min-w-full inline-block align-middle", @inner_wrapper_class]}>
        <div class={[
          "overflow-hidden",
          color_variant(@variant, @color),
          text_position(@text_position),
          rounded_size(@rounded, @variant),
          text_size(@text_size),
          border_class(@border, @variant),
          padding_size(@padding),
          rows_space(@space, @variant),
          @header_border && header_border(@header_border, @variant),
          @rows_border != "" && rows_border(@rows_border, @variant),
          @cols_border && cols_border(@cols_border, @variant),
          @table_wrapper_class
        ]}>
          <table
            class={[
              "min-w-full",
              @rows != [] && "divide-y",
              @table_fixed && "table-fixed",
              @variant == "separated" || (@variant == "base_separated" && "border-separate"),
              @class
            ]}
            {@rest}
          >
            <thead class={@thead_class}>
              <.tr>
                <.th
                  :for={{header, index} <- Enum.with_index(@header, 1)}
                  id={"#{@id}-table-header-#{index}"}
                  scope="col"
                  class={header[:class]}
                >
                  <.icon
                    :if={header[:icon]}
                    name={header[:icon]}
                    class={["table-header-icon block me-2", header[:icon_class]]}
                  />
                  {render_slot(header)}
                </.th>
              </.tr>

              <.tr :if={@col}>
                <.th :for={col <- @col} class={["font-normal", col[:label_class]]}>{col[:label]}</.th>
                <.th :if={@action != []} class="relative">
                  <span class="sr-only">{gettext("Actions")}</span>
                </.th>
              </.tr>
            </thead>

            <tbody
              id={@id}
              phx-update={match?(%Phoenix.LiveView.LiveStream{}, @rows) && "stream"}
              class={[@rows != [] && "divide-y", @table_body_class]}
              aria-live="polite"
            >
              {render_slot(@inner_block)}

              <.tr :for={row <- @rows} :if={@rows != []} id={@row_id && @row_id.(row)}>
                <.td
                  :for={{col, i} <- Enum.with_index(@col)}
                  phx-click={@row_click && @row_click.(row)}
                  class={@row_click && "hover:cursor-pointer"}
                >
                  <div class="relative">
                    <span class="absolute -inset-y-px right-0 -left-4" />
                    <span class={["relative", i == 0 && "font-semibold"]}>
                      {render_slot(col, @row_item.(row))}
                    </span>
                  </div>
                </.td>

                <.td :if={@action} class="relative w-14 p-0">
                  <div class="relative whitespace-nowrap py-4 text-right text-sm font-medium">
                    <span class="absolute -inset-y-px -right-4 left-0" />
                    <span :for={action <- @action} class="relative ml-4 font-semibold leading-6">
                      {render_slot(action, @row_item.(row))}
                    </span>
                  </div>
                </.td>
              </.tr>
            </tbody>

            <tfoot :if={length(@footer) > 0} class={@footer_class}>
              <.tr>
                <.td
                  :for={{footer, index} <- Enum.with_index(@footer, 1)}
                  id={"#{@id}-table-footer-#{index}"}
                  class={footer[:class]}
                >
                  <div class="flex items-center">
                    <.icon
                      :if={footer[:icon]}
                      name={footer[:icon]}
                      class={["table-footer-icon block me-2", footer[:icon_class]]}
                    />
                    {render_slot(footer)}
                  </div>
                </.td>
              </.tr>
            </tfoot>
          </table>
        </div>
      </div>
    </div>
    """
  end

  @doc """
  Renders a table header cell (`<th>`) component with customizable class and scope attributes.
  This component allows for additional styling and accepts global attributes.

  ## Examples

  ```elixir
  <.th>Column Title</.th>
  ```
  """
  @doc type: :component
  attr :id, :string,
    default: nil,
    doc: "A unique identifier is used to manage state and interaction"

  attr :class, :any, default: nil, doc: "Custom CSS class for additional styling"
  attr :scope, :string, default: nil, doc: "Specifies the scope of the table header cell"

  attr :rest, :global,
    doc:
      "Global attributes can define defaults which are merged with attributes provided by the caller"

  slot :inner_block, required: false, doc: "Inner block that renders HEEx content"

  def th(assigns) do
    ~H"""
    <th id={@id} scope={@scope} class={["table-header", @class]} {@rest}>
      {render_slot(@inner_block)}
    </th>
    """
  end

  @doc """
  Renders a table row (<tr>) component with customizable class attributes.
  This component allows for additional styling and accepts global attributes.

  ## Examples

  ```elixir
  <.tr>
    <.td>Data 1</.td>
    <.td>Data 2</.td>
  </.tr>
  ```
  """
  @doc type: :component
  attr :id, :string,
    default: nil,
    doc: "A unique identifier is used to manage state and interaction"

  attr :class, :string, default: nil, doc: "Custom CSS class for additional styling"

  attr :rest, :global,
    doc:
      "Global attributes can define defaults which are merged with attributes provided by the caller"

  slot :inner_block, required: false, doc: "Inner block that renders HEEx content"

  def tr(assigns) do
    ~H"""
    <tr id={@id} class={["table-row", @class]} {@rest}>
      {render_slot(@inner_block)}
    </tr>
    """
  end

  @doc """
  Renders a table data cell (`<td>`) component with customizable class attributes.
  This component allows for additional styling and accepts global attributes.

  ## Examples
  ```elixir
  <.td>Data</.td>
  ```
  """
  @doc type: :component
  attr :id, :string,
    default: nil,
    doc: "A unique identifier is used to manage state and interaction"

  attr :class, :string, default: nil, doc: "Custom CSS class for additional styling"

  attr :rest, :global,
    doc:
      "Global attributes can define defaults which are merged with attributes provided by the caller"

  slot :inner_block, required: false, doc: "Inner block that renders HEEx content"

  def td(assigns) do
    ~H"""
    <td id={@id} class={["table-data-cell", @class]} {@rest}>
      {render_slot(@inner_block)}
    </td>
    """
  end

  defp rounded_size("extra_small", "separated") do
    [
      "[&_.border-separate_tr_td:first-child]:rounded-s-sm",
      "[&_.border-separate_tr_td:last-child]:rounded-e-sm",
      "[&_.border-separate_tr_th:first-child]:rounded-s-sm",
      "[&_.border-separate_tr_th:last-child]:rounded-e-sm"
    ]
  end

  defp rounded_size("small", "separated") do
    [
      "[&_.border-separate_tr_td:first-child]:rounded-s",
      "[&_.border-separate_tr_td:last-child]:rounded-e",
      "[&_.border-separate_tr_th:first-child]:rounded-s",
      "[&_.border-separate_tr_th:last-child]:rounded-e"
    ]
  end

  defp rounded_size("medium", "separated") do
    [
      "[&_.border-separate_tr_td:first-child]:rounded-s-md",
      "[&_.border-separate_tr_td:last-child]:rounded-e-md",
      "[&_.border-separate_tr_th:first-child]:rounded-s-md",
      "[&_.border-separate_tr_th:last-child]:rounded-e-md"
    ]
  end

  defp rounded_size("large", "separated") do
    [
      "[&_.border-separate_tr_td:first-child]:rounded-s-lg",
      "[&_.border-separate_tr_td:last-child]:rounded-e-lg",
      "[&_.border-separate_tr_th:first-child]:rounded-s-lg",
      "[&_.border-separate_tr_th:last-child]:rounded-e-lg"
    ]
  end

  defp rounded_size("extra_large", "separated") do
    [
      "[&_.border-separate_tr_td:first-child]:rounded-s-xl",
      "[&_.border-separate_tr_td:last-child]:rounded-e-xl",
      "[&_.border-separate_tr_th:first-child]:rounded-s-xl",
      "[&_.border-separate_tr_th:last-child]:rounded-e-xl"
    ]
  end

  defp rounded_size("extra_small", "base_separated") do
    [
      "[&_.border-separate_tr_td:first-child]:rounded-s-sm",
      "[&_.border-separate_tr_td:last-child]:rounded-e-sm",
      "[&_.border-separate_tr_th:first-child]:rounded-s-sm",
      "[&_.border-separate_tr_th:last-child]:rounded-e-sm"
    ]
  end

  defp rounded_size("small", "base_separated") do
    [
      "[&_.border-separate_tr_td:first-child]:rounded-s",
      "[&_.border-separate_tr_td:last-child]:rounded-e",
      "[&_.border-separate_tr_th:first-child]:rounded-s",
      "[&_.border-separate_tr_th:last-child]:rounded-e"
    ]
  end

  defp rounded_size("medium", "base_separated") do
    [
      "[&_.border-separate_tr_td:first-child]:rounded-s-md",
      "[&_.border-separate_tr_td:last-child]:rounded-e-md",
      "[&_.border-separate_tr_th:first-child]:rounded-s-md",
      "[&_.border-separate_tr_th:last-child]:rounded-e-md"
    ]
  end

  defp rounded_size("large", "base_separated") do
    [
      "[&_.border-separate_tr_td:first-child]:rounded-s-lg",
      "[&_.border-separate_tr_td:last-child]:rounded-e-lg",
      "[&_.border-separate_tr_th:first-child]:rounded-s-lg",
      "[&_.border-separate_tr_th:last-child]:rounded-e-lg"
    ]
  end

  defp rounded_size("extra_large", "base_separated") do
    [
      "[&_.border-separate_tr_td:first-child]:rounded-s-xl",
      "[&_.border-separate_tr_td:last-child]:rounded-e-xl",
      "[&_.border-separate_tr_th:first-child]:rounded-s-xl",
      "[&_.border-separate_tr_th:last-child]:rounded-e-xl"
    ]
  end

  defp rounded_size("extra_small", _), do: "rounded-sm"

  defp rounded_size("small", _), do: "rounded"

  defp rounded_size("medium", _), do: "rounded-md"

  defp rounded_size("large", _), do: "rounded-lg"

  defp rounded_size("extra_large", _), do: "rounded-xl"

  defp rounded_size(params, _) when is_binary(params), do: [params]

  defp text_size("extra_small"), do: "text-xs"
  defp text_size("small"), do: "text-sm"
  defp text_size("medium"), do: "text-base"
  defp text_size("large"), do: "text-lg"
  defp text_size("extra_large"), do: "text-xl"
  defp text_size(params) when is_binary(params), do: [params]

  defp text_position("left"), do: "[&_table]:text-left [&_table_thead]:text-left"
  defp text_position("right"), do: "[&_table]:text-right [&_table_thead]:text-right"
  defp text_position("center"), do: "[&_table]:text-center [&_table_thead]:text-center"
  defp text_position("justify"), do: "[&_table]:text-justify [&_table_thead]:text-justify"
  defp text_position("start"), do: "[&_table]:text-start [&_table_thead]:text-start"
  defp text_position("end"), do: "[&_table]:text-end [&_table_thead]:text-end"
  defp text_position(params) when is_binary(params), do: params

  defp border_class(_, variant)
       when variant in [
              "default",
              "shadow",
              "transparent",
              "stripped",
              "hoverable",
              "separated",
              "base_separated"
            ],
       do: nil

  defp border_class("extra_small", _), do: "border"
  defp border_class("small", _), do: "border-2"
  defp border_class("medium", _), do: "border-[3px]"
  defp border_class("large", _), do: "border-4"
  defp border_class("extra_large", _), do: "border-[5px]"
  defp border_class(params, _) when is_binary(params), do: [params]

  defp cols_border(_, variant)
       when variant in ["default", "shadow", "transparent", "stripped", "hoverable", "separated"],
       do: nil

  defp cols_border("extra_small", _) do
    [
      "[&_table_thead_th:not(:last-child)]:border-e",
      "[&_table_tbody_td:not(:last-child)]:border-e",
      "[&_table_tfoot_td:not(:last-child)]:border-e"
    ]
  end

  defp cols_border("small", _) do
    [
      "[&_table_thead_th:not(:last-child)]:border-e-2",
      "[&_table_tbody_td:not(:last-child)]:border-e-2",
      "[&_table_tfoot_td:not(:last-child)]:border-e-2"
    ]
  end

  defp cols_border("medium", _) do
    [
      "[&_table_thead_th:not(:last-child)]:border-e-[3px]",
      "[&_table_tbody_td:not(:last-child)]:border-e-[3px]",
      "[&_table_tfoot_td:not(:last-child)]:border-e-[3px]"
    ]
  end

  defp cols_border("large", _) do
    [
      "[&_table_thead_th:not(:last-child)]:border-e-4",
      "[&_table_tbody_td:not(:last-child)]:border-e-4",
      "[&_table_tfoot_td:not(:last-child)]:border-e-4"
    ]
  end

  defp cols_border("extra_large", _) do
    [
      "[&_table_thead_th:not(:last-child)]:border-e-[5px]",
      "[&_table_tbody_td:not(:last-child)]:border-e-[5px]",
      "[&_table_tfoot_td:not(:last-child)]:border-e-[5px]"
    ]
  end

  defp cols_border(params, _) when is_binary(params), do: [params]

  defp rows_border(_, variant)
       when variant in ["default", "shadow", "transparent", "stripped", "hoverable", "separated"],
       do: nil

  defp rows_border("none", "base_separated"), do: nil

  defp rows_border("extra_small", "base_separated") do
    [
      "[&_td]:border-y [&_th]:border-y",
      "[&_td:first-child]:border-s [&_th:first-child]:border-s",
      "[&_td:last-child]:border-e [&_th:last-child]:border-e"
    ]
  end

  defp rows_border("small", "base_separated") do
    [
      "[&_td]:border-y-2 [&_th]:border-y-2",
      "[&_td:first-child]:border-s-2 [&_th:first-child]:border-s-2",
      "[&_td:last-child]:border-e-2 [&_th:last-child]:border-e-2"
    ]
  end

  defp rows_border("medium", "base_separated") do
    [
      "[&_td]:border-y-[3px] [&_th]:border-y-[3px]",
      "[&_td:first-child]:border-s-3 [&_th:first-child]:border-s-3",
      "[&_td:last-child]:border-e-3 [&_th:last-child]:border-e-3"
    ]
  end

  defp rows_border("large", "base_separated") do
    [
      "[&_td]:border-y-4 [&_th]:border-y-4",
      "[&_td:first-child]:border-s-4 [&_th:first-child]:border-s-4",
      "[&_td:last-child]:border-e-4 [&_th:last-child]:border-e-4"
    ]
  end

  defp rows_border("extra_large", "base_separated") do
    [
      "[&_td]:border-y-[5px] [&_th]:border-y-[5px]",
      "[&_td:first-child]:border-s-5 [&_th:first-child]:border-s-5",
      "[&_td:last-child]:border-e-5 [&_th:last-child]:border-e-5"
    ]
  end

  defp rows_border("none", _), do: nil
  defp rows_border("extra_small", _), do: "[&_table_tbody]:divide-y"
  defp rows_border("small", _), do: "[&_table_tbody]:divide-y-2"
  defp rows_border("medium", _), do: "[&_table_tbody]:divide-y-[3px]"
  defp rows_border("large", _), do: "[&_table_tbody]:divide-y-4"
  defp rows_border("extra_large", _), do: "[&_table_tbody]:divide-y-[5px]"
  defp rows_border(params, _) when is_binary(params), do: [params]

  defp header_border(_, variant)
       when variant in [
              "default",
              "shadow",
              "transparent",
              "stripped",
              "hoverable",
              "separated",
              "base_separated"
            ],
       do: nil

  defp header_border("extra_small", _), do: "[&_table]:divide-y"
  defp header_border("small", _), do: "[&_table]:divide-y-2"
  defp header_border("medium", _), do: "[&_table]:divide-y-[3px]"
  defp header_border("large", _), do: "[&_table]:divide-y-4"
  defp header_border("extra_large", _), do: "[&_table]:divide-y-[5px]"
  defp header_border(params, _) when is_binary(params), do: [params]

  defp rows_space(_, variant)
       when variant in [
              "default",
              "shadow",
              "transparent",
              "stripped",
              "hoverable",
              "bordered",
              "base",
              "base_hoverable",
              "base_stripped",
              "outline"
            ],
       do: nil

  defp rows_space("extra_small", _), do: "[&_table]:border-spacing-y-0.5"
  defp rows_space("small", _), do: "[&_table]:border-spacing-y-1"
  defp rows_space("medium", _), do: "[&_table]:border-spacing-y-2"
  defp rows_space("large", _), do: "[&_table]:border-spacing-y-3"
  defp rows_space("extra_large", _), do: "[&_table]:border-spacing-y-4"
  defp rows_space(params, _) when is_binary(params), do: [params]

  defp padding_size("extra_small") do
    [
      "[&_table_.table-data-cell]:px-3 [&_table_.table-data-cell]:py-1.5",
      "[&_table_.table-header]:px-3 [&_table_.table-header]:py-1.5"
    ]
  end

  defp padding_size("small") do
    [
      "[&_table_.table-data-cell]:px-4 [&_table_.table-data-cell]:py-2",
      "[&_table_.table-header]:px-4 [&_table_.table-header]:py-2"
    ]
  end

  defp padding_size("medium") do
    [
      "[&_table_.table-data-cell]:px-5 [&_table_.table-data-cell]:py-2.5",
      "[&_table_.table-header]:px-5 [&_table_.table-header]:py-2.5"
    ]
  end

  defp padding_size("large") do
    [
      "[&_table_.table-data-cell]:px-6 [&_table_.table-data-cell]:py-3",
      "[&_table_.table-header]:px-6 [&_table_.table-header]:py-3"
    ]
  end

  defp padding_size("extra_large") do
    [
      "[&_table_.table-data-cell]:px-7 [&_table_.table-data-cell]:py-3.5",
      "[&_table_.table-header]:px-7 [&_table_.table-header]:py-3.5"
    ]
  end

  defp padding_size(params) when is_binary(params), do: params

  defp color_variant("base", _) do
    [
      "[&_table]:bg-white dark:[&_table]:bg-base-bg-dark [&_table]:text-base-text-light dark:[&_table]:text-base-text-dark",
      "border-base-border-light dark:border-base-border-dark",
      "[&_*]:divide-base-border-light [&_td]:border-base-border-light [&_th]:border-base-border-light",
      "dark:[&_*]:divide-base-border-dark dark:[&_td]:border-base-border-dark dark:[&_th]:border-base-border-dark",
      "shadow-sm"
    ]
  end

  defp color_variant("base_separated", _) do
    [
      "[&_table_tr]:bg-white [&_table]:text-base-text-light dark:[&_table_tr]:bg-base-bg-dark dark:[&_table]:text-base-text-dark",
      "[&_td]:border-base-border-light dark:[&_td]:border-base-border-dark",
      "[&_th]:border-base-border-light dark:[&_th]:border-base-border-dark"
    ]
  end

  defp color_variant("base_hoverable", _) do
    [
      "[&_table]:bg-white [&_table]:text-base-text-light dark:[&_table]:bg-base-bg-dark dark:[&_table]:text-base-text-dark",
      "[&_table_tbody_tr]:hover:bg-base-border-light dark:[&_table_tbody_tr]:hover:bg-base-border-dark",
      "border-base-border-light dark:border-base-border-dark",
      "[&_*]:divide-base-border-light [&_td]:border-base-border-light [&_th]:border-base-border-light",
      "dark:[&_*]:divide-base-border-dark dark:[&_td]:border-base-border-dark dark:[&_th]:border-base-border-dark"
    ]
  end

  defp color_variant("base_stripped", _) do
    [
      "[&_table]:bg-white [&_table]:text-base-text-light dark:[&_table]:bg-base-bg-dark dark:[&_table]:text-base-text-dark",
      "odd:[&_table_tbody_tr]:bg-base-hover-light dark:odd:[&_table_tbody_tr]:bg-base-hover-dark",
      "border-base-border-light dark:border-base-border-dark",
      "[&_*]:divide-base-border-light [&_td]:border-base-border-light [&_th]:border-base-border-light",
      "dark:[&_*]:divide-base-border-dark dark:[&_td]:border-base-border-dark dark:[&_th]:border-base-border-dark"
    ]
  end

  defp color_variant("bordered", "white") do
    "[&_table]:bg-white text-table-white-text border-table-white-border [&_*]:divide-table-white-border [&_td]:border-table-white-border [&_th]:border-table-white-border"
  end

  defp color_variant("bordered", "natural") do
    [
      "[&_table]:bg-natural-bordered-bg-light dark:[&_table]:bg-natural-bordered-bg-dark [&_table]:text-natural-bordered-text-light dark:[&_table]:text-natural-bordered-text-dark",
      "border-natural-border-light dark:border-natural-border-dark",
      "[&_*]:divide-natural-border-light [&_td]:border-natural-border-light [&_th]:border-natural-border-light",
      "dark:[&_*]:divide-natural-border-dark dark:[&_td]:border-natural-border-dark dark:[&_th]:border-natural-border-dark"
    ]
  end

  defp color_variant("bordered", "primary") do
    [
      "[&_table]:bg-primary-bordered-bg-light dark:[&_table]:bg-primary-bordered-bg-dark [&_table]:text-primary-bordered-text-light dark:[&_table]:text-primary-bordered-text-dark",
      "border-primary-bordered-text-light dark:border-primary-bordered-text-dark",
      "[&_*]:divide-primary-bordered-text-light [&_td]:border-primary-bordered-text-light [&_th]:border-primary-bordered-text-light",
      "dark:[&_*]:divide-primary-bordered-text-dark dark:[&_td]:border-primary-bordered-text-dark dark:[&_th]:border-primary-bordered-text-dark"
    ]
  end

  defp color_variant("bordered", "secondary") do
    [
      "[&_table]:bg-secondary-bordered-bg-light dark:[&_table]:bg-secondary-bordered-bg-dark [&_table]:text-secondary-bordered-text-light dark:[&_table]:text-secondary-bordered-text-dark",
      "border-secondary-bordered-text-light dark:border-secondary-bordered-text-dark",
      "[&_*]:divide-secondary-bordered-text-light [&_td]:border-secondary-bordered-text-light [&_th]:border-secondary-bordered-text-light",
      "dark:[&_*]:divide-secondary-bordered-text-dark dark:[&_td]:border-secondary-bordered-text-dark dark:[&_th]:border-secondary-bordered-text-dark"
    ]
  end

  defp color_variant("bordered", "success") do
    [
      "[&_table]:bg-success-bordered-bg-light dark:[&_table]:bg-success-bordered-bg-dark [&_table]:text-success-bordered-text-light dark:[&_table]:text-success-bordered-text-dark",
      "border-success-bordered-text-light dark:border-success-bordered-text-dark",
      "[&_*]:divide-success-bordered-text-light [&_td]:border-success-bordered-text-light [&_th]:border-success-bordered-text-light",
      "dark:[&_*]:divide-success-bordered-text-dark dark:[&_td]:border-success-bordered-text-dark dark:[&_th]:border-success-bordered-text-dark"
    ]
  end

  defp color_variant("bordered", "warning") do
    [
      "[&_table]:bg-warning-bordered-bg-light dark:[&_table]:bg-warning-bordered-bg-dark [&_table]:text-warning-bordered-text-light dark:[&_table]:text-warning-bordered-text-dark",
      "border-warning-bordered-text-light dark:border-warning-bordered-text-dark",
      "[&_*]:divide-warning-bordered-text-light [&_td]:border-warning-bordered-text-light [&_th]:border-warning-bordered-text-light",
      "dark:[&_*]:divide-warning-bordered-text-dark dark:[&_td]:border-warning-bordered-text-dark dark:[&_th]:border-warning-bordered-text-dark"
    ]
  end

  defp color_variant("bordered", "danger") do
    [
      "[&_table]:bg-danger-bordered-bg-light dark:[&_table]:bg-danger-bordered-bg-dark [&_table]:text-danger-bordered-text-light dark:[&_table]:text-danger-bordered-text-dark",
      "border-danger-bordered-text-light dark:border-danger-bordered-text-dark",
      "[&_*]:divide-danger-bordered-text-light [&_td]:border-danger-bordered-text-light [&_th]:border-danger-bordered-text-light",
      "dark:[&_*]:divide-danger-bordered-text-dark dark:[&_td]:border-danger-bordered-text-dark dark:[&_th]:border-danger-bordered-text-dark"
    ]
  end

  defp color_variant("bordered", "info") do
    [
      "[&_table]:bg-info-bordered-bg-light dark:[&_table]:bg-info-bordered-bg-dark [&_table]:text-info-bordered-text-light dark:[&_table]:text-info-bordered-text-dark",
      "border-info-bordered-text-light dark:border-info-bordered-text-dark",
      "[&_*]:divide-info-bordered-text-light [&_td]:border-info-bordered-text-light [&_th]:border-info-bordered-text-light",
      "dark:[&_*]:divide-info-bordered-text-dark dark:[&_td]:border-info-bordered-text-dark dark:[&_th]:border-info-bordered-text-dark"
    ]
  end

  defp color_variant("bordered", "misc") do
    [
      "[&_table]:bg-misc-bordered-bg-light dark:[&_table]:bg-misc-bordered-bg-dark [&_table]:text-misc-bordered-text-light dark:[&_table]:text-misc-bordered-text-dark",
      "border-misc-bordered-text-light dark:border-misc-bordered-text-dark",
      "[&_*]:divide-misc-bordered-text-light [&_td]:border-misc-bordered-text-light [&_th]:border-misc-bordered-text-light",
      "dark:[&_*]:divide-misc-bordered-text-dark dark:[&_td]:border-misc-bordered-text-dark dark:[&_th]:border-misc-bordered-text-dark"
    ]
  end

  defp color_variant("bordered", "dawn") do
    [
      "[&_table]:bg-dawn-bordered-bg-light dark:[&_table]:bg-dawn-bordered-bg-dark [&_table]:text-dawn-bordered-text-light dark:[&_table]:text-dawn-bordered-text-dark",
      "border-dawn-bordered-text-light dark:border-dawn-bordered-text-dark",
      "[&_*]:divide-dawn-bordered-text-light [&_td]:border-dawn-bordered-text-light [&_th]:border-dawn-bordered-text-light",
      "dark:[&_*]:divide-dawn-bordered-text-dark dark:[&_td]:border-dawn-bordered-text-dark dark:[&_th]:border-dawn-bordered-text-dark"
    ]
  end

  defp color_variant("bordered", "silver") do
    [
      "[&_table]:bg-natural-bordered-bg-dark dark:[&_table]:bg-dawn-bordered-bg-dark [&_table]:text-silver-bordered-text-light dark:[&_table]:text-silver-bordered-text-dark",
      "border-silver-bordered-text-light dark:border-silver-bordered-text-dark",
      "[&_*]:divide-silver-bordered-text-light [&_td]:border-silver-bordered-text-light [&_th]:border-silver-bordered-text-light",
      "dark:[&_*]:divide-silver-bordered-text-dark dark:[&_td]:border-silver-bordered-text-dark dark:[&_th]:border-silver-bordered-text-dark"
    ]
  end

  defp color_variant("bordered", "dark") do
    "[&_table]:bg-default-dark-bg text-white border-table-dark-border [&_*]:divide-table-dark-border [&_td]:border-table-dark-border [&_th]:border-table-dark-border"
  end

  defp color_variant("outline", "natural") do
    [
      "[&_table]:text-natural-light border-natural-light dark:[&_table]:text-natural-dark dark:border-natural-dark",
      "[&_*]:divide-natural-light [&_td]:border-natural-light [&_th]:border-natural-light",
      "dark:[&_*]:divide-natural-dark dark:[&_td]:border-natural-dark dark:[&_th]:border-natural-dark"
    ]
  end

  defp color_variant("outline", "primary") do
    [
      "[&_table]:text-primary-light border-primary-light dark:[&_table]:text-primary-dark dark:border-primary-dark",
      "[&_*]:divide-primary-light [&_td]:border-primary-light [&_th]:border-primary-light",
      "dark:[&_*]:divide-primary-dark dark:[&_td]:border-primary-dark dark:[&_th]:border-primary-dark"
    ]
  end

  defp color_variant("outline", "secondary") do
    [
      "[&_table]:text-primary-light border-primary-light dark:[&_table]:text-primary-dark dark:border-primary-dark",
      "[&_*]:divide-primary-light [&_td]:border-primary-light [&_th]:border-primary-light",
      "dark:[&_*]:divide-primary-dark dark:[&_td]:border-primary-dark dark:[&_th]:border-primary-dark"
    ]
  end

  defp color_variant("outline", "success") do
    [
      "[&_table]:text-success-light border-success-light dark:[&_table]:text-success-dark dark:border-success-dark",
      "[&_*]:divide-success-light [&_td]:border-success-light [&_th]:border-success-light",
      "dark:[&_*]:divide-success-dark dark:[&_td]:border-success-dark dark:[&_th]:border-success-dark"
    ]
  end

  defp color_variant("outline", "warning") do
    [
      "[&_table]:text-warning-light border-warning-light dark:[&_table]:text-warning-dark dark:border-warning-dark",
      "[&_*]:divide-warning-light [&_td]:border-warning-light [&_th]:border-warning-light",
      "dark:[&_*]:divide-warning-dark dark:[&_td]:border-warning-dark dark:[&_th]:border-warning-dark"
    ]
  end

  defp color_variant("outline", "danger") do
    [
      "[&_table]:text-danger-light border-danger-light dark:[&_table]:text-danger-dark dark:border-danger-dark",
      "[&_*]:divide-danger-light [&_td]:border-danger-light [&_th]:border-danger-light",
      "dark:[&_*]:divide-danger-dark dark:[&_td]:border-danger-dark dark:[&_th]:border-danger-dark"
    ]
  end

  defp color_variant("outline", "info") do
    [
      "[&_table]:text-info-light border-info-light dark:[&_table]:text-info-dark dark:border-info-dark",
      "[&_*]:divide-info-light [&_td]:border-info-light [&_th]:border-info-light",
      "dark:[&_*]:divide-info-dark dark:[&_td]:border-info-dark dark:[&_th]:border-info-dark"
    ]
  end

  defp color_variant("outline", "misc") do
    [
      "[&_table]:text-misc-light border-misc-light dark:[&_table]:text-misc-dark dark:border-misc-dark",
      "[&_*]:divide-misc-light [&_td]:border-misc-light [&_th]:border-misc-light",
      "dark:[&_*]:divide-misc-dark dark:[&_td]:border-misc-dark dark:[&_th]:border-misc-dark"
    ]
  end

  defp color_variant("outline", "dawn") do
    [
      "[&_table]:text-dawn-light border-dawn-light dark:[&_table]:text-dawn-dark dark:border-dawn-dark",
      "[&_*]:divide-dawn-light [&_td]:border-dawn-light [&_th]:border-dawn-light",
      "dark:[&_*]:divide-dawn-dark dark:[&_td]:border-dawn-dark dark:[&_th]:border-dawn-dark"
    ]
  end

  defp color_variant("outline", "silver") do
    [
      "[&_table]:text-silver-light border-silver-light dark:[&_table]:text-silver-dark dark:border-silver-dark",
      "[&_*]:divide-silver-light [&_td]:border-silver-light [&_th]:border-silver-light",
      "dark:[&_*]:divide-silver-dark dark:[&_td]:border-silver-dark dark:[&_th]:border-silver-dark"
    ]
  end

  defp color_variant("default", "white") do
    "bg-white text-black"
  end

  defp color_variant("default", "natural") do
    "[&_table]:bg-natural-light [&_table]:text-white dark:[&_table]:bg-natural-dark dark:[&_table]:text-black"
  end

  defp color_variant("default", "primary") do
    "[&_table]:bg-primary-light [&_table]:text-white dark:[&_table]:bg-primary-dark dark:[&_table]:text-black"
  end

  defp color_variant("default", "secondary") do
    "[&_table]:bg-secondary-light [&_table]:text-white dark:[&_table]:bg-secondary-dark dark:[&_table]:text-black"
  end

  defp color_variant("default", "success") do
    "[&_table]:bg-success-light [&_table]:text-white dark:[&_table]:bg-success-dark dark:[&_table]:text-black"
  end

  defp color_variant("default", "warning") do
    "[&_table]:bg-warning-light [&_table]:text-white dark:[&_table]:bg-warning-dark dark:[&_table]:text-black"
  end

  defp color_variant("default", "danger") do
    "[&_table]:bg-danger-light [&_table]:text-white dark:[&_table]:bg-danger-dark dark:[&_table]:text-black"
  end

  defp color_variant("default", "info") do
    "[&_table]:bg-info-light [&_table]:text-white dark:[&_table]:bg-info-dark dark:[&_table]:text-black"
  end

  defp color_variant("default", "misc") do
    "[&_table]:bg-misc-light [&_table]:text-white dark:[&_table]:bg-misc-dark dark:[&_table]:text-black"
  end

  defp color_variant("default", "dawn") do
    "[&_table]:bg-dawn-light [&_table]:text-white dark:[&_table]:bg-dawn-dark dark:[&_table]:text-black"
  end

  defp color_variant("default", "silver") do
    "[&_table]:bg-silver-light [&_table]:text-white dark:[&_table]:bg-silver-dark dark:[&_table]:text-black"
  end

  defp color_variant("default", "dark") do
    "[&_table]:bg-default-dark-bg [&_table]:text-white"
  end

  defp color_variant("shadow", "natural") do
    [
      "[&_table]:bg-natural-light [&_table]:text-white dark:[&_table]:bg-natural-dark dark:[&_table]:text-black",
      "shadow-[0px_4px_6px_-4px_var(--color-shadow-natural)] shadow-[0px_10px_15px_-3px_var(--color-shadow-natural)] dark:shadow-none"
    ]
  end

  defp color_variant("shadow", "primary") do
    [
      "[&_table]:bg-primary-light [&_table]:text-white dark:[&_table]:bg-primary-dark dark:[&_table]:text-black",
      "shadow-[0px_4px_6px_-4px_var(--color-shadow-primary)] shadow-[0px_10px_15px_-3px_var(--color-shadow-primary)] dark:shadow-none"
    ]
  end

  defp color_variant("shadow", "secondary") do
    [
      "[&_table]:bg-secondary-light [&_table]:text-white dark:[&_table]:bg-secondary-dark dark:[&_table]:text-black",
      "shadow-[0px_4px_6px_-4px_var(--color-shadow-secondary)] shadow-[0px_10px_15px_-3px_var(--color-shadow-secondary)] dark:shadow-none"
    ]
  end

  defp color_variant("shadow", "success") do
    [
      "[&_table]:bg-success-light [&_table]:text-white dark:[&_table]:bg-success-dark dark:[&_table]:text-black",
      "shadow-[0px_4px_6px_-4px_var(--color-shadow-success)] shadow-[0px_10px_15px_-3px_var(--color-shadow-success)] dark:shadow-none"
    ]
  end

  defp color_variant("shadow", "warning") do
    [
      "[&_table]:bg-warning-light [&_table]:text-white dark:[&_table]:bg-warning-dark dark:[&_table]:text-black",
      "shadow-[0px_4px_6px_-4px_var(--color-shadow-warning)] shadow-[0px_10px_15px_-3px_var(--color-shadow-warning)] dark:shadow-none"
    ]
  end

  defp color_variant("shadow", "danger") do
    [
      "[&_table]:bg-danger-light [&_table]:text-white dark:[&_table]:bg-danger-dark dark:[&_table]:text-black",
      "shadow-[0px_4px_6px_-4px_var(--color-shadow-danger)] shadow-[0px_10px_15px_-3px_var(--color-shadow-danger)] dark:shadow-none"
    ]
  end

  defp color_variant("shadow", "info") do
    [
      "[&_table]:bg-info-light [&_table]:text-white dark:[&_table]:bg-info-dark dark:[&_table]:text-black",
      "shadow-[0px_4px_6px_-4px_var(--color-shadow-info)] shadow-[0px_10px_15px_-3px_var(--color-shadow-info)] dark:shadow-none"
    ]
  end

  defp color_variant("shadow", "misc") do
    [
      "[&_table]:bg-misc-light [&_table]:text-white dark:[&_table]:bg-misc-dark dark:[&_table]:text-black",
      "shadow-[0px_4px_6px_-4px_var(--color-shadow-misc)] shadow-[0px_10px_15px_-3px_var(--color-shadow-misc)] dark:shadow-none"
    ]
  end

  defp color_variant("shadow", "dawn") do
    [
      "[&_table]:bg-dawn-light [&_table]:text-white dark:[&_table]:bg-dawn-dark dark:[&_table]:text-black",
      "shadow-[0px_4px_6px_-4px_var(--color-shadow-dawn)] shadow-[0px_10px_15px_-3px_var(--color-shadow-dawn)] dark:shadow-none"
    ]
  end

  defp color_variant("shadow", "silver") do
    [
      "[&_table]:bg-silver-light [&_table]:text-white dark:[&_table]:bg-silver-dark dark:[&_table]:text-black",
      "shadow-[0px_4px_6px_-4px_var(--color-shadow-silver)] shadow-[0px_10px_15px_-3px_var(--color-shadow-silver)] dark:shadow-none"
    ]
  end

  defp color_variant("transparent", "natural") do
    [
      "[&_table]:text-natural-light dark:[&_table]:text-natural-dark"
    ]
  end

  defp color_variant("transparent", "primary") do
    [
      "[&_table]:text-primary-light dark:[&_table]:text-primary-dark"
    ]
  end

  defp color_variant("transparent", "secondary") do
    [
      "[&_table]:text-secondary-light dark:[&_table]:text-secondary-dark"
    ]
  end

  defp color_variant("transparent", "success") do
    [
      "[&_table]:text-success-light dark:[&_table]:text-success-dark"
    ]
  end

  defp color_variant("transparent", "warning") do
    [
      "[&_table]:text-warning-light dark:[&_table]:text-warning-dark"
    ]
  end

  defp color_variant("transparent", "danger") do
    [
      "[&_table]:text-danger-light dark:[&_table]:text-danger-dark"
    ]
  end

  defp color_variant("transparent", "info") do
    [
      "[&_table]:text-info-light dark:[&_table]:text-info-dark"
    ]
  end

  defp color_variant("transparent", "misc") do
    [
      "[&_table]:text-misc-light dark:[&_table]:text-misc-dark"
    ]
  end

  defp color_variant("transparent", "dawn") do
    [
      "[&_table]:text-dawn-light dark:[&_table]:text-dawn-dark"
    ]
  end

  defp color_variant("transparent", "silver") do
    [
      "[&_table]:text-silver-light dark:[&_table]:text-silver-dark"
    ]
  end

  defp color_variant("hoverable", "white") do
    [
      "[&_table]:bg-white [&_table_tbody_tr]:hover:bg-table-white-border text-table-white-text"
    ]
  end

  defp color_variant("hoverable", "natural") do
    [
      "[&_table]:bg-natural-light [&_table]:text-white dark:[&_table]:bg-natural-dark dark:[&_table]:text-black",
      "[&_table_tbody_tr]:hover:bg-natural-hover-light dark:[&_table_tbody_tr]:hover:bg-natural-hover-dark"
    ]
  end

  defp color_variant("hoverable", "primary") do
    [
      "[&_table]:bg-primary-light [&_table]:text-white dark:[&_table]:bg-primary-dark dark:[&_table]:text-black",
      "[&_table_tbody_tr]:hover:bg-primary-hover-light dark:[&_table_tbody_tr]:hover:bg-primary-hover-dark"
    ]
  end

  defp color_variant("hoverable", "secondary") do
    [
      "[&_table]:bg-secondary-light [&_table]:text-white dark:[&_table]:bg-secondary-dark dark:[&_table]:text-black",
      "[&_table_tbody_tr]:hover:bg-secondary-hover-light dark:[&_table_tbody_tr]:hover:bg-secondary-hover-dark"
    ]
  end

  defp color_variant("hoverable", "success") do
    [
      "[&_table]:bg-success-light [&_table]:text-white dark:[&_table]:bg-success-dark dark:[&_table]:text-black",
      "[&_table_tbody_tr]:hover:bg-success-dark dark:[&_table_tbody_tr]:hover:bg-success-hover-dark"
    ]
  end

  defp color_variant("hoverable", "warning") do
    [
      "[&_table]:bg-warning-light [&_table]:text-white dark:[&_table]:bg-warning-dark dark:[&_table]:text-black",
      "[&_table_tbody_tr]:hover:bg-warning-hover-light dark:[&_table_tbody_tr]:hover:bg-warning-hover-dark"
    ]
  end

  defp color_variant("hoverable", "danger") do
    [
      "[&_table]:bg-danger-light [&_table]:text-white dark:[&_table]:bg-danger-dark dark:[&_table]:text-black",
      "[&_table_tbody_tr]:hover:bg-danger-hover-light dark:[&_table_tbody_tr]:hover:bg-danger-hover-dark"
    ]
  end

  defp color_variant("hoverable", "info") do
    [
      "[&_table]:bg-info-light [&_table]:text-white dark:[&_table]:bg-info-dark dark:[&_table]:text-black",
      "[&_table_tbody_tr]:hover:bg-info-hover-light dark:[&_table_tbody_tr]:hover:bg-info-hover-dark"
    ]
  end

  defp color_variant("hoverable", "misc") do
    [
      "[&_table]:bg-misc-light [&_table]:text-white dark:[&_table]:bg-misc-dark dark:[&_table]:text-black",
      "[&_table_tbody_tr]:hover:bg-misc-hover-light dark:[&_table_tbody_tr]:hover:bg-misc-hover-dark"
    ]
  end

  defp color_variant("hoverable", "dawn") do
    [
      "[&_table]:bg-dawn-light [&_table]:text-white dark:[&_table]:bg-dawn-dark dark:[&_table]:text-black",
      "[&_table_tbody_tr]:hover:bg-dawn-hover-light dark:[&_table_tbody_tr]:hover:bg-dawn-hover-dark"
    ]
  end

  defp color_variant("hoverable", "silver") do
    [
      "[&_table]:bg-silver-light [&_table]:text-white dark:[&_table]:bg-silver-dark dark:[&_table]:text-black",
      "[&_table_tbody_tr]:hover:bg-silver-hover-light dark:[&_table_tbody_tr]:hover:bg-silver-hover-dark"
    ]
  end

  defp color_variant("hoverable", "dark") do
    [
      "[&_table]:bg-default-dark-bg [&_table]:text-white [&_table_tbody_tr]:hover:bg-black"
    ]
  end

  defp color_variant("stripped", "white") do
    [
      "[&_table]:bg-white odd:[&_table_tbody_tr]:bg-table-white-border text-table-white-text"
    ]
  end

  defp color_variant("stripped", "natural") do
    [
      "[&_table]:bg-natural-light [&_table]:text-white dark:[&_table]:bg-natural-dark dark:[&_table]:text-black",
      "odd:[&_table_tbody_tr]:bg-natural-hover-light dark:odd:[&_table_tbody_tr]:bg-natural-hover-dark"
    ]
  end

  defp color_variant("stripped", "primary") do
    [
      "[&_table]:bg-primary-light [&_table]:text-white dark:[&_table]:bg-primary-dark dark:[&_table]:text-black",
      "odd:[&_table_tbody_tr]:bg-primary-hover-light dark:odd:[&_table_tbody_tr]:bg-primary-hover-dark"
    ]
  end

  defp color_variant("stripped", "secondary") do
    [
      "[&_table]:bg-secondary-light [&_table]:text-white dark:[&_table]:bg-secondary-dark dark:[&_table]:text-black",
      "odd:[&_table_tbody_tr]:bg-secondary-hover-light dark:odd:[&_table_tbody_tr]:bg-secondary-hover-dark"
    ]
  end

  defp color_variant("stripped", "success") do
    [
      "[&_table]:bg-success-light [&_table]:text-white dark:[&_table]:bg-success-dark dark:[&_table]:text-black",
      "odd:[&_table_tbody_tr]:bg-success-dark dark:odd:[&_table_tbody_tr]:bg-success-hover-dark"
    ]
  end

  defp color_variant("stripped", "warning") do
    [
      "[&_table]:bg-warning-light [&_table]:text-white dark:[&_table]:bg-warning-dark dark:[&_table]:text-black",
      "odd:[&_table_tbody_tr]:bg-warning-hover-light dark:odd:[&_table_tbody_tr]:bg-warning-hover-dark"
    ]
  end

  defp color_variant("stripped", "danger") do
    [
      "[&_table]:bg-danger-light [&_table]:text-white dark:[&_table]:bg-danger-dark dark:[&_table]:text-black",
      "odd:[&_table_tbody_tr]:bg-danger-hover-light dark:odd:[&_table_tbody_tr]:bg-danger-hover-dark"
    ]
  end

  defp color_variant("stripped", "info") do
    [
      "[&_table]:bg-info-light [&_table]:text-white dark:[&_table]:bg-info-dark dark:[&_table]:text-black",
      "odd:[&_table_tbody_tr]:bg-info-hover-light dark:odd:[&_table_tbody_tr]:bg-info-hover-dark"
    ]
  end

  defp color_variant("stripped", "misc") do
    [
      "[&_table]:bg-misc-light [&_table]:text-white dark:[&_table]:bg-misc-dark dark:[&_table]:text-black",
      "odd:[&_table_tbody_tr]:bg-misc-hover-light dark:odd:[&_table_tbody_tr]:bg-misc-hover-dark"
    ]
  end

  defp color_variant("stripped", "dawn") do
    [
      "[&_table]:bg-dawn-light [&_table]:text-white dark:[&_table]:bg-dawn-dark dark:[&_table]:text-black",
      "odd:[&_table_tbody_tr]:bg-dawn-hover-light dark:odd:[&_table_tbody_tr]:bg-dawn-hover-dark"
    ]
  end

  defp color_variant("stripped", "silver") do
    [
      "[&_table]:bg-silver-light [&_table]:text-white dark:[&_table]:bg-silver-dark dark:[&_table]:text-black",
      "odd:[&_table_tbody_tr]:bg-silver-hover-light dark:odd:[&_table_tbody_tr]:bg-silver-hover-dark"
    ]
  end

  defp color_variant("stripped", "dark") do
    [
      "[&_table]:bg-default-dark-bg [&_table]:text-white odd:[&_table_tbody_tr]:bg-black"
    ]
  end

  defp color_variant("separated", "white") do
    "[&_table_tr]:bg-white [&_table]:text-black"
  end

  defp color_variant("separated", "natural") do
    "[&_table_tr]:bg-natural-light [&_table]:text-white dark:[&_table_tr]:bg-natural-dark dark:[&_table]:text-black"
  end

  defp color_variant("separated", "primary") do
    "[&_table_tr]:bg-primary-light [&_table]:text-white dark:[&_table_tr]:bg-primary-dark dark:[&_table]:text-black"
  end

  defp color_variant("separated", "secondary") do
    "[&_table_tr]:bg-secondary-light [&_table]:text-white dark:[&_table_tr]:bg-secondary-dark dark:[&_table]:text-black"
  end

  defp color_variant("separated", "success") do
    "[&_table_tr]:bg-success-light [&_table]:text-white dark:[&_table_tr]:bg-success-dark dark:[&_table]:text-black"
  end

  defp color_variant("separated", "warning") do
    "[&_table_tr]:bg-warning-light [&_table]:text-white dark:[&_table_tr]:bg-warning-dark dark:[&_table]:text-black"
  end

  defp color_variant("separated", "danger") do
    "[&_table_tr]:bg-danger-light [&_table]:text-white dark:[&_table_tr]:bg-danger-dark dark:[&_table]:text-black"
  end

  defp color_variant("separated", "info") do
    "[&_table_tr]:bg-info-light [&_table]:text-white dark:[&_table_tr]:bg-info-dark dark:[&_table]:text-black"
  end

  defp color_variant("separated", "misc") do
    "[&_table_tr]:bg-misc-light [&_table]:text-white dark:[&_table_tr]:bg-misc-dark dark:[&_table]:text-black"
  end

  defp color_variant("separated", "dawn") do
    "[&_table_tr]:bg-dawn-light [&_table]:text-white dark:[&_table_tr]:bg-dawn-dark dark:[&_table]:text-black"
  end

  defp color_variant("separated", "silver") do
    "[&_table_tr]:bg-silver-light [&_table]:text-white dark:[&_table_tr]:bg-silver-dark dark:[&_table]:text-black"
  end

  defp color_variant("separated", "dark") do
    "[&_table_tr]:bg-default-dark-bg [&_table]:text-white"
  end

  defp color_variant(params, _) when is_binary(params), do: params
end
