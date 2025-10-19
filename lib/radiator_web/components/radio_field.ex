defmodule RadiatorWeb.Components.RadioField do
  @moduledoc """
  The `RadiatorWeb.Components.RadioField` module provides a highly customizable radio button
  component for Phoenix LiveView applications. This module supports various styling options,
  including different colors, sizes, and border styles, allowing developers to
  integrate radio buttons seamlessly into their design system.

  The component offers attributes and slots to control layout, appearance, and behavior,
  making it versatile for use cases ranging from simple forms to complex UI elements.
  With features such as error handling and custom labels, it enhances the usability and
  accessibility of forms, ensuring a cohesive user experience across the application.

  In addition, the module includes support for grouped radio buttons with the `group_radio`
  component, enabling the creation of sets of related radio inputs. This facilitates the
  development of dynamic and interactive form elements in a clean and organized manner.

  **Documentation:** https://mishka.tools/chelekom/docs/forms/radio-field
  """
  use Phoenix.Component
  alias Phoenix.HTML.Form
  import RadiatorWeb.Components.Icon, only: [icon: 1]

  @doc """
  Renders a `radio_field` component. This component allows users to select a single option from
  a list of options, and provides various customization options for appearance and behavior.

  ## Examples

  ```elixir
  <.radio_field name="option" value="Option 1" space="small" label="Option 1 Label"/>

  <.radio_field
    name="option"
    value="Option 2"
    space="medium"
    color="secondary"
    label="Option 2 Label"
    checked
  />

  <.radio_field name="option" value="Option 3" color="dawn" label="Option 3 Label" reverse/>

  <.radio_field
    name="option"
    value="Option 4"
    space="medium"
    color="danger"
    label="Option 4 Label"
    errors={["Error message for Option 4"]}
  />

  <.radio_field name="option" value="Option 5" space="small" color="info" label="Option 5 Label"/>
  ```
  """
  @doc type: :component
  attr :id, :string,
    default: nil,
    doc: "A unique identifier is used to manage state and interaction"

  attr :class, :any, default: nil, doc: "Custom CSS class for additional styling"
  attr :label_class, :string, default: nil, doc: "Custom CSS class for the label styling"
  attr :color, :string, default: "primary", doc: "Determines color theme"
  attr :border, :string, default: "extra_small", doc: "Determines border style"
  attr :space, :string, default: "medium", doc: "Space between items"
  attr :wrapper_class, :string, default: nil, doc: "Custom CSS class for the wrapper"
  attr :radio_class, :string, default: nil, doc: "Custom CSS class for the radio input"

  attr :size, :string,
    default: "extra_large",
    doc:
      "Determines the overall size of the elements, including padding, font size, and other items"

  attr :ring, :boolean,
    default: true,
    doc:
      "Determines a ring border on focused input, utilities for creating outline rings with box-shadows."

  attr :reverse, :boolean, default: false, doc: "Switches the order of the element and label"
  attr :checked, :boolean, default: false, doc: "Specifies if the element is checked by default"
  attr :error_icon, :string, default: nil, doc: "Icon to be displayed alongside error messages"
  attr :label, :string, default: nil, doc: "Specifies text for the label"

  attr :errors, :list, default: [], doc: "List of error messages to be displayed"
  attr :name, :any, doc: "Name of input"
  attr :value, :any, doc: "Value of input"

  attr :field, Phoenix.HTML.FormField, doc: "a form field struct retrieved from the form"

  attr :rest, :global,
    include: ~w(autocomplete disabled form checked readonly required title autofocus),
    doc:
      "Global attributes can define defaults which are merged with attributes provided by the caller"

  @spec radio_field(map()) :: Phoenix.LiveView.Rendered.t()
  def radio_field(%{field: %Phoenix.HTML.FormField{} = field} = assigns) do
    errors = if Phoenix.Component.used_input?(field), do: field.errors, else: []

    assigns
    |> assign(field: nil, id: assigns.id || field.id)
    |> assign(:errors, Enum.map(errors, &translate_error(&1)))
    |> assign_new(:name, fn -> field.name end)
    |> assign_new(:value, fn -> field.value end)
    |> radio_field()
  end

  def radio_field(assigns) do
    ~H"""
    <div class={[
      color_class(@color),
      border_class(@border),
      size_class(@size),
      space_class(@space),
      @ring && "[&_.radio-field-wrapper_input]:focus-within:ring-1",
      @reverse && "[&_.radio-field-wrapper]:flex-row-reverse",
      @class
    ]}>
      <.label class={["radio-field-wrapper flex items-center w-fit", @wrapper_class]} for={@id}>
        <input
          type="radio"
          name={@name}
          id={@id}
          value={@value}
          checked={@checked}
          class={[
            "bg-white dark:bg-base-bg-dark radio-input rounded-full",
            @radio_class
          ]}
          {@rest}
        />
        <span :if={@label} class={@label_class}>{@label}</span>
      </.label>

      <.error :for={msg <- @errors} icon={@error_icon}>{msg}</.error>
    </div>
    """
  end

  @doc """
  Renders a `group_radio` component, allowing users to select a single option from a list of
  grouped options. This component provides flexibility in layout, appearance, and behavior.

  ## Examples

  ```elixir
  <.group_radio name="items_group_1" space="small">
    <:radio value="option1">Option 1</:radio>
    <:radio value="option2">Option 2</:radio>
    <:radio value="option3">Option 3</:radio>
    <:radio value="option4" checked>Option 4</:radio>
  </.group_radio>
  ```
  """
  @doc type: :component
  attr :id, :string,
    default: nil,
    doc: "A unique identifier is used to manage state and interaction"

  attr :class, :string, default: nil, doc: "Custom CSS class for additional styling"
  attr :color, :string, default: "primary", doc: "Determines color theme"
  attr :border, :string, default: "extra_small", doc: "Determines border style"
  attr :space, :string, default: "medium", doc: "Space between items"

  attr :variation, :string,
    default: "vertical",
    doc: "Defines the layout orientation of the component"

  attr :label_class, :string, default: nil, doc: "Custom CSS class for the label styling"
  attr :wrapper_class, :string, default: nil, doc: "Custom CSS class for the wrapper"
  attr :radio_class, :string, default: nil, doc: "Custom CSS class for the wrapper"
  attr :radio_wrapper_class, :string, default: nil, doc: "Custom CSS class for the wrapper"

  attr :size, :string,
    default: "extra_large",
    doc:
      "Determines the overall size of the elements, including padding, font size, and other items"

  attr :ring, :boolean,
    default: true,
    doc:
      "Determines a ring border on focused input, utilities for creating outline rings with box-shadows."

  attr :reverse, :boolean, default: false, doc: "Switches the order of the element and label"
  attr :error_icon, :string, default: nil, doc: "Icon to be displayed alongside error messages"
  attr :errors, :list, default: [], doc: "List of error messages to be displayed"
  attr :name, :any, doc: "Name of input"
  attr :value, :any, doc: "Value of input"

  attr :rest, :global,
    include:
      ~w(autocomplete disabled form indeterminate multiple readonly required title autofocus),
    doc:
      "Global attributes can define defaults which are merged with attributes provided by the caller"

  attr :field, Phoenix.HTML.FormField, doc: "a form field struct retrieved from the form"

  slot :radio, required: true do
    attr :value, :string, required: true
    attr :checked, :boolean, required: false
    attr :space, :any, required: false, doc: "Space between items"
  end

  slot :inner_block

  @spec group_radio(map()) :: Phoenix.LiveView.Rendered.t()
  def group_radio(%{field: %Phoenix.HTML.FormField{} = field} = assigns) do
    errors = if Phoenix.Component.used_input?(field), do: field.errors, else: []

    assigns
    |> assign(field: nil, id: assigns.id || field.id)
    |> assign(:errors, Enum.map(errors, &translate_error(&1)))
    |> assign_new(:name, fn -> field.name end)
    |> assign_new(:value, fn -> field.value end)
    |> group_radio()
  end

  def group_radio(assigns) do
    ~H"""
    <div class={[
      @variation == "horizontal" && "flex flex-wrap items-center",
      @variation == "vertical" && "flex flex-col",
      variation_gap(@space),
      @class
    ]}>
      {render_slot(@inner_block)}
      <input type="hidden" name={@name} value="" disabled={@rest[:disabled]} />
      <div
        :for={{radio, index} <- Enum.with_index(@radio, 1)}
        class={[
          color_class(@color),
          border_class(@border),
          size_class(@size),
          space_class(radio[:space] || "small"),
          @ring && "[&_.radio-field-wrapper_input]:focus-within:ring-1",
          @reverse && "[&_.radio-field-wrapper]:flex-row-reverse",
          @wrapper_class
        ]}
      >
        <.label
          class={["radio-field-wrapper flex items-center w-fit", @radio_wrapper_class]}
          for={"#{@id}-#{index}"}
        >
          <input
            type="radio"
            name={@name}
            id={"#{@id}-#{index}"}
            value={radio[:value]}
            checked={radio[:checked]}
            class={["bg-white dark:bg-base-bg-dark radio-input rounded-full", @radio_class]}
            {@rest}
          />
          <span class={@label_class}>{render_slot(radio)}</span>
        </.label>
      </div>
    </div>
    <.error :for={msg <- @errors} icon={@error_icon}>{msg}</.error>
    """
  end

  def radio_check(:list, {field, value}, %{params: params, data: data} = _form) do
    if params[Atom.to_string(field)] do
      new_value = if is_atom(value), do: Atom.to_string(value), else: value
      new_value == params[Atom.to_string(field)]
    else
      Map.get(data, field) == value
    end
  end

  def radio_check(:boolean, field, %{params: params, data: data} = _form) do
    if params[Atom.to_string(field)] do
      Form.normalize_value("radio", params[Atom.to_string(field)])
    else
      Map.get(data, field, false)
    end
  end

  @doc type: :component
  attr :for, :string, default: nil, doc: "Specifies the form which is associated with"
  attr :class, :any, default: nil, doc: "Custom CSS class for additional styling"
  slot :inner_block, required: true, doc: "Inner block that renders HEEx content"

  defp label(assigns) do
    ~H"""
    <label for={@for} class={["block text-sm font-semibold leading-6", @class]}>
      {render_slot(@inner_block)}
    </label>
    """
  end

  @doc type: :component
  attr :icon, :string, default: nil, doc: "Icon displayed alongside of an item"
  slot :inner_block, required: true, doc: "Inner block that renders HEEx content"

  defp error(assigns) do
    ~H"""
    <p class="mt-3 flex items-center gap-3 text-sm leading-6 text-rose-700">
      <.icon :if={!is_nil(@icon)} name={@icon} class="shrink-0" />
      {render_slot(@inner_block)}
    </p>
    """
  end

  defp size_class("extra_small"), do: "[&_.radio-field-wrapper_input]:size-2.5"

  defp size_class("small"), do: "[&_.radio-field-wrapper_input]:size-3"

  defp size_class("medium"), do: "[&_.radio-field-wrapper_input]:size-3.5"

  defp size_class("large"), do: "[&_.radio-field-wrapper_input]:size-4"

  defp size_class("extra_large"), do: "[&_.radio-field-wrapper_input]:size-5"

  defp size_class(params) when is_binary(params), do: params

  defp border_class("none"), do: "[&_.radio-field-wrapper_.radio-input]:border-0"
  defp border_class("extra_small"), do: "[&_.radio-field-wrapper_.radio-input]:border"
  defp border_class("small"), do: "[&_.radio-field-wrapper_.radio-input]:border-2"
  defp border_class("medium"), do: "[&_.radio-field-wrapper_.radio-input]:border-[3px]"
  defp border_class("large"), do: "[&_.radio-field-wrapper_.radio-input]:border-4"
  defp border_class("extra_large"), do: "[&_.radio-field-wrapper_.radio-input]:border-[5px]"
  defp border_class(params) when is_binary(params), do: params

  defp space_class("extra_small"), do: "[&_.radio-field-wrapper]:gap-1"

  defp space_class("small"), do: "[&_.radio-field-wrapper]:gap-1.5"

  defp space_class("medium"), do: "[&_.radio-field-wrapper]:gap-2"

  defp space_class("large"), do: "[&_.radio-field-wrapper]:gap-2.5"

  defp space_class("extra_large"), do: "[&_.radio-field-wrapper]:gap-3"

  defp space_class("none"), do: nil

  defp space_class(params) when is_binary(params), do: params

  defp variation_gap("extra_small"), do: "gap-1"
  defp variation_gap("small"), do: "gap-2"
  defp variation_gap("medium"), do: "gap-3"
  defp variation_gap("large"), do: "gap-4"
  defp variation_gap("extra_large"), do: "gap-5"

  defp variation_gap(params) when is_binary(params), do: params

  defp color_class("base") do
    [
      "text-base-text-light dark:text-base-text-dark",
      "[&_.radio-field-wrapper_.radio-input]:checked:accent-base-form-border-light",
      "dark:[&_.radio-field-wrapper_.radio-input]:checked:accent-base-form-border-dark",
      "[&_.radio-field-wrapper_.radio-input]:border-base-form-border-light",
      "dark:[&_.radio-field-wrapper_.radio-input]:border-base-form-border-dark",
      "focus-within:[&_.radio-field-wrapper_.radio-input]:ring-base-hover-light dark:focus-within:[&_.radio-field-wrapper_.radio-input]:ring-base-hover-dark"
    ]
  end

  defp color_class("white") do
    [
      "[&_.radio-field-wrapper_.radio-input]:text-white text-bordered-white-border",
      "[&_.radio-field-wrapper_.radio-input]:border-bordered-white-border",
      "focus-within:[&_.radio-field-wrapper_.radio-input_.radio-input]:ring-bordered-white-border"
    ]
  end

  defp color_class("natural") do
    [
      "text-natural-hover-light dark:text-natural-border-dark",
      "[&_.radio-field-wrapper_.radio-input]:checked:accent-natural-hover-light",
      "dark:[&_.radio-field-wrapper_.radio-input]:checked:accent-natural-hover-dark",
      "[&_.radio-field-wrapper_.radio-input]:border-natural-hover-light",
      "dark:[&_.radio-field-wrapper_.radio-input]:border-silver-light",
      "focus-within:[&_.radio-field-wrapper_.radio-input]:ring-natural-light dark:focus-within:[&_.radio-field-wrapper_.radio-input]:ring-natural-dark"
    ]
  end

  defp color_class("primary") do
    [
      "text-primary-hover-light dark:text-primary-hover-dark",
      "[&_.radio-field-wrapper_.radio-input]:checked:accent-primary-hover-light",
      "dark:[&_.radio-field-wrapper_.radio-input]:checked:accent-primary-hover-dark",
      "[&_.radio-field-wrapper_.radio-input]:border-primary-hover-light",
      "dark:[&_.radio-field-wrapper_.radio-input]:border-primary-hover-dark",
      "focus-within:[&_.radio-field-wrapper_.radio-input]:ring-primary-light dark:focus-within:[&_.radio-field-wrapper_.radio-input]:ring-primary-dark"
    ]
  end

  defp color_class("secondary") do
    [
      "text-secondary-hover-light dark:text-secondary-hover-dark",
      "[&_.radio-field-wrapper_.radio-input]:checked:accent-secondary-hover-light",
      "dark:[&_.radio-field-wrapper_.radio-input]:checked:accent-secondary-hover-dark",
      "[&_.radio-field-wrapper_.radio-input]:border-secondary-hover-light",
      "dark:[&_.radio-field-wrapper_.radio-input]:border-secondary-hover-dark",
      "focus-within:[&_.radio-field-wrapper_.radio-input]:ring-secondary-light dark:focus-within:[&_.radio-field-wrapper_.radio-input]:ring-secondary-dark"
    ]
  end

  defp color_class("success") do
    [
      "text-success-hover-light dark:text-success-hover-dark",
      "[&_.radio-field-wrapper_.radio-input]:checked:accent-success-hover-light",
      "dark:[&_.radio-field-wrapper_.radio-input]:checked:accent-success-hover-dark",
      "[&_.radio-field-wrapper_.radio-input]:border-success-hover-light",
      "dark:[&_.radio-field-wrapper_.radio-input]:border-success-hover-dark",
      "focus-within:[&_.radio-field-wrapper_.radio-input]:ring-success-light dark:focus-within:[&_.radio-field-wrapper_.radio-input]:ring-success-dark"
    ]
  end

  defp color_class("warning") do
    [
      "text-warning-hover-light dark:text-warning-hover-dark",
      "[&_.radio-field-wrapper_.radio-input]:checked:accent-warning-hover-light",
      "dark:[&_.radio-field-wrapper_.radio-input]:checked:accent-warning-hover-dark",
      "[&_.radio-field-wrapper_.radio-input]:border-warning-hover-light",
      "dark:[&_.radio-field-wrapper_.radio-input]:border-warning-hover-dark",
      "focus-within:[&_.radio-field-wrapper_.radio-input]:ring-warning-light dark:focus-within:[&_.radio-field-wrapper_.radio-input]:ring-warning-dark"
    ]
  end

  defp color_class("danger") do
    [
      "text-danger-hover-light dark:text-danger-hover-dark",
      "[&_.radio-field-wrapper_.radio-input]:checked:accent-danger-hover-light",
      "dark:[&_.radio-field-wrapper_.radio-input]:checked:accent-danger-hover-dark",
      "[&_.radio-field-wrapper_.radio-input]:border-danger-hover-light",
      "dark:[&_.radio-field-wrapper_.radio-input]:border-danger-hover-dark",
      "focus-within:[&_.radio-field-wrapper_.radio-input]:ring-danger-light dark:focus-within:[&_.radio-field-wrapper_.radio-input]:ring-danger-dark"
    ]
  end

  defp color_class("info") do
    [
      "text-info-hover-light dark:text-info-hover-dark",
      "[&_.radio-field-wrapper_.radio-input]:checked:accent-info-hover-light",
      "dark:[&_.radio-field-wrapper_.radio-input]:checked:accent-info-hover-dark",
      "[&_.radio-field-wrapper_.radio-input]:border-info-hover-light",
      "dark:[&_.radio-field-wrapper_.radio-input]:border-info-hover-dark",
      "focus-within:[&_.radio-field-wrapper_.radio-input]:ring-info-light dark:focus-within:[&_.radio-field-wrapper_.radio-input]:ring-info-dark"
    ]
  end

  defp color_class("misc") do
    [
      "text-misc-hover-light dark:text-misc-hover-dark",
      "[&_.radio-field-wrapper_.radio-input]:checked:accent-misc-hover-light",
      "dark:[&_.radio-field-wrapper_.radio-input]:checked:accent-misc-hover-dark",
      "[&_.radio-field-wrapper_.radio-input]:border-misc-hover-light",
      "dark:[&_.radio-field-wrapper_.radio-input]:border-misc-hover-dark",
      "focus-within:[&_.radio-field-wrapper_.radio-input]:ring-misc-light dark:focus-within:[&_.radio-field-wrapper_.radio-input]:ring-misc-dark"
    ]
  end

  defp color_class("dawn") do
    [
      "text-dawn-hover-light dark:text-dawn-hover-dark",
      "[&_.radio-field-wrapper_.radio-input]:checked:accent-dawn-hover-light",
      "dark:[&_.radio-field-wrapper_.radio-input]:checked:accent-dawn-hover-dark",
      "[&_.radio-field-wrapper_.radio-input]:border-dawn-hover-light",
      "dark:[&_.radio-field-wrapper_.radio-input]:border-dawn-hover-dark",
      "focus-within:[&_.radio-field-wrapper_.radio-input]:ring-dawn-light dark:focus-within:[&_.radio-field-wrapper_.radio-input]:ring-dawn-dark"
    ]
  end

  defp color_class("silver") do
    [
      "text-silver-hover-light dark:text-silver-hover-dark",
      "[&_.radio-field-wrapper_.radio-input]:checked:accent-silver-hover-light",
      "dark:[&_.radio-field-wrapper_.radio-input]:checked:accent-silver-hover-dark",
      "[&_.radio-field-wrapper_.radio-input]:border-silver-hover-light",
      "dark:[&_.radio-field-wrapper_.radio-input]:border-silver-hover-dark",
      "focus-within:[&_.radio-field-wrapper_.radio-input]:ring-silver-light dark:focus-within:[&_.radio-field-wrapper_.radio-input]:ring-silver-dark"
    ]
  end

  defp color_class("dark") do
    [
      "[&_.radio-field-wrapper_.radio-input]:text-natural-hover-light text-natural-hover-light",
      "[&_.radio-field-wrapper_.radio-input]:border-silver-hover-light",
      "[&_.radio-field-wrapper_.radio-input]:checked:accent-default-dark-bg",
      "focus-within:[&_.radio-field-wrapper_.radio-input]:ring-natural-hover-light"
    ]
  end

  defp color_class(params) when is_binary(params), do: params

  defp translate_error({msg, opts}) do
    # When using gettext, we typically pass the strings we want
    # to translate as a static argument:
    #
    #     # Translate the number of files with plural rules
    #     dngettext("errors", "1 file", "%{count} files", count)
    #
    # However the error messages in our forms and APIs are generated
    # dynamically, so we need to translate them by calling Gettext
    # with our gettext backend as first argument. Translations are
    # available in the errors.po file (as we use the "errors" domain).
    if count = opts[:count] do
      Gettext.dngettext(RadiatorWeb.Gettext, "errors", msg, msg, count, opts)
    else
      Gettext.dgettext(RadiatorWeb.Gettext, "errors", msg, opts)
    end
  end
end
