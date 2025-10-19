defmodule RadiatorWeb.Components.ToggleField do
  @moduledoc """
  RadiatorWeb.Components.ToggleField component renders a toggle field with customizable options.

  This module provides functionality for creating a toggle switch UI element
  that can be integrated into forms. It supports various attributes to tailor
  the appearance and behavior of the toggle, including size, color, and error handling.

  The toggle field includes support for accessibility features and can display
  error messages when validation fails. It is designed to be used within
  Phoenix LiveView applications, enabling dynamic interactions.

  **Documentation:** https://mishka.tools/chelekom/docs/forms/toggle
  """
  use Phoenix.Component
  alias Phoenix.HTML.Form
  import RadiatorWeb.Components.Icon, only: [icon: 1]

  @doc """
  The `toggle_field` component is a customizable toggle switch input, often used for binary on/off
  choices like enabling or disabling a feature.

  ## Examples

  ```elixir
  <.toggle_field id="name1" color="danger" label="This is label" />

  <.toggle_field id="name2" color="dark" label="This is label" size="extra_large"/>

  <.toggle_field id="name3" color="warning" label="This is label" size="extra_small" checked={true} />

  <.toggle_field id="name4" color="success" label="This is label" size="small"/>
  ```
  """
  @doc type: :component
  attr :id, :string,
    default: nil,
    doc: "A unique identifier is used to manage state and interaction"

  attr :class, :string, default: nil, doc: "Custom CSS class for additional styling"
  attr :color, :string, default: "primary", doc: "Determines color theme"
  attr :rounded, :string, default: "full", doc: "Determines border radius"
  attr :description, :string, default: nil, doc: "Determines a short description"
  attr :border, :string, default: "extra_small", doc: "Determines border style"
  attr :label_class, :string, default: nil, doc: "Determines the label class"
  attr :label_wrapper_class, :string, default: nil, doc: "Determines the label wrapper"
  attr :description_class, :string, default: nil, doc: "Determines the label description"
  attr :toggle_wrapper_class, :string, default: nil, doc: "Determines the toggle wrapper"

  attr :toggle_field_wrapper_class, :string,
    default: nil,
    doc: "Determines the toggle field wrapper"

  attr :toggle_base_class, :string, default: nil, doc: "Determines the toggle base"
  attr :toggle_circle_class, :string, default: nil, doc: "Determines the toggle circle"

  attr :size, :string,
    default: "medium",
    doc:
      "Determines the overall size of the elements, including padding, font size, and other items"

  attr :checked, :boolean, doc: "Determines if the toggle is initially checked"

  attr :ring, :boolean,
    default: true,
    doc:
      "Determines a ring border on focused input, utilities for creating outline rings with box-shadows."

  attr :reverse, :boolean, default: false, doc: "Switches the order of the element and label"
  attr :error_icon, :string, default: nil, doc: "Icon to be displayed alongside error messages"
  attr :label, :string, default: nil, doc: "Specifies text for the label"

  attr :errors, :list, default: [], doc: "List of error messages to be displayed"
  attr :name, :any, doc: "Name of input"
  attr :value, :any, default: nil

  attr :field, Phoenix.HTML.FormField, doc: "a form field struct retrieved from the form"

  attr :rest, :global,
    include: ~w(autocomplete disabled form indeterminate readonly required title autofocus),
    doc:
      "Global attributes can define defaults which are merged with attributes provided by the caller"

  @spec toggle_field(map()) :: Phoenix.LiveView.Rendered.t()
  def toggle_field(%{field: %Phoenix.HTML.FormField{} = field} = assigns) do
    errors = if Phoenix.Component.used_input?(field), do: field.errors, else: []

    assigns
    |> assign(field: nil, id: assigns.id || field.id)
    |> assign(:errors, Enum.map(errors, &translate_error(&1)))
    |> assign_new(:name, fn -> field.name end)
    |> assign_new(:value, fn -> field.value end)
    |> toggle_field()
  end

  def toggle_field(assigns) do
    assigns =
      assign_new(assigns, :checked, fn ->
        Phoenix.HTML.Form.normalize_value("checkbox", assigns[:value])
      end)

    ~H"""
    <div class={[
      size_class(@size),
      rounded_size(@rounded),
      @class
    ]}>
      <div class={@label_wrapper_class}>
        <.label :if={@label} for={@id} class={@label_class}>{@label}</.label>
        <div :if={!is_nil(@description)} class={@description_class}>
          {@description}
        </div>
      </div>
      <label
        for={@id}
        class={["flex items-center cursor-pointer select-none w-fit", @toggle_wrapper_class]}
      >
        <div class={["relative toggle-field-wrapper", @toggle_field_wrapper_class]}>
          <input type="hidden" name={@name} value="false" disabled={@rest[:disabled]} />
          <input
            type="checkbox"
            checked={@checked}
            id={@id}
            name={@name}
            value="true"
            class="peer sr-only"
            role="switch"
            aria-checked={to_string(@checked)}
            {@rest}
          />
          <div class={[
            "toggle-field-circle absolute transition-all ease-in-out duration-500 bg-white",
            "top-1 peer-checked:translate-x-full left-1",
            @toggle_circle_class
          ]}>
          </div>
          <div class={[
            "bg-default-light-gray dark:bg-natural-light transition-all ease-in-out duration-500 toggle-field-base",
            color_class(@color),
            @toggle_base_class
          ]}>
          </div>
        </div>
      </label>

      <.error :for={msg <- @errors} icon={@error_icon}>{msg}</.error>
    </div>
    """
  end

  def toggle_check(field, %{params: params, data: data} = _form) do
    if params[Atom.to_string(field)] do
      Form.normalize_value("checkbox", params[Atom.to_string(field)])
    else
      Map.get(data, field, false)
    end
  end

  @doc type: :component
  attr :for, :string, default: nil, doc: "Specifies the form which is associated with"
  attr :class, :string, default: nil, doc: "Custom CSS class for additional styling"
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

  defp rounded_size("extra_small"),
    do: "[&_.toggle-field-base]:rounded-sm [&_.toggle-field-circle]:rounded-sm"

  defp rounded_size("small"),
    do: "[&_.toggle-field-base]:rounded [&_.toggle-field-circle]:rounded"

  defp rounded_size("medium"),
    do: "[&_.toggle-field-base]:rounded-md [&_.toggle-field-circle]:rounded-md"

  defp rounded_size("large"),
    do: "[&_.toggle-field-base]:rounded-lg [&_.toggle-field-circle]:rounded-lg"

  defp rounded_size("extra_large"),
    do: "[&_.toggle-field-base]:rounded-xl [&_.toggle-field-circle]:rounded-xl"

  defp rounded_size("full"),
    do: "[&_.toggle-field-base]:rounded-full [&_.toggle-field-circle]:rounded-full"

  defp rounded_size(params) when is_binary(params), do: params

  defp size_class("extra_small") do
    [
      "[&_.toggle-field-base]:w-10 [&_.toggle-field-base]:h-6 [&_.toggle-field-circle]:size-4"
    ]
  end

  defp size_class("small") do
    [
      "[&_.toggle-field-base]:w-12 [&_.toggle-field-base]:h-7 [&_.toggle-field-circle]:size-5"
    ]
  end

  defp size_class("medium") do
    [
      "[&_.toggle-field-base]:w-14 [&_.toggle-field-base]:h-8 [&_.toggle-field-circle]:size-6"
    ]
  end

  defp size_class("large") do
    [
      "[&_.toggle-field-base]:w-16 [&_.toggle-field-base]:h-9 [&_.toggle-field-circle]:size-7"
    ]
  end

  defp size_class("extra_large") do
    [
      "[&_.toggle-field-base]:w-[72px] [&_.toggle-field-base]:h-10 [&_.toggle-field-circle]:size-8"
    ]
  end

  defp size_class(params) when is_binary(params), do: params

  defp color_class("base") do
    [
      "peer-checked:bg-base-border-light dark:peer-checked:bg-base-border-dark"
    ]
  end

  defp color_class("white") do
    [
      "peer-checked:bg-white"
    ]
  end

  defp color_class("natural") do
    [
      "peer-checked:bg-natural-light dark:peer-checked:bg-natural-dark"
    ]
  end

  defp color_class("primary") do
    [
      "peer-checked:bg-primary-light dark:peer-checked:bg-primary-dark"
    ]
  end

  defp color_class("secondary") do
    [
      "peer-checked:bg-secondary-light dark:peer-checked:bg-secondary-dark"
    ]
  end

  defp color_class("success") do
    [
      "peer-checked:bg-success-light dark:peer-checked:bg-success-dark"
    ]
  end

  defp color_class("warning") do
    [
      "peer-checked:bg-warning-light dark:peer-checked:bg-warning-dark"
    ]
  end

  defp color_class("danger") do
    [
      "peer-checked:bg-danger-light dark:peer-checked:bg-danger-dark"
    ]
  end

  defp color_class("info") do
    [
      "peer-checked:bg-info-light dark:peer-checked:bg-info-dark"
    ]
  end

  defp color_class("misc") do
    [
      "peer-checked:bg-misc-light dark:peer-checked:bg-misc-dark"
    ]
  end

  defp color_class("dawn") do
    [
      "peer-checked:bg-dawn-light dark:peer-checked:bg-dawn-dark"
    ]
  end

  defp color_class("silver") do
    [
      "peer-checked:bg-silver-light dark:peer-checked:bg-silver-dark"
    ]
  end

  defp color_class("dark") do
    [
      "peer-checked:bg-default-dark-bg"
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
