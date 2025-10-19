defmodule RadiatorWeb.Components.ColorField do
  @moduledoc """
  The `RadiatorWeb.Components.ColorField` module provides a reusable and customizable color
  input component for Phoenix applications. This component supports various styling options,
  error handling, and additional customization through attributes and slots.

  ## Features:
  - Customizable color themes, border styles, and rounded corners.
  - Optional sections for displaying icons or additional elements before and after the input field.
  - Flexible error handling with support for custom error icons and messages.
  - Configurable size and layout options for various use cases.
  - Support for Phoenix form field integration.

  **Documentation:** https://mishka.tools/chelekom/docs/forms/color-field
  """

  use Phoenix.Component
  import RadiatorWeb.Components.Icon, only: [icon: 1]

  @doc """
  The `color_field` component is used to create a customizable color input field with various
  options such as `size`, `color`, and `rounded`.

  It supports labels, descriptions, and error messages, making it suitable for form validation and styling.

  ## Examples

  ```elixir
  <div class="p-10">
    <.color_field
      name="name1"
      value="#ff5733"
      border="none"
      rounded="small"
      color="danger"
      description="This is description"
      label="This is label"
    />

    <.color_field
      name="name1"
      color="dark"
      description="This is description"
      label="This is label"
      size="extra_large"
    />

    <.color_field name="name1" color="dark" size="full" label="This is label"/>
  </div>
  ```
  """
  @doc type: :component
  attr :id, :string,
    default: nil,
    doc: "A unique identifier is used to manage state and interaction"

  attr :class, :string, default: nil, doc: "Custom CSS class for additional styling"
  attr :color, :string, default: "natural", doc: "Determines color theme"
  attr :border, :string, default: "extra_small", doc: "Determines border style"
  attr :rounded, :string, default: "small", doc: "Determines the border radius"
  attr :description, :string, default: nil, doc: "Determines a short description"
  attr :description_class, :string, default: "text-[12px]", doc: "Custom classes for description"
  attr :label_class, :string, default: nil, doc: "Custom CSS class for the label styling"
  attr :field_wrapper_class, :string, default: nil, doc: "Custom CSS class field wrapper"
  attr :input_class, :string, default: nil, doc: "Custom CSS class for the input"
  attr :space, :string, default: "medium", doc: "Space between items"

  attr :description_wrapper_class, :string,
    default: nil,
    doc: "Custom classes for description wrapper"

  attr :size, :string,
    default: "extra_large",
    doc:
      "Determines the overall size of the elements, including padding, font size, and other items"

  attr :circle, :boolean,
    default: false,
    doc: "Determines if the color input should be displayed as a circle"

  attr :error_icon, :string, default: nil, doc: "Icon to be displayed alongside error messages"
  attr :label, :string, default: nil, doc: "Specifies text for the label"

  attr :errors, :list, default: [], doc: "List of error messages to be displayed"
  attr :name, :any, doc: "Name of input"
  attr :value, :any, default: "#000000", doc: "Value of input"

  attr :field, Phoenix.HTML.FormField, doc: "a form field struct retrieved from the form"

  attr :rest, :global,
    include: ~w(autocomplete disabled form list min max pattern placeholder
        readonly required size inputmode inputmode step title autofocus),
    doc:
      "Global attributes can define defaults which are merged with attributes provided by the caller"

  @spec color_field(map()) :: Phoenix.LiveView.Rendered.t()
  def color_field(%{field: %Phoenix.HTML.FormField{} = field} = assigns) do
    errors = if Phoenix.Component.used_input?(field), do: field.errors, else: []

    assigns
    |> assign(field: nil, id: assigns.id || field.id)
    |> assign(:errors, Enum.map(errors, &translate_error(&1)))
    |> assign_new(:name, fn -> field.name end)
    |> assign_new(:value, fn -> field.value end)
    |> color_field()
  end

  def color_field(assigns) do
    ~H"""
    <div class={[
      "w-fit",
      color_class(@color),
      rounded_size(@rounded),
      border_class(@border),
      size_class(@size),
      space_class(@space),
      @class
    ]}>
      <div
        :if={@label || @description}
        class={["color-field-label-wrapper", @description_wrapper_class]}
      >
        <.label :if={@label} for={@id} class={@label_class}>{@label}</.label>
        <div :if={@description} class={@description_class}>
          {@description}
        </div>
      </div>

      <div class="color-field-wrapper">
        <input
          type="color"
          name={@name}
          id={@id}
          value={@value}
          class={["color-input", @input_class]}
          {@rest}
        />
      </div>
      <.error :for={msg <- @errors} icon={@error_icon}>{msg}</.error>
    </div>
    """
  end

  attr :for, :string, default: nil, doc: "Specifies the form which is associated with"
  attr :class, :string, default: nil, doc: "Custom CSS class for additional styling"
  slot :inner_block, required: true, doc: "Inner block that renders HEEx content"

  defp label(assigns) do
    ~H"""
    <label for={@for} class={["leading-5 font-semibold", @class]}>
      {render_slot(@inner_block)}
    </label>
    """
  end

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

  defp size_class("extra_small") do
    [
      "[&_.color-field-wrapper_.color-input]:w-7 [&_.color-field-wrapper_.color-input]:h-4"
    ]
  end

  defp size_class("small") do
    [
      "[&_.color-field-wrapper_.color-input]:w-8 [&_.color-field-wrapper_.color-input]:h-5"
    ]
  end

  defp size_class("medium") do
    [
      "[&_.color-field-wrapper_.color-input]:w-9 [&_.color-field-wrapper_.color-input]:h-6"
    ]
  end

  defp size_class("large") do
    [
      "[&_.color-field-wrapper_.color-input]:w-10 [&_.color-field-wrapper_.color-input]:h-7"
    ]
  end

  defp size_class("extra_large") do
    [
      "[&_.color-field-wrapper_.color-input]:w-11 [&_.color-field-wrapper_.color-input]:h-8"
    ]
  end

  defp size_class("full"), do: "[&_.color-field-wrapper_.color-input]:w-full h-4"

  defp size_class(params) when is_binary(params), do: params

  defp rounded_size("extra_small"), do: "[&_.color-field-wrapper_.color-input]:rounded-sm"

  defp rounded_size("small"), do: "[&_.color-field-wrapper_.color-input]:rounded"

  defp rounded_size("medium"), do: "[&_.color-field-wrapper_.color-input]:rounded-md"

  defp rounded_size("large"), do: "[&_.color-field-wrapper_.color-input]:rounded-lg"

  defp rounded_size("extra_large"), do: "[&_.color-field-wrapper_.color-input]:rounded-xl"

  defp rounded_size("none"), do: nil

  defp rounded_size(params) when is_binary(params), do: params

  defp border_class("none"), do: "[&_.color-field-wrapper_.color-input]:border-0"
  defp border_class("extra_small"), do: "[&_.color-field-wrapper_.color-input]:border"
  defp border_class("small"), do: "[&_.color-field-wrapper_.color-input]:border-2"
  defp border_class("medium"), do: "[&_.color-field-wrapper_.color-input]:border-[3px]"
  defp border_class("large"), do: "[&_.color-field-wrapper_.color-input]:border-4"
  defp border_class("extra_large"), do: "[&_.color-field-wrapper_.color-input]:border-[5px]"
  defp border_class(params) when is_binary(params), do: params

  defp space_class("none"), do: nil

  defp space_class("extra_small"), do: "space-y-1"

  defp space_class("small"), do: "space-y-1.5"

  defp space_class("medium"), do: "space-y-2"

  defp space_class("large"), do: "space-y-2.5"

  defp space_class("extra_large"), do: "space-y-3"

  defp space_class(params) when is_binary(params), do: params

  defp color_class("base") do
    [
      "[&_.color-field-wrapper_.color-input]:border-base-border-light",
      "dark:[&_.color-field-wrapper_.color-input]:border-base-border-dark"
    ]
  end

  defp color_class("white") do
    [
      "[&_.color-field-wrapper_.color-input]:border-form-white-focus"
    ]
  end

  defp color_class("natural") do
    [
      "[&_.color-field-wrapper_.color-input]:border-natural-light",
      "dark:[&_.color-field-wrapper_.color-input]:border-natural-dark"
    ]
  end

  defp color_class("primary") do
    [
      "[&_.color-field-wrapper_.color-input]:border-primary-light",
      "dark:[&_.color-field-wrapper_.color-input]:border-primary-dark"
    ]
  end

  defp color_class("secondary") do
    [
      "[&_.color-field-wrapper_.color-input]:border-secondary-light",
      "dark:[&_.color-field-wrapper_.color-input]:border-secondary-dark"
    ]
  end

  defp color_class("success") do
    [
      "[&_.color-field-wrapper_.color-input]:border-success-light",
      "dark:[&_.color-field-wrapper_.color-input]:border-success-dark"
    ]
  end

  defp color_class("warning") do
    [
      "[&_.color-field-wrapper_.color-input]:border-warning-light",
      "dark:[&_.color-field-wrapper_.color-input]:border-warning-dark"
    ]
  end

  defp color_class("danger") do
    [
      "[&_.color-field-wrapper_.color-input]:border-danger-light",
      "dark:[&_.color-field-wrapper_.color-input]:border-danger-dark"
    ]
  end

  defp color_class("info") do
    [
      "[&_.color-field-wrapper_.color-input]:border-info-light",
      "dark:[&_.color-field-wrapper_.color-input]:border-info-dark"
    ]
  end

  defp color_class("misc") do
    [
      "[&_.color-field-wrapper_.color-input]:border-misc-light",
      "dark:[&_.color-field-wrapper_.color-input]:border-misc-dark"
    ]
  end

  defp color_class("dawn") do
    [
      "[&_.color-field-wrapper_.color-input]:border-dawn-light",
      "dark:[&_.color-field-wrapper_.color-input]:border-dawn-dark"
    ]
  end

  defp color_class("silver") do
    [
      "[&_.color-field-wrapper_.color-input]:border-silver-light",
      "dark:[&_.color-field-wrapper_.color-input]:border-silver-dark"
    ]
  end

  defp color_class("dark") do
    [
      "[&_.color-field-wrapper_.color-input]:border-default-dark-bg"
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
