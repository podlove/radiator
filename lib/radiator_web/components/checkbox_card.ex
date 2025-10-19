defmodule RadiatorWeb.Components.CheckboxCard do
  @moduledoc """
  The `RadiatorWeb.Components.CheckboxCard` module provides a customizable checkbox card component for Phoenix LiveView
  applications. This component extends beyond basic checkbox buttons by offering a card-based interface
  with rich styling options.

  ## Key Features
  - Multiple visual variants: base, default, outline, shadow, and bordered
  - Comprehensive color themes including natural, primary, secondary, etc.
  - Customizable borders, padding, and spacing
  - Support for icons and descriptions within cards
  - Grid layout options for organizing multiple cards
  - Built-in dark mode support
  - Accessible form integration

  ## Example Usage
  ```heex
  <.checkbox_card name="plan" class="w-full" icon="hero-home">
    <:checkbox value="basic" title="Basic Plan" description="For small teams">
    </:checkbox>
    <:checkbox value="pro" title="Pro Plan" description="For growing businesses">
    </:checkbox>
    <:checkbox value="pro">
      <p>$25/month</p>
    </:checkbox>
  </.checkbox_card>
  ```

  The component handles form integration automatically when used with Phoenix.HTML.Form fields
  and includes built-in error handling and validation display.

  **Documentation:** https://mishka.tools/chelekom/docs/forms/checkbox-card
  """
  use Phoenix.Component
  alias Phoenix.HTML.Form
  import RadiatorWeb.Components.Icon, only: [icon: 1]

  @doc type: :component
  attr :id, :string,
    default: nil,
    doc: "A unique identifier is used to manage state and interaction"

  attr :class, :string, default: nil, doc: "Custom CSS class for additional styling"
  attr :color, :string, default: "natural", doc: "Determines color theme"
  attr :variant, :string, default: "base", doc: "Determines variant theme"
  attr :border, :string, default: "extra_small", doc: "Determines border style"
  attr :rounded, :string, default: "medium", doc: "Radius size"
  attr :padding, :string, default: "small", doc: "Padding size"
  attr :space, :string, default: "small", doc: "Determines space between elements"
  attr :cols, :string, default: "one", doc: "Determines cols of elements"
  attr :cols_gap, :string, default: "small", doc: "Determines gap between elements"
  attr :label_class, :string, default: nil, doc: "Custom CSS class for the label styling"
  attr :reverse, :boolean, default: false, doc: "Switches the order of the element and label"
  attr :show_checkbox, :boolean, default: false, doc: "Boolean to show and hide checkbox"
  attr :label, :string, default: nil, doc: "Specifies text for the label"
  attr :description, :string, default: nil, doc: "Determines a short description"
  attr :error_icon_class, :string, default: nil, doc: "Custom classes for error Icon"
  attr :content_wrapper_class, :string, default: nil, doc: "Custom classes for content wrapper"

  attr :description_wrapper_class, :string,
    default: nil,
    doc: "Custom classes for description wrapper"

  attr :description_class, :string, default: nil, doc: "Custom classes for description"

  attr :checkbox_wrapper_class, :string,
    default: nil,
    doc: "Custom classes for checkbox main wrapper"

  attr :size, :string,
    default: "small",
    doc:
      "Determines the overall size of the elements, including padding, font size, and other items"

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

  slot :checkbox, required: true do
    attr :value, :string, required: true
    attr :checked, :boolean, required: false
    attr :icon, :string, doc: "Icon displayed alongside of a checkbox"
    attr :icon_class, :string, doc: "Determines custom class for the icon"
    attr :content_class, :string, doc: "Determines custom class for the content"
    attr :description_class, :string, doc: "Determines custom class for the description"
    attr :title_class, :string, doc: "Determines custom class for the title"
    attr :card_content_class, :string, doc: "Determines custom class for the card content"
    attr :title, :string, required: false
    attr :description, :string, required: false
  end

  slot :inner_block

  @spec checkbox_card(map()) :: Phoenix.LiveView.Rendered.t()
  def checkbox_card(%{field: %Phoenix.HTML.FormField{} = field} = assigns) do
    errors = if Phoenix.Component.used_input?(field), do: field.errors, else: []

    assigns
    |> assign(field: nil)
    |> assign(id: assigns.id || field.id)
    |> assign(:errors, Enum.map(errors, &translate_error(&1)))
    |> assign_new(:name, fn -> field.name <> "[]" end)
    |> assign_new(:value, fn -> field.value end)
    |> assign(:multiple, true)
    |> checkbox_card()
  end

  def checkbox_card(assigns) do
    ~H"""
    <div class={["leading-5", space_class(@space)]}>
      <input type="hidden" name={@name} value="" disabled={@rest[:disabled]} />

      <div
        :if={@label || @description}
        class={["checkbox-card-label-wrapper", @description_wrapper_class]}
      >
        <.label :if={@label} for={@id} class={@label_class}>{@label}</.label>
        <div :if={@description} class={["text-[12px]", @description_class]}>
          {@description}
        </div>
      </div>

      <div class={["grid", grid_cols(@cols), grid_gap(@cols_gap), @class]}>
        <label
          :for={{checkbox, index} <- Enum.with_index(@checkbox, 1)}
          for={"#{@id}-#{index}"}
          aria-checked={(checkbox[:checked] && "true") || "false"}
          aria-labelledby={"#{@id}-#{index}-label"}
          class={[
            "checkbox-card-wrapper flex items-start cursor-pointer",
            "has-[:disabled]:pointer-events-none has-[:disabled]:opacity-50",
            "has-[:focus-visible]:outline has-[:focus-visible]:outline-2 has-[:focus-visible]:outline-blue-400",
            "has-[:focus-visible]:outline-offset-[-2px] transition-all",
            @reverse && "flex-row-reverse",
            border_class(@border, @variant),
            color_variant(@variant, @color),
            rounded_size(@rounded),
            padding_size(@padding),
            size_class(@size),
            @checkbox_wrapper_class
          ]}
          {@rest}
        >
          <input
            type="checkbox"
            name={@name}
            id={"#{@id}-#{index}"}
            value={checkbox[:value]}
            checked={checkbox[:checked]}
            aria-describedby={"#{@id}-#{index}-description"}
            class={[
              "checkbox-card-input shrink-0 focus:ring-0 focus:ring-offset-0 appearance-none rounded-sm",
              "cursor-pointer disabled:opacity-50",
              !@show_checkbox && "opacity-0 absolute"
            ]}
          />
          <div
            data-part="label"
            class={["checkbox-card-content-wrapper flex-1", @content_wrapper_class]}
          >
            <div
              :if={!is_nil(checkbox[:icon]) || checkbox[:title] || checkbox[:description]}
              class={["checkbox-slot-content flex flex-col", checkbox[:content_class]]}
            >
              <.icon
                :if={!is_nil(checkbox[:icon])}
                name={checkbox[:icon]}
                class={["block mx-auto", checkbox[:icon_class]]}
              />
              <div
                :if={checkbox[:title]}
                class={[
                  "block checkbox-card-title leading-[16px] font-semibold",
                  checkbox[:title_class]
                ]}
              >
                {checkbox[:title]}
              </div>

              <p
                :if={checkbox[:description]}
                class={["checkbox-card-description", checkbox[:description_class]]}
              >
                {checkbox[:description]}
              </p>
            </div>
            <div class={["checkbox-card-content leading-[17px]", checkbox[:card_content_class]]}>
              {render_slot(checkbox)}
            </div>
          </div>
        </label>
      </div>
    </div>

    <.error :for={msg <- @errors} icon={@error_icon} icon_class={@error_icon_class}>{msg}</.error>
    """
  end

  def checkbox_card_check(:list, {field, value}, %{params: params, data: data} = _form) do
    if params[Atom.to_string(field)] do
      new_value = if is_atom(value), do: Atom.to_string(value), else: value
      new_value in params[Atom.to_string(field)]
    else
      Map.get(data, field) == value
    end
  end

  def checkbox_card_check(:boolean, field, %{params: params, data: data} = _form) do
    if params[Atom.to_string(field)] do
      Form.normalize_value("checkbox", params[Atom.to_string(field)])
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
    <label for={@for} class={["leading-4 font-semibold", @class]}>
      {render_slot(@inner_block)}
    </label>
    """
  end

  @doc type: :component
  attr :icon, :string, default: nil, doc: "Icon displayed alongside of an item"
  attr :icon_class, :string, default: nil, doc: "Custom classes for error Icon"
  slot :inner_block, required: true, doc: "Inner block that renders HEEx content"

  defp error(assigns) do
    ~H"""
    <p class="mt-3 flex items-center gap-3 text-[14px] text-rose-700">
      <.icon :if={!is_nil(@icon)} name={@icon} class={["shrink-0", @error_icon_class]} /> {render_slot(
        @inner_block
      )}
    </p>
    """
  end

  defp border_class(_, variant) when variant in ["default", "shadow"],
    do: nil

  defp border_class("none", _), do: nil
  defp border_class("extra_small", _), do: "border"
  defp border_class("small", _), do: "border-2"
  defp border_class("medium", _), do: "border-[3px]"
  defp border_class("large", _), do: "border-4"
  defp border_class("extra_large", _), do: "border-[5px]"
  defp border_class(params, _) when is_binary(params), do: params

  defp rounded_size("extra_small"), do: "rounded-sm"

  defp rounded_size("small"), do: "rounded"

  defp rounded_size("medium"), do: "rounded-md"

  defp rounded_size("large"), do: "rounded-lg"

  defp rounded_size("extra_large"), do: "rounded-xl"

  defp rounded_size("none"), do: nil

  defp rounded_size(params) when is_binary(params), do: params

  defp padding_size("extra_small"), do: "py-1 px-2"

  defp padding_size("small"), do: "py-2 px-3"

  defp padding_size("medium"), do: "py-3 px-4"

  defp padding_size("large"), do: "py-4 px-5"

  defp padding_size("extra_large"), do: "py-5 px-6"

  defp padding_size(params) when is_binary(params), do: params

  defp grid_cols("one"), do: "grid-cols-1"
  defp grid_cols("two"), do: "grid-cols-2"
  defp grid_cols("three"), do: "grid-cols-2 md:grid-cols-3"
  defp grid_cols("four"), do: "grid-cols-2 md:grid-cols-4"
  defp grid_cols("five"), do: "grid-cols-2 md:grid-cols-5"
  defp grid_cols("six"), do: "grid-cols-2 md:grid-cols-6"
  defp grid_cols("seven"), do: "grid-cols-2 md:grid-cols-7"
  defp grid_cols("eight"), do: "grid-cols-2 md:grid-cols-8"
  defp grid_cols("nine"), do: "grid-cols-2 md:grid-cols-9"
  defp grid_cols("ten"), do: "grid-cols-2 md:grid-cols-10"
  defp grid_cols("eleven"), do: "grid-cols-2 md:grid-cols-11"
  defp grid_cols("twelve"), do: "grid-cols-2 md:grid-cols-12"
  defp grid_cols(params) when is_binary(params), do: params

  defp grid_gap("extra_small"), do: "gap-1"
  defp grid_gap("small"), do: "gap-2"
  defp grid_gap("medium"), do: "gap-3"
  defp grid_gap("large"), do: "gap-4"
  defp grid_gap("extra_large"), do: "gap-5"
  defp grid_gap(params) when is_binary(params), do: params

  defp size_class("extra_small") do
    [
      "text-[13px]",
      "[&_.checkbox-card-icon]:size-5",
      "[&_.checkbox-card-description]:text-[11px]"
    ]
  end

  defp size_class("small") do
    [
      "text-[14px]",
      "[&_.checkbox-card-icon]:size-6",
      "[&_.checkbox-card-description]:text-[12px]"
    ]
  end

  defp size_class("medium") do
    [
      "text-[15px]",
      "[&_.checkbox-card-icon]:size-7",
      "[&_.checkbox-card-description]:text-[13px]"
    ]
  end

  defp size_class("large") do
    [
      "text-[16px]",
      "[&_.checkbox-card-icon]:size-8",
      "[&_.checkbox-card-description]:text-[14px]"
    ]
  end

  defp size_class("extra_large") do
    [
      "text-[17px]",
      "[&_.checkbox-card-icon]:size-9",
      "[&_.checkbox-card-description]:text-[15px]"
    ]
  end

  defp size_class(params) when is_binary(params), do: params

  defp space_class("extra_small") do
    [
      "[&_.checkbox-card-label-wrapper]:space-y-1",
      "[&_.checkbox-card-label-wrapper]:mb-1",
      "[&_.checkbox-card-wrapper]:gap-1 [&_.checkbox-slot-content]:gap-1"
    ]
  end

  defp space_class("small") do
    [
      "[&_.checkbox-card-label-wrapper]:space-y-1.5",
      "[&_.checkbox-card-label-wrapper]:mb-2",
      "[&_.checkbox-card-wrapper]:gap-2 [&_.checkbox-slot-content]:gap-2"
    ]
  end

  defp space_class("medium") do
    [
      "[&_.checkbox-card-label-wrapper]:space-y-2",
      "[&_.checkbox-card-label-wrapper]:mb-3",
      "[&_.checkbox-card-wrapper]:gap-3 [&_.checkbox-slot-content]:gap-3"
    ]
  end

  defp space_class("large") do
    [
      "[&_.checkbox-card-label-wrapper]:space-y-2.5",
      "[&_.checkbox-card-label-wrapper]:mb-4",
      "[&_.checkbox-card-wrapper]:gap-4 [&_.checkbox-slot-content]:gap-4"
    ]
  end

  defp space_class("extra_large") do
    [
      "[&_.checkbox-card-label-wrapper]:space-y-3",
      "[&_.checkbox-card-label-wrapper]:mb-5",
      "[&_.checkbox-card-wrapper]:gap-5 [&_.checkbox-slot-content]:gap-5"
    ]
  end

  defp space_class("none"), do: nil

  defp space_class(params) when is_binary(params), do: params

  defp color_variant("base", _) do
    [
      "bg-white text-base-text-light border-base-border-light shadow-sm",
      "dark:bg-base-bg-dark dark:text-base-text-dark dark:border-base-border-dark",
      "checked:[&_.checkbox-card-input]:text-base-text-light",
      "dark:checked:[&_.checkbox-card-input]:text-base-disabled-text-dark",
      "[&_.checkbox-card-input]:border-base-border-light dark:[&_.checkbox-card-input]:border-base-border-dark",
      "[&_.checkbox-card-input:checked]:border-base-text-light dark:[&_.checkbox-card-input:checked]:border-base-border-dark",
      "has-[:checked]:bg-base-hover-light dark:has-[:checked]:bg-base-hover-dark",
      "has-[:checked]:border-base-text-light dark:has-[:checked]:border-base-disabled-text-dark",
      "[&_.checkbox-card-input:not(:checked)]:bg-white dark:[&_.checkbox-card-input:not(:checked)]:bg-checkbox-unchecked-dark"
    ]
  end

  defp color_variant("default", "white") do
    [
      "bg-white text-black",
      "checked:[&_.checkbox-card-input]:text-black",
      "[&_.checkbox-card-input]:border-black",
      "has-[:checked]:bg-checkbox-white-checked"
    ]
  end

  defp color_variant("default", "dark") do
    [
      "bg-default-dark-bg text-white",
      "checked:[&_.checkbox-card-input]:text-white",
      "[&_.checkbox-card-input]:border-white",
      "has-[:checked]:bg-checkbox-dark-checked"
    ]
  end

  defp color_variant("default", "natural") do
    [
      "bg-natural-bg-dark text-white dark:bg-natural-dark dark:text-black",
      "checked:[&_.checkbox-card-input]:text-silver-indicator-alt-light",
      "dark:checked:[&_.checkbox-card-input]:text-silver-hover-dark",
      "[&_.checkbox-card-input]:border-base-border-light dark:[&_.checkbox-card-input]:border-base-border-dark",
      "has-[:checked]:bg-natural-hover-light dark:has-[:checked]:bg-natural-border-dark"
    ]
  end

  defp color_variant("default", "primary") do
    [
      "bg-primary-light text-white dark:bg-primary-dark dark:text-black",
      "checked:[&_.checkbox-card-input]:text-checkbox-primary-checked",
      "[&_.checkbox-card-input]:border-checkbox-primary-checked",
      "has-[:checked]:bg-primary-hover-light dark:has-[:checked]:bg-primary-hover-dark"
    ]
  end

  defp color_variant("default", "secondary") do
    [
      "bg-secondary-light text-white dark:bg-secondary-dark dark:text-black",
      "checked:[&_.checkbox-card-input]:text-checkbox-secondary-checked",
      "[&_.checkbox-card-input]:border-checkbox-secondary-checked",
      "has-[:checked]:bg-secondary-hover-light dark:has-[:checked]:bg-primary-hover-dark"
    ]
  end

  defp color_variant("default", "success") do
    [
      "bg-success-light text-white dark:bg-success-dark dark:text-black",
      "checked:[&_.checkbox-card-input]:text-checkbox-success-checked",
      "[&_.checkbox-card-input]:border-checkbox-success-checked",
      "has-[:checked]:bg-success-hover-light dark:has-[:checked]:bg-success-hover-dark"
    ]
  end

  defp color_variant("default", "warning") do
    [
      "bg-warning-light text-white dark:bg-warning-dark dark:text-black",
      "checked:[&_.checkbox-card-input]:text-checkbox-warning-checked",
      "[&_.checkbox-card-input]:border-checkbox-warning-checked",
      "has-[:checked]:bg-warning-hover-light dark:has-[:checked]:bg-warning-hover-dark"
    ]
  end

  defp color_variant("default", "danger") do
    [
      "bg-danger-light text-white dark:bg-danger-dark dark:text-black",
      "checked:[&_.checkbox-card-input]:text-checkbox-danger-checked",
      "[&_.checkbox-card-input]:border-checkbox-danger-checked",
      "has-[:checked]:bg-danger-hover-light dark:has-[:checked]:bg-danger-hover-dark"
    ]
  end

  defp color_variant("default", "info") do
    [
      "bg-info-light text-white dark:bg-info-dark dark:text-black",
      "checked:[&_.checkbox-card-input]:text-checkbox-info-checked",
      "[&_.checkbox-card-input]:border-checkbox-info-checked",
      "has-[:checked]:bg-info-hover-light dark:has-[:checked]:bg-info-hover-dark"
    ]
  end

  defp color_variant("default", "misc") do
    [
      "bg-misc-light text-white dark:bg-misc-dark dark:text-black",
      "checked:[&_.checkbox-card-input]:text-checkbox-misc-checked",
      "[&_.checkbox-card-input]:border-checkbox-misc-checked",
      "has-[:checked]:bg-misc-hover-light dark:has-[:checked]:bg-misc-hover-dark"
    ]
  end

  defp color_variant("default", "dawn") do
    [
      "bg-dawn-light text-white dark:bg-dawn-dark dark:text-black",
      "checked:[&_.checkbox-card-input]:text-checkbox-dawn-checked",
      "[&_.checkbox-card-input]:border-checkbox-dawn-checked",
      "has-[:checked]:bg-dawn-hover-light dark:has-[:checked]:bg-dawn-hover-dark"
    ]
  end

  defp color_variant("default", "silver") do
    [
      "bg-silver-light text-white dark:bg-silver-dark dark:text-black",
      "checked:[&_.checkbox-card-input]:text-silver-dark",
      "[&_.checkbox-card-input]:border-silver-dark",
      "has-[:checked]:bg-silver-hover-light dark:has-[:checked]:bg-silver-hover-dark"
    ]
  end

  defp color_variant("outline", "natural") do
    [
      "text-natural-light border-natural-light dark:text-natural-dark dark:border-natural-dark",
      "checked:[&_.checkbox-card-input]:text-natural-dark",
      "[&_.checkbox-card-input]:border-natural-dark",
      "dark:checked:[&_.checkbox-card-input]:text-natural-light",
      "dark:[&_.checkbox-card-input]:border-natural-light",
      "has-[:checked]:border-black dark:has-[:checked]:border-white"
    ]
  end

  defp color_variant("outline", "primary") do
    [
      "text-primary-light border-primary-light dark:text-primary-dark dark:border-primary-dark",
      "checked:[&_.checkbox-card-input]:text-primary-light",
      "[&_.checkbox-card-input]:border-primary-light",
      "dark:checked:[&_.checkbox-card-input]:text-primary-dark",
      "dark:[&_.checkbox-card-input]:border-primary-dark",
      "has-[:checked]:border-primary-indicator-light dark:has-[:checked]:border-primary-indicator-dark"
    ]
  end

  defp color_variant("outline", "secondary") do
    [
      "text-secondary-light border-secondary-light dark:text-secondary-dark dark:border-secondary-dark",
      "checked:[&_.checkbox-card-input]:text-secondary-light",
      "[&_.checkbox-card-input]:border-secondary-light",
      "dark:checked:[&_.checkbox-card-input]:text-secondary-dark",
      "dark:[&_.checkbox-card-input]:border-secondary-dark",
      "has-[:checked]:border-secondary-indicator-light dark:has-[:checked]:border-secondary-indicator-dark"
    ]
  end

  defp color_variant("outline", "success") do
    [
      "text-success-light border-success-light dark:text-success-dark dark:border-success-dark",
      "checked:[&_.checkbox-card-input]:text-success-light",
      "[&_.checkbox-card-input]:border-success-light",
      "dark:checked:[&_.checkbox-card-input]:text-success-dark",
      "dark:[&_.checkbox-card-input]:border-success-dark",
      "has-[:checked]:border-success-indicator-alt-light dark:has-[:checked]:border-success-indicator-dark"
    ]
  end

  defp color_variant("outline", "warning") do
    [
      "text-warning-light border-warning-light dark:text-warning-dark dark:border-warning-dark",
      "checked:[&_.checkbox-card-input]:text-warning-light",
      "[&_.checkbox-card-input]:border-warning-light",
      "dark:checked:[&_.checkbox-card-input]:text-warning-dark",
      "dark:[&_.checkbox-card-input]:border-warning-dark",
      "has-[:checked]:border-warning-indicator-alt-light dark:has-[:checked]:border-warning-indicator-dark"
    ]
  end

  defp color_variant("outline", "danger") do
    [
      "text-danger-light border-danger-light dark:text-danger-dark dark:border-danger-dark",
      "checked:[&_.checkbox-card-input]:text-danger-light",
      "[&_.checkbox-card-input]:border-danger-light",
      "dark:checked:[&_.checkbox-card-input]:text-danger-dark",
      "dark:[&_.checkbox-card-input]:border-danger-dark",
      "has-[:checked]:border-danger-indicator-alt-light dark:has-[:checked]:border-danger-indicator-dark"
    ]
  end

  defp color_variant("outline", "info") do
    [
      "text-info-light border-info-light dark:text-info-dark dark:border-info-dark",
      "checked:[&_.checkbox-card-input]:text-info-light",
      "[&_.checkbox-card-input]:border-info-light",
      "dark:checked:[&_.checkbox-card-input]:text-info-dark",
      "dark:[&_.checkbox-card-input]:border-info-dark",
      "has-[:checked]:border-info-indicator-alt-light dark:has-[:checked]:border-info-indicator-dark"
    ]
  end

  defp color_variant("outline", "misc") do
    [
      "text-misc-light border-misc-light dark:text-misc-dark dark:border-misc-dark",
      "checked:[&_.checkbox-card-input]:text-misc-light",
      "[&_.checkbox-card-input]:border-misc-light",
      "dark:checked:[&_.checkbox-card-input]:text-misc-dark",
      "dark:[&_.checkbox-card-input]:border-misc-dark",
      "has-[:checked]:border-misc-indicator-alt-light dark:has-[:checked]:border-misc-indicator-dark"
    ]
  end

  defp color_variant("outline", "dawn") do
    [
      "text-dawn-light border-dawn-light dark:text-dawn-dark dark:border-dawn-dark",
      "checked:[&_.checkbox-card-input]:text-dawn-light",
      "[&_.checkbox-card-input]:border-dawn-light",
      "dark:checked:[&_.checkbox-card-input]:text-dawn-dark",
      "dark:[&_.checkbox-card-input]:border-dawn-dark",
      "has-[:checked]:border-dawn-indicator-alt-light dark:has-[:checked]:border-dawn-indicator-dark"
    ]
  end

  defp color_variant("outline", "silver") do
    [
      "text-silver-light border-silver-light dark:text-silver-dark dark:border-silver-dark",
      "checked:[&_.checkbox-card-input]:text-silver-light",
      "[&_.checkbox-card-input]:border-silver-light",
      "dark:checked:[&_.checkbox-card-input]:text-silver-dark",
      "dark:[&_.checkbox-card-input]:border-silver-dark",
      "has-[:checked]:border-silver-indicator-alt-light dark:has-[:checked]:border-silver-indicator-dark"
    ]
  end

  defp color_variant("shadow", "natural") do
    [
      "bg-natural-bg-dark text-white dark:bg-natural-dark dark:text-black",
      "shadow-[0px_4px_6px_-4px_var(--color-shadow-natural)] shadow-[0px_10px_15px_-3px_var(--color-shadow-natural)] dark:shadow-none",
      "checked:[&_.checkbox-card-input]:text-silver-indicator-alt-light",
      "dark:checked:[&_.checkbox-card-input]:text-silver-hover-dark",
      "[&_.checkbox-card-input]:border-base-border-light dark:[&_.checkbox-card-input]:border-base-border-dark",
      "has-[:checked]:bg-natural-hover-light dark:has-[:checked]:bg-natural-border-dark"
    ]
  end

  defp color_variant("shadow", "primary") do
    [
      "bg-primary-light text-white dark:bg-primary-dark dark:text-black",
      "shadow-[0px_4px_6px_-4px_var(--color-shadow-primary)] shadow-[0px_10px_15px_-3px_var(--color-shadow-primary)] dark:shadow-none",
      "checked:[&_.checkbox-card-input]:text-checkbox-primary-checked",
      "[&_.checkbox-card-input]:border-checkbox-primary-checked",
      "has-[:checked]:bg-primary-hover-light dark:has-[:checked]:bg-primary-hover-dark"
    ]
  end

  defp color_variant("shadow", "secondary") do
    [
      "bg-secondary-light text-white dark:bg-secondary-dark dark:text-black",
      "shadow-[0px_4px_6px_-4px_var(--color-shadow-secondary)] shadow-[0px_10px_15px_-3px_var(--color-shadow-secondary)] dark:shadow-none",
      "checked:[&_.checkbox-card-input]:text-checkbox-secondary-checked",
      "[&_.checkbox-card-input]:border-checkbox-secondary-checked",
      "has-[:checked]:bg-secondary-hover-light dark:has-[:checked]:bg-primary-hover-dark"
    ]
  end

  defp color_variant("shadow", "success") do
    [
      "bg-success-light text-white dark:bg-success-dark dark:text-black",
      "shadow-[0px_4px_6px_-4px_var(--color-shadow-success)] shadow-[0px_10px_15px_-3px_var(--color-shadow-success)] dark:shadow-none",
      "checked:[&_.checkbox-card-input]:text-checkbox-success-checked",
      "[&_.checkbox-card-input]:border-checkbox-success-checked",
      "has-[:checked]:bg-success-hover-light dark:has-[:checked]:bg-success-hover-dark"
    ]
  end

  defp color_variant("shadow", "warning") do
    [
      "bg-warning-light text-white dark:bg-warning-dark dark:text-black",
      "shadow-[0px_4px_6px_-4px_var(--color-shadow-warning)] shadow-[0px_10px_15px_-3px_var(--color-shadow-warning)] dark:shadow-none",
      "checked:[&_.checkbox-card-input]:text-checkbox-warning-checked",
      "[&_.checkbox-card-input]:border-checkbox-warning-checked",
      "has-[:checked]:bg-warning-hover-light dark:has-[:checked]:bg-warning-hover-dark"
    ]
  end

  defp color_variant("shadow", "danger") do
    [
      "bg-danger-light text-white dark:bg-danger-dark dark:text-black",
      "shadow-[0px_4px_6px_-4px_var(--color-shadow-danger)] shadow-[0px_10px_15px_-3px_var(--color-shadow-danger)] dark:shadow-none",
      "checked:[&_.checkbox-card-input]:text-checkbox-danger-checked",
      "[&_.checkbox-card-input]:border-checkbox-danger-checked",
      "has-[:checked]:bg-danger-hover-light dark:has-[:checked]:bg-danger-hover-dark"
    ]
  end

  defp color_variant("shadow", "info") do
    [
      "bg-info-light text-white dark:bg-info-dark dark:text-black",
      "shadow-[0px_4px_6px_-4px_var(--color-shadow-info)] shadow-[0px_10px_15px_-3px_var(--color-shadow-info)] dark:shadow-none",
      "checked:[&_.checkbox-card-input]:text-checkbox-info-checked",
      "[&_.checkbox-card-input]:border-checkbox-info-checked",
      "has-[:checked]:bg-info-hover-light dark:has-[:checked]:bg-info-hover-dark"
    ]
  end

  defp color_variant("shadow", "misc") do
    [
      "bg-misc-light text-white dark:bg-misc-dark dark:text-black",
      "shadow-[0px_4px_6px_-4px_var(--color-shadow-misc)] shadow-[0px_10px_15px_-3px_var(--color-shadow-misc)] dark:shadow-none",
      "checked:[&_.checkbox-card-input]:text-checkbox-misc-checked",
      "[&_.checkbox-card-input]:border-checkbox-misc-checked",
      "has-[:checked]:bg-misc-hover-light dark:has-[:checked]:bg-misc-hover-dark"
    ]
  end

  defp color_variant("shadow", "dawn") do
    [
      "bg-dawn-light text-white dark:bg-dawn-dark dark:text-black",
      "shadow-[0px_4px_6px_-4px_var(--color-shadow-dawn)] shadow-[0px_10px_15px_-3px_var(--color-shadow-dawn)] dark:shadow-none",
      "checked:[&_.checkbox-card-input]:text-checkbox-dawn-checked",
      "[&_.checkbox-card-input]:border-checkbox-dawn-checked",
      "has-[:checked]:bg-dawn-hover-light dark:has-[:checked]:bg-dawn-hover-dark"
    ]
  end

  defp color_variant("shadow", "silver") do
    [
      "bg-silver-light text-white dark:bg-silver-dark dark:text-black",
      "shadow-[0px_4px_6px_-4px_var(--color-shadow-silver)] shadow-[0px_10px_15px_-3px_var(--color-shadow-silver)] dark:shadow-none",
      "checked:[&_.checkbox-card-input]:text-silver-dark",
      "[&_.checkbox-card-input]:border-silver-dark",
      "has-[:checked]:bg-silver-hover-light dark:has-[:checked]:bg-silver-hover-dark"
    ]
  end

  defp color_variant("bordered", "white") do
    [
      "bg-white text-black border-bordered-white-border",
      "checked:[&_.checkbox-card-input]:text-black",
      "[&_.checkbox-card-input]:border-black",
      "has-[:checked]:bg-checkbox-white-checked"
    ]
  end

  defp color_variant("bordered", "dark") do
    [
      "bg-bordered-dark-bg text-white border-bordered-dark-border",
      "checked:[&_.checkbox-card-input]:text-white",
      "[&_.checkbox-card-input]:border-white",
      "has-[:checked]:bg-checkbox-dark-checked"
    ]
  end

  defp color_variant("bordered", "natural") do
    [
      "text-natural-bordered-text-light border-natural-border-light bg-natural-bordered-bg-light",
      "dark:text-natural-bordered-text-dark dark:border-natural-border-dark dark:bg-natural-bordered-bg-dark",
      "checked:[&_.checkbox-card-input]:text-black",
      "dark:checked:[&_.checkbox-card-input]:text-white",
      "[&_.checkbox-card-input]:border-natural-border-light dark:[&_.checkbox-card-input]:border-natural-border-dark",
      "has-[:checked]:border-black dark:has-[:checked]:border-white",
      "has-[:checked]:bg-natural-border-dark dark:has-[:checked]:bg-silver-indicator-alt-light"
    ]
  end

  defp color_variant("bordered", "primary") do
    [
      "text-primary-bordered-text-light border-primary-bordered-text-light bg-primary-bordered-bg-light",
      "dark:text-primary-bordered-text-dark dark:border-primary-bordered-text-dark dark:bg-primary-bordered-bg-dark",
      "checked:[&_.checkbox-card-input]:text-primary-bordered-text-light",
      "dark:checked:[&_.checkbox-card-input]:text-primary-bordered-text-dark",
      "[&_.checkbox-card-input]:border-primary-bordered-text-light dark:[&_.checkbox-card-input]:border-primary-bordered-text-dark",
      "has-[:checked]:border-primary-indicator-light dark:has-[:checked]:border-primary-indicator-dark",
      "has-[:checked]:bg-primary-gradient-indicator-dark dark:has-[:checked]:bg-primary-indicator-light"
    ]
  end

  defp color_variant("bordered", "secondary") do
    [
      "text-secondary-bordered-text-light border-secondary-bordered-text-light bg-secondary-bordered-bg-light",
      "dark:text-secondary-bordered-text-dark dark:border-secondary-bordered-text-dark dark:bg-secondary-bordered-bg-dark",
      "checked:[&_.checkbox-card-input]:text-secondary-bordered-text-light",
      "dark:checked:[&_.checkbox-card-input]:text-secondary-bordered-text-dark",
      "[&_.checkbox-card-input]:border-secondary-bordered-text-light dark:[&_.checkbox-card-input]:border-secondary-bordered-text-dark",
      "has-[:checked]:border-secondary-indicator-light dark:has-[:checked]:border-secondary-indicator-dark",
      "has-[:checked]:bg-secondary-gradient-indicator-dark dark:has-[:checked]:bg-secondary-indicator-light"
    ]
  end

  defp color_variant("bordered", "success") do
    [
      "text-success-bordered-text-light border-success-bordered-text-light bg-success-bordered-bg-light",
      "dark:text-success-bordered-text-dark dark:border-success-bordered-text-dark dark:bg-success-bordered-bg-dark",
      "checked:[&_.checkbox-card-input]:text-success-bordered-text-light",
      "dark:checked:[&_.checkbox-card-input]:text-success-bordered-text-dark",
      "[&_.checkbox-card-input]:border-success-bordered-text-light dark:[&_.checkbox-card-input]:border-success-bordered-text-dark",
      "has-[:checked]:border-success-indicator-alt-light dark:has-[:checked]:border-success-indicator-dark",
      "has-[:checked]:bg-success-gradient-indicator-dark dark:has-[:checked]:bg-success-indicator-alt-light"
    ]
  end

  defp color_variant("bordered", "warning") do
    [
      "text-warning-bordered-text-light border-warning-bordered-text-light bg-warning-bordered-bg-light",
      "dark:text-warning-bordered-text-dark dark:border-warning-bordered-text-dark dark:bg-warning-bordered-bg-dark",
      "checked:[&_.checkbox-card-input]:text-warning-bordered-text-light",
      "dark:checked:[&_.checkbox-card-input]:text-warning-bordered-text-dark",
      "[&_.checkbox-card-input]:border-warning-bordered-text-light dark:[&_.checkbox-card-input]:border-warning-bordered-text-dark",
      "has-[:checked]:border-warning-indicator-alt-light dark:has-[:checked]:border-warning-indicator-dark",
      "has-[:checked]:bg-warning-gradient-indicator-dark dark:has-[:checked]:bg-warning-indicator-alt-light"
    ]
  end

  defp color_variant("bordered", "danger") do
    [
      "text-danger-bordered-text-light border-danger-bordered-text-light bg-danger-bordered-bg-light",
      "dark:text-danger-bordered-text-dark dark:border-danger-bordered-text-dark dark:bg-danger-bordered-bg-dark",
      "checked:[&_.checkbox-card-input]:text-danger-bordered-text-light",
      "dark:checked:[&_.checkbox-card-input]:text-danger-bordered-text-dark",
      "[&_.checkbox-card-input]:border-danger-bordered-text-light dark:[&_.checkbox-card-input]:border-danger-bordered-text-dark",
      "has-[:checked]:border-danger-indicator-alt-light dark:has-[:checked]:border-danger-indicator-dark",
      "has-[:checked]:bg-danger-gradient-indicator-dark dark:has-[:checked]:bg-danger-indicator-alt-light"
    ]
  end

  defp color_variant("bordered", "info") do
    [
      "text-info-bordered-text-light border-info-bordered-text-light bg-info-bordered-bg-light",
      "dark:text-info-bordered-text-dark dark:border-info-bordered-text-dark dark:bg-info-bordered-bg-dark",
      "checked:[&_.checkbox-card-input]:text-info-bordered-text-light",
      "dark:checked:[&_.checkbox-card-input]:text-info-bordered-text-dark",
      "[&_.checkbox-card-input]:border-info-bordered-text-light dark:[&_.checkbox-card-input]:border-info-bordered-text-dark",
      "has-[:checked]:border-info-indicator-alt-light dark:has-[:checked]:border-info-indicator-dark",
      "has-[:checked]:bg-info-gradient-indicator-dark dark:has-[:checked]:bg-info-indicator-alt-light"
    ]
  end

  defp color_variant("bordered", "misc") do
    [
      "text-misc-bordered-text-light border-misc-bordered-text-light bg-misc-bordered-bg-light",
      "dark:text-misc-bordered-text-dark dark:border-misc-bordered-text-dark dark:bg-misc-bordered-bg-dark",
      "checked:[&_.checkbox-card-input]:text-misc-bordered-text-light",
      "dark:checked:[&_.checkbox-card-input]:text-misc-bordered-text-dark",
      "[&_.checkbox-card-input]:border-misc-bordered-text-light dark:[&_.checkbox-card-input]:border-misc-bordered-text-dark",
      "has-[:checked]:border-misc-indicator-alt-light dark:has-[:checked]:border-misc-indicator-dark",
      "has-[:checked]:bg-misc-gradient-indicator-dark dark:has-[:checked]:bg-misc-indicator-alt-light"
    ]
  end

  defp color_variant("bordered", "dawn") do
    [
      "text-dawn-bordered-text-light border-dawn-bordered-text-light bg-dawn-bordered-bg-light",
      "dark:text-dawn-bordered-text-dark dark:border-dawn-bordered-text-dark dark:bg-dawn-bordered-bg-dark",
      "checked:[&_.checkbox-card-input]:text-dawn-bordered-text-light",
      "dark:checked:[&_.checkbox-card-input]:text-dawn-bordered-text-dark",
      "[&_.checkbox-card-input]:border-dawn-bordered-text-light dark:[&_.checkbox-card-input]:border-dawn-bordered-text-dark",
      "has-[:checked]:border-dawn-indicator-alt-light dark:has-[:checked]:border-dawn-indicator-dark",
      "has-[:checked]:bg-dawn-gradient-indicator-dark dark:has-[:checked]:bg-dawn-indicator-alt-light"
    ]
  end

  defp color_variant("bordered", "silver") do
    [
      "text-silver-bordered-text-light border-silver-bordered-text-light bg-silver-bordered-bg-light",
      "dark:text-silver-bordered-text-dark dark:border-silver-bordered-text-dark dark:bg-silver-bordered-bg-dark",
      "checked:[&_.checkbox-card-input]:text-silver-bordered-text-light",
      "dark:checked:[&_.checkbox-card-input]:text-silver-bordered-text-dark",
      "[&_.checkbox-card-input]:border-silver-bordered-text-light dark:[&_.checkbox-card-input]:border-silver-bordered-text-dark",
      "has-[:checked]:border-silver-indicator-alt-light dark:has-[:checked]:border-silver-indicator-dark",
      "has-[:checked]:bg-natural-border-dark dark:has-[:checked]:bg-silver-indicator-alt-light"
    ]
  end

  defp color_variant(params, _) when is_binary(params), do: params

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
