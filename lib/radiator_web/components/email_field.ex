defmodule RadiatorWeb.Components.EmailField do
  @moduledoc """
  The `RadiatorWeb.Components.EmailField` module provides a customizable email input field
  component built using Phoenix LiveView. It offers extensive styling options and behavior
  customizations for email input fields, such as:

  - Setting the size, color, and style of the input field.
  - Customizable labels, error messages, and descriptions.
  - Support for floating labels with inner and outer options.
  - Additional slots for icons or content at the start and end of the input field.
  - Integration with `Phoenix.HTML.FormField` for easy form handling.

  This component is designed to simplify the creation of styled and functional email
  input fields in Phoenix LiveView applications, providing developers with the flexibility
  to customize appearance and behavior according to their application's needs.

  **Documentation:** https://mishka.tools/chelekom/docs/forms/email-field
  """

  use Phoenix.Component
  import RadiatorWeb.Components.Icon, only: [icon: 1]

  @doc """
  Renders a customizable `email_field` with options for styling, floating labels, and additional
  start or end sections.

  The component allows you to create an email input field with various attributes
  like `size`, `color`, `border`, and `error` handling.

  ## Examples

  ```elixir
  <.email_field name="name" color="danger" placeholder="This is placeholder" floating="outer"/>

  <.email_field
    name="name"
    space="small"
    color="danger"
    description="This is description"
    label="This is outline label Email"
    placeholder="This is Email placeholder"
    floating="outer"
  >
    <:start_section>
      <.icon name="hero-home" class="size-4" />
    </:start_section>
    <:end_section>
      <.icon name="hero-home" class="size-4" />
    </:end_section>
  </.email_field>

  <.email_field
    name="name"
    space="small"
    color="silver"
    rounded="extra_large"
    label="This is outline Silver label Email"
    placeholder="This is Email placeholder"
    floating="outer"
  />
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
  attr :variant, :string, default: "base", doc: "Determines the style"
  attr :description, :string, default: nil, doc: "Determines a short description"
  attr :space, :string, default: "medium", doc: "Space between items"
  attr :placeholder, :string, default: nil, doc: "Specifies text for placeholder"
  attr :description_class, :string, default: "text-[12px]", doc: "Custom classes for description"
  attr :label_class, :string, default: nil, doc: "Custom CSS class for the label styling"
  attr :field_wrapper_class, :string, default: nil, doc: "Custom CSS class field wrapper"
  attr :input_class, :string, default: nil, doc: "Custom CSS class for the input"

  attr :floating_label_class, :string,
    default: nil,
    doc: "Custom CSS class for the floating label"

  attr :description_wrapper_class, :string,
    default: nil,
    doc: "Custom classes for description wrapper"

  attr :size, :string,
    default: "extra_large",
    doc:
      "Determines the overall size of the elements, including padding, font size, and other items"

  attr :ring, :boolean,
    default: true,
    doc:
      "Determines a ring border on focused input, utilities for creating outline rings with box-shadows."

  attr :floating, :string, default: "none", doc: "none, inner, outer"
  attr :error_icon, :string, default: nil, doc: "Icon to be displayed alongside error messages"
  attr :label, :string, default: nil, doc: "Specifies text for the label"

  slot :start_section, required: false, doc: "Renders heex content in start of an element" do
    attr :class, :string, doc: "Custom CSS class for additional styling"
    attr :icon, :string, doc: "Icon displayed alongside of an item"
  end

  slot :end_section, required: false, doc: "Renders heex content in end of an element" do
    attr :class, :string, doc: "Custom CSS class for additional styling"
    attr :icon, :string, doc: "Icon displayed alongside of an item"
  end

  attr :errors, :list, default: [], doc: "List of error messages to be displayed"
  attr :name, :any, doc: "Name of input"
  attr :value, :any, doc: "Value of input"

  attr :field, Phoenix.HTML.FormField, doc: "a form field struct retrieved from the form"

  attr :rest, :global,
    include:
      ~w(autocomplete disabled form list maxlength minlength spellcheck pattern placeholder readonly required size multiple title autofocus),
    doc:
      "Global attributes can define defaults which are merged with attributes provided by the caller"

  @spec email_field(map()) :: Phoenix.LiveView.Rendered.t()
  def email_field(%{field: %Phoenix.HTML.FormField{} = field} = assigns) do
    errors = if Phoenix.Component.used_input?(field), do: field.errors, else: []

    assigns
    |> assign(field: nil, id: assigns.id || field.id)
    |> assign(:errors, Enum.map(errors, &translate_error(&1)))
    |> assign_new(:value, fn -> field.value end)
    |> email_field()
  end

  def email_field(%{floating: floating} = assigns) when floating in ["inner", "outer"] do
    ~H"""
    <div class={[
      color_variant(@variant, @color, @floating),
      rounded_size(@rounded),
      border_class(@border, @variant),
      size_class(@size),
      space_class(@space),
      @ring && "[&_.email-field-wrapper]:focus-within:ring-[0.03rem] leading-6",
      @class
    ]}>
      <div :if={@description} class={@description_class}>
        {@description}
      </div>
      <div class={[
        "email-field-wrapper transition-all ease-in-out duration-200 w-full flex flex-nowrap",
        @errors != [] && "email-field-error",
        @field_wrapper_class
      ]}>
        <div
          :if={@start_section}
          class={[
            "flex items-center justify-center shrink-0 ps-2",
            @start_section[:class]
          ]}
        >
          {render_slot(@start_section)}
        </div>
        <div class="relative w-full z-[2]">
          <input
            type="email"
            name={@name}
            id={@id}
            value={@value}
            class={[
              "disabled:opacity-80 block w-full z-[2] focus:ring-0 placeholder:text-transparent pb-1 pt-2.5 px-2",
              "text-[16px] sm:font-inherit appearance-none bg-transparent border-0 focus:outline-none peer",
              @input_class
            ]}
            placeholder=" "
            {@rest}
          />

          <label
            class={[
              "floating-label px-1 start-1 -z-[1] absolute text-xs duration-300 transform scale-75 origin-[0]",
              variant_label_position(@floating),
              @floating_label_class
            ]}
            for={@id}
          >
            {@label}
          </label>
        </div>

        <div
          :if={@end_section}
          class={["flex items-center justify-center shrink-0 pe-2", @end_section[:class]]}
        >
          {render_slot(@end_section)}
        </div>
      </div>

      <.error :for={msg <- @errors} icon={@error_icon}>{msg}</.error>
    </div>
    """
  end

  def email_field(assigns) do
    ~H"""
    <div class={[
      color_variant(@variant, @color, @floating),
      rounded_size(@rounded),
      border_class(@border, @variant),
      size_class(@size),
      space_class(@space),
      @ring && "[&_.email-field-wrapper]:focus-within:ring-[0.03rem] leading-6",
      @class
    ]}>
      <div
        :if={@label || @description}
        class={["email-label-wrapper", @description_wrapper_class]}
      >
        <.label :if={@label} for={@id} class={@label_class}>{@label}</.label>
        <div :if={@description} class={@description_class}>
          {@description}
        </div>
      </div>

      <div class={[
        "email-field-wrapper overflow-hidden transition-all ease-in-out duration-200 flex items-center flex-nowrap",
        @errors != [] && "email-field-error",
        @field_wrapper_class
      ]}>
        <div
          :if={@start_section}
          class={[
            "flex items-center justify-center shrink-0 ps-2",
            @start_section[:class]
          ]}
        >
          {render_slot(@start_section)}
        </div>

        <input
          type="email"
          name={@name}
          id={@id}
          value={@value}
          placeholder={@placeholder}
          class={[
            "flex-1 py-1 px-2 text-sm disabled:opacity-80 block w-full appearance-none",
            "bg-transparent border-0 focus:outline-none focus:ring-0",
            @input_class
          ]}
          {@rest}
        />

        <div
          :if={@end_section}
          class={["flex items-center justify-center shrink-0 pe-2", @end_section[:class]]}
        >
          {render_slot(@end_section)}
        </div>
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
    <label for={@for} class={["font-semibold", @class]}>
      {render_slot(@inner_block)}
    </label>
    """
  end

  attr :icon, :string, default: nil, doc: "Icon displayed alongside of an item"
  slot :inner_block, required: true, doc: "Inner block that renders HEEx content"

  defp error(assigns) do
    ~H"""
    <p class="mt-3 flex items-center gap-3 text-sm text-rose-700">
      <.icon :if={!is_nil(@icon)} name={@icon} class="shrink-0" />
      {render_slot(@inner_block)}
    </p>
    """
  end

  defp variant_label_position("outer") do
    [
      "-translate-y-4 top-2 origin-[0] peer-focus:px-1 peer-placeholder-shown:scale-100",
      "peer-placeholder-shown:-translate-y-1/2 peer-placeholder-shown:top-1/2 peer-focus:top-2 peer-focus:scale-75 peer-focus:-translate-y-4",
      "rtl:peer-focus:translate-x-1/4 rtl:peer-focus:left-auto"
    ]
  end

  defp variant_label_position("inner") do
    [
      "-translate-y-4 scale-75 top-4 origin-[0] peer-placeholder-shown:scale-100 peer-placeholder-shown:translate-y-0",
      "peer-focus:scale-75 peer-focus:-translate-y-4 rtl:peer-focus:translate-x-1/4 rtl:peer-focus:left-auto"
    ]
  end

  defp size_class("extra_small"),
    do: "[&_.email-field-wrapper_input]:h-8 [&_.email-field-wrapper_.email-field-icon]:size-3"

  defp size_class("small"),
    do: "[&_.email-field-wrapper_input]:h-9 [&_.email-field-wrapper_.email-field-icon]:size-3.5"

  defp size_class("medium"),
    do: "[&_.email-field-wrapper_input]:h-10 [&_.email-field-wrapper_.email-field-icon]:size-4"

  defp size_class("large"),
    do: "[&_.email-field-wrapper_input]:h-11 [&_.email-field-wrapper_.email-field-icon]:size-5"

  defp size_class("extra_large"),
    do: "[&_.email-field-wrapper_input]:h-12 [&_.email-field-wrapper_.email-field-icon]:size-6"

  defp size_class(params) when is_binary(params), do: params

  defp rounded_size("extra_small"), do: "[&_.email-field-wrapper]:rounded-sm"

  defp rounded_size("small"), do: "[&_.email-field-wrapper]:rounded"

  defp rounded_size("medium"), do: "[&_.email-field-wrapper]:rounded-md"

  defp rounded_size("large"), do: "[&_.email-field-wrapper]:rounded-lg"

  defp rounded_size("extra_large"), do: "[&_.email-field-wrapper]:rounded-xl"

  defp rounded_size("full"), do: "[&_.email-field-wrapper]:rounded-full"

  defp rounded_size("none"), do: nil

  defp rounded_size(params) when is_binary(params), do: params

  defp border_class(_, variant) when variant in ["default", "shadow", "transparent"],
    do: nil

  defp border_class("none", _), do: "[&_.email-field-wrapper]:border-0"
  defp border_class("extra_small", _), do: "[&_.email-field-wrapper]:border"
  defp border_class("small", _), do: "[&_.email-field-wrapper]:border-2"
  defp border_class("medium", _), do: "[&_.email-field-wrapper]:border-[3px]"
  defp border_class("large", _), do: "[&_.email-field-wrapper]:border-4"
  defp border_class("extra_large", _), do: "[&_.email-field-wrapper]:border-[5px]"
  defp border_class(params, _) when is_binary(params), do: params

  defp space_class("none"), do: nil

  defp space_class("extra_small"), do: "space-y-1"

  defp space_class("small"), do: "space-y-1.5"

  defp space_class("medium"), do: "space-y-2"

  defp space_class("large"), do: "space-y-2.5"

  defp space_class("extra_large"), do: "space-y-3"

  defp space_class(params) when is_binary(params), do: params

  defp color_variant("base", _, floating) do
    [
      "[&_.email-field-wrapper:not(:has(.email-field-error))]:bg-white",
      "dark:[&_.email-field-wrapper:not(:has(.email-field-error))]:bg-base-bg-dark",
      "text-base-text-light dark:text-base-text-dark [&_.email-field-wrapper:not(:has(.email-field-error))]:border-base-border-light",
      "dark:[&_.email-field-wrapper:not(:has(.email-field-error))]:border-base-border-dark",
      "[&_.email-field-wrapper.email-field-error]:border-rose-700",
      "[&_.email-field-wrapper>input]:placeholder:text-base-text-light dark:[&_.email-field-wrapper>input]:placeholder:text-base-text-dark",
      "focus-within:[&_.email-field-wrapper]:ring-base-border-light dark:focus-within:[&_.email-field-wrapper]:ring-base-border-light",
      "[&_.email-field-wrapper]:shadow-sm",
      floating == "outer" &&
        "[&_.email-field-wrapper_.floating-label]:bg-white dark:[&_.email-field-wrapper_.floating-label]:bg-base-bg-dark"
    ]
  end

  defp color_variant("outline", "natural", floating) do
    [
      "text-natural-light dark:text-natural-dark [&_.email-field-wrapper:not(:has(.email-field-error))]:border-natural-light",
      "dark:[&_.email-field-wrapper:not(:has(.email-field-error))]:border-natural-dark",
      "[&_.email-field-wrapper.email-field-error]:border-rose-700",
      "[&_.email-field-wrapper>input]:placeholder:text-natural-light dark:[&_.email-field-wrapper>input]:placeholder:text-natural-dark",
      "focus-within:[&_.email-field-wrapper]:ring-natural-light dark:focus-within:[&_.email-field-wrapper]:ring-natural-dark",
      floating == "outer" &&
        "[&_.email-field-wrapper_.floating-label]:bg-white dark:[&_.email-field-wrapper_.floating-label]:bg-default-dark-bg"
    ]
  end

  defp color_variant("outline", "primary", floating) do
    [
      "text-primary-light dark:text-primary-dark [&_.email-field-wrapper:not(:has(.email-field-error))]:border-primary-light",
      "dark:[&_.email-field-wrapper:not(:has(.email-field-error))]:border-primary-dark",
      "[&_.email-field-wrapper.email-field-error]:border-rose-700",
      "[&_.email-field-wrapper>input]:placeholder:text-primary-light dark:[&_.email-field-wrapper>input]:placeholder:text-primary-dark",
      "focus-within:[&_.email-field-wrapper]:ring-primary-light dark:focus-within:[&_.email-field-wrapper]:ring-primary-dark",
      floating == "outer" &&
        "[&_.email-field-wrapper_.floating-label]:bg-white dark:[&_.email-field-wrapper_.floating-label]:bg-default-dark-bg"
    ]
  end

  defp color_variant("outline", "secondary", floating) do
    [
      "text-secondary-light dark:text-secondary-dark [&_.email-field-wrapper:not(:has(.email-field-error))]:border-secondary-light",
      "dark:[&_.email-field-wrapper:not(:has(.email-field-error))]:border-secondary-dark",
      "[&_.email-field-wrapper.email-field-error]:border-rose-700",
      "[&_.email-field-wrapper>input]:placeholder:text-secondary-light dark:[&_.email-field-wrapper>input]:placeholder:text-secondary-dark",
      "focus-within:[&_.email-field-wrapper]:ring-secondary-light dark:focus-within:[&_.email-field-wrapper]:ring-secondary-dark",
      floating == "outer" &&
        "[&_.email-field-wrapper_.floating-label]:bg-white dark:[&_.email-field-wrapper_.floating-label]:bg-default-dark-bg"
    ]
  end

  defp color_variant("outline", "success", floating) do
    [
      "text-success-light dark:text-success-dark [&_.email-field-wrapper:not(:has(.email-field-error))]:border-success-light",
      "dark:[&_.email-field-wrapper:not(:has(.email-field-error))]:border-success-dark",
      "[&_.email-field-wrapper.email-field-error]:border-rose-700",
      "[&_.email-field-wrapper>input]:placeholder:text-success-light dark:[&_.email-field-wrapper>input]:placeholder:text-success-dark",
      "focus-within:[&_.email-field-wrapper]:ring-success-light dark:focus-within:[&_.email-field-wrapper]:ring-success-dark",
      floating == "outer" &&
        "[&_.email-field-wrapper_.floating-label]:bg-white dark:[&_.email-field-wrapper_.floating-label]:bg-default-dark-bg"
    ]
  end

  defp color_variant("outline", "warning", floating) do
    [
      "text-warning-light dark:text-warning-dark [&_.email-field-wrapper:not(:has(.email-field-error))]:border-warning-light",
      "dark:[&_.email-field-wrapper:not(:has(.email-field-error))]:border-warning-dark",
      "[&_.email-field-wrapper.email-field-error]:border-rose-700",
      "[&_.email-field-wrapper>input]:placeholder:text-warning-light dark:[&_.email-field-wrapper>input]:placeholder:text-warning-dark",
      "focus-within:[&_.email-field-wrapper]:ring-warning-light dark:focus-within:[&_.email-field-wrapper]:ring-warning-dark",
      floating == "outer" &&
        "[&_.email-field-wrapper_.floating-label]:bg-white dark:[&_.email-field-wrapper_.floating-label]:bg-default-dark-bg"
    ]
  end

  defp color_variant("outline", "danger", floating) do
    [
      "text-danger-light dark:text-danger-dark [&_.email-field-wrapper:not(:has(.email-field-error))]:border-danger-light",
      "dark:[&_.email-field-wrapper:not(:has(.email-field-error))]:border-danger-dark",
      "[&_.email-field-wrapper.email-field-error]:border-rose-700",
      "[&_.email-field-wrapper>input]:placeholder:text-danger-light dark:[&_.email-field-wrapper>input]:placeholder:text-danger-dark",
      "focus-within:[&_.email-field-wrapper]:ring-danger-light dark:focus-within:[&_.email-field-wrapper]:ring-danger-dark",
      floating == "outer" &&
        "[&_.email-field-wrapper_.floating-label]:bg-white dark:[&_.email-field-wrapper_.floating-label]:bg-default-dark-bg"
    ]
  end

  defp color_variant("outline", "info", floating) do
    [
      "text-info-light dark:text-info-dark [&_.email-field-wrapper:not(:has(.email-field-error))]:border-info-light",
      "dark:[&_.email-field-wrapper:not(:has(.email-field-error))]:border-info-dark",
      "[&_.email-field-wrapper.email-field-error]:border-rose-700",
      "[&_.email-field-wrapper>input]:placeholder:text-info-light dark:[&_.email-field-wrapper>input]:placeholder:text-info-dark",
      "focus-within:[&_.email-field-wrapper]:ring-info-light dark:focus-within:[&_.email-field-wrapper]:ring-info-dark",
      floating == "outer" &&
        "[&_.email-field-wrapper_.floating-label]:bg-white dark:[&_.email-field-wrapper_.floating-label]:bg-default-dark-bg"
    ]
  end

  defp color_variant("outline", "misc", floating) do
    [
      "text-misc-light dark:text-misc-dark [&_.email-field-wrapper:not(:has(.email-field-error))]:border-misc-light",
      "dark:[&_.email-field-wrapper:not(:has(.email-field-error))]:border-misc-dark",
      "[&_.email-field-wrapper.email-field-error]:border-rose-700",
      "[&_.email-field-wrapper>input]:placeholder:text-misc-light dark:[&_.email-field-wrapper>input]:placeholder:text-misc-dark",
      "focus-within:[&_.email-field-wrapper]:ring-misc-light dark:focus-within:[&_.email-field-wrapper]:ring-misc-dark",
      floating == "outer" &&
        "[&_.email-field-wrapper_.floating-label]:bg-white dark:[&_.email-field-wrapper_.floating-label]:bg-default-dark-bg"
    ]
  end

  defp color_variant("outline", "dawn", floating) do
    [
      "text-dawn-light dark:text-dawn-dark [&_.email-field-wrapper:not(:has(.email-field-error))]:border-dawn-light",
      "dark:[&_.email-field-wrapper:not(:has(.email-field-error))]:border-dawn-dark",
      "[&_.email-field-wrapper.email-field-error]:border-rose-700",
      "[&_.email-field-wrapper>input]:placeholder:text-dawn-light dark:[&_.email-field-wrapper>input]:placeholder:text-dawn-dark",
      "focus-within:[&_.email-field-wrapper]:ring-dawn-light dark:focus-within:[&_.email-field-wrapper]:ring-dawn-dark",
      floating == "outer" &&
        "[&_.email-field-wrapper_.floating-label]:bg-white dark:[&_.email-field-wrapper_.floating-label]:bg-default-dark-bg"
    ]
  end

  defp color_variant("outline", "silver", floating) do
    [
      "text-silver-light dark:text-silver-dark [&_.email-field-wrapper:not(:has(.email-field-error))]:border-silver-light",
      "dark:[&_.email-field-wrapper:not(:has(.email-field-error))]:border-silver-dark",
      "[&_.email-field-wrapper.email-field-error]:border-rose-700",
      "[&_.email-field-wrapper>input]:placeholder:text-silver-light dark:[&_.email-field-wrapper>input]:placeholder:text-silver-dark",
      "focus-within:[&_.email-field-wrapper]:ring-silver-light dark:focus-within:[&_.email-field-wrapper]:ring-silver-dark",
      floating == "outer" &&
        "[&_.email-field-wrapper_.floating-label]:bg-white dark:[&_.email-field-wrapper_.floating-label]:bg-default-dark-bg"
    ]
  end

  defp color_variant("default", "white", floating) do
    [
      "[&_.email-field-wrapper]:bg-white text-form-white-text",
      "[&_.email-field-wrapper.email-field-error]:border-rose-700",
      "[&_.email-field-wrapper>input]:placeholder:text-form-white-text focus-within:[&_.email-field-wrapper]:ring-form-white-focus",
      floating == "outer" && "[&_.email-field-wrapper_.floating-label]:bg-white"
    ]
  end

  defp color_variant("default", "natural", floating) do
    [
      "text-black dark:text-white [&_.email-field-wrapper:not(:has(.email-field-error))]:bg-natural-light",
      "dark:[&_.email-field-wrapper:not(:has(.email-field-error))]:bg-natural-dark",
      "[&_.email-field-wrapper.email-field-error]:bg-rose-700",
      "[&_.email-field-wrapper>input]:placeholder:text-white dark:[&_.email-field-wrapper>input]:placeholder:text-black",
      "[&_.email-field-wrapper>input]:text-white dark:[&_.email-field-wrapper>input]:text-black",
      "focus-within:[&_.email-field-wrapper]:ring-natural-light dark:focus-within:[&_.email-field-wrapper]:ring-natural-dark",
      floating == "outer" &&
        "[&_.email-field-wrapper_.floating-label]:bg-natural-light dark:[&_.email-field-wrapper_.floating-label]:bg-natural-dark"
    ]
  end

  defp color_variant("default", "primary", floating) do
    [
      "text-black dark:text-white [&_.email-field-wrapper:not(:has(.email-field-error))]:bg-primary-light",
      "dark:[&_.email-field-wrapper:not(:has(.email-field-error))]:bg-primary-dark",
      "[&_.email-field-wrapper.email-field-error]:bg-rose-700",
      "[&_.email-field-wrapper>input]:placeholder:text-white dark:[&_.email-field-wrapper>input]:placeholder:text-black",
      "[&_.email-field-wrapper>input]:text-white dark:[&_.email-field-wrapper>input]:text-black",
      "focus-within:[&_.email-field-wrapper]:ring-primary-light dark:focus-within:[&_.email-field-wrapper]:ring-primary-dark",
      floating == "outer" &&
        "[&_.email-field-wrapper_.floating-label]:bg-primary-light dark:[&_.email-field-wrapper_.floating-label]:bg-primary-dark"
    ]
  end

  defp color_variant("default", "secondary", floating) do
    [
      "text-black dark:text-white [&_.email-field-wrapper:not(:has(.email-field-error))]:bg-secondary-light",
      "dark:[&_.email-field-wrapper:not(:has(.email-field-error))]:bg-secondary-dark",
      "[&_.email-field-wrapper.email-field-error]:bg-rose-700",
      "[&_.email-field-wrapper>input]:placeholder:text-white dark:[&_.email-field-wrapper>input]:placeholder:text-black",
      "[&_.email-field-wrapper>input]:text-white dark:[&_.email-field-wrapper>input]:text-black",
      "focus-within:[&_.email-field-wrapper]:ring-secondary-light dark:focus-within:[&_.email-field-wrapper]:ring-secondary-dark",
      floating == "outer" &&
        "[&_.email-field-wrapper_.floating-label]:bg-secondary-light dark:[&_.email-field-wrapper_.floating-label]:bg-secondary-dark"
    ]
  end

  defp color_variant("default", "success", floating) do
    [
      "text-black dark:text-white [&_.email-field-wrapper:not(:has(.email-field-error))]:bg-success-light",
      "dark:[&_.email-field-wrapper:not(:has(.email-field-error))]:bg-success-dark",
      "[&_.email-field-wrapper.email-field-error]:bg-rose-700",
      "[&_.email-field-wrapper>input]:placeholder:text-white dark:[&_.email-field-wrapper>input]:placeholder:text-black",
      "[&_.email-field-wrapper>input]:text-white dark:[&_.email-field-wrapper>input]:text-black",
      "focus-within:[&_.email-field-wrapper]:ring-success-light dark:focus-within:[&_.email-field-wrapper]:ring-success-dark",
      floating == "outer" &&
        "[&_.email-field-wrapper_.floating-label]:bg-success-light dark:[&_.email-field-wrapper_.floating-label]:bg-success-dark"
    ]
  end

  defp color_variant("default", "warning", floating) do
    [
      "text-black dark:text-white [&_.email-field-wrapper:not(:has(.email-field-error))]:bg-warning-light",
      "dark:[&_.email-field-wrapper:not(:has(.email-field-error))]:bg-warning-dark",
      "[&_.email-field-wrapper.email-field-error]:bg-rose-700",
      "[&_.email-field-wrapper>input]:placeholder:text-white dark:[&_.email-field-wrapper>input]:placeholder:text-black",
      "[&_.email-field-wrapper>input]:text-white dark:[&_.email-field-wrapper>input]:text-black",
      "focus-within:[&_.email-field-wrapper]:ring-warning-light dark:focus-within:[&_.email-field-wrapper]:ring-warning-dark",
      floating == "outer" &&
        "[&_.email-field-wrapper_.floating-label]:bg-warning-light dark:[&_.email-field-wrapper_.floating-label]:bg-warning-dark"
    ]
  end

  defp color_variant("default", "danger", floating) do
    [
      "text-black dark:text-white [&_.email-field-wrapper:not(:has(.email-field-error))]:bg-danger-light",
      "dark:[&_.email-field-wrapper:not(:has(.email-field-error))]:bg-danger-dark",
      "[&_.email-field-wrapper.email-field-error]:bg-rose-700",
      "[&_.email-field-wrapper>input]:placeholder:text-white dark:[&_.email-field-wrapper>input]:placeholder:text-black",
      "[&_.email-field-wrapper>input]:text-white dark:[&_.email-field-wrapper>input]:text-black",
      "focus-within:[&_.email-field-wrapper]:ring-danger-light dark:focus-within:[&_.email-field-wrapper]:ring-danger-dark",
      floating == "outer" &&
        "[&_.email-field-wrapper_.floating-label]:bg-danger-light dark:[&_.email-field-wrapper_.floating-label]:bg-danger-dark"
    ]
  end

  defp color_variant("default", "info", floating) do
    [
      "text-black dark:text-white [&_.email-field-wrapper:not(:has(.email-field-error))]:bg-info-light",
      "dark:[&_.email-field-wrapper:not(:has(.email-field-error))]:bg-info-dark",
      "[&_.email-field-wrapper.email-field-error]:bg-rose-700",
      "[&_.email-field-wrapper>input]:placeholder:text-white dark:[&_.email-field-wrapper>input]:placeholder:text-black",
      "[&_.email-field-wrapper>input]:text-white dark:[&_.email-field-wrapper>input]:text-black",
      "focus-within:[&_.email-field-wrapper]:ring-info-light dark:focus-within:[&_.email-field-wrapper]:ring-info-dark",
      floating == "outer" &&
        "[&_.email-field-wrapper_.floating-label]:bg-info-light dark:[&_.email-field-wrapper_.floating-label]:bg-info-dark"
    ]
  end

  defp color_variant("default", "misc", floating) do
    [
      "text-black dark:text-white [&_.email-field-wrapper:not(:has(.email-field-error))]:bg-misc-light",
      "dark:[&_.email-field-wrapper:not(:has(.email-field-error))]:bg-misc-dark",
      "[&_.email-field-wrapper.email-field-error]:bg-rose-700",
      "[&_.email-field-wrapper>input]:placeholder:text-white dark:[&_.email-field-wrapper>input]:placeholder:text-black",
      "[&_.email-field-wrapper>input]:text-white dark:[&_.email-field-wrapper>input]:text-black",
      "focus-within:[&_.email-field-wrapper]:ring-misc-light dark:focus-within:[&_.email-field-wrapper]:ring-misc-dark",
      floating == "outer" &&
        "[&_.email-field-wrapper_.floating-label]:bg-misc-light dark:[&_.email-field-wrapper_.floating-label]:bg-misc-dark"
    ]
  end

  defp color_variant("default", "dawn", floating) do
    [
      "text-black dark:text-white [&_.email-field-wrapper:not(:has(.email-field-error))]:bg-dawn-light",
      "dark:[&_.email-field-wrapper:not(:has(.email-field-error))]:bg-dawn-dark",
      "[&_.email-field-wrapper.email-field-error]:bg-rose-700",
      "[&_.email-field-wrapper>input]:placeholder:text-white dark:[&_.email-field-wrapper>input]:placeholder:text-black",
      "[&_.email-field-wrapper>input]:text-white dark:[&_.email-field-wrapper>input]:text-black",
      "focus-within:[&_.email-field-wrapper]:ring-dawn-light dark:focus-within:[&_.email-field-wrapper]:ring-dawn-dark",
      floating == "outer" &&
        "[&_.email-field-wrapper_.floating-label]:bg-dawn-light dark:[&_.email-field-wrapper_.floating-label]:bg-dawn-dark"
    ]
  end

  defp color_variant("default", "silver", floating) do
    [
      "text-black dark:text-white [&_.email-field-wrapper:not(:has(.email-field-error))]:bg-silver-light",
      "dark:[&_.email-field-wrapper:not(:has(.email-field-error))]:bg-silver-dark",
      "[&_.email-field-wrapper.email-field-error]:bg-rose-700",
      "[&_.email-field-wrapper>input]:placeholder:text-white dark:[&_.email-field-wrapper>input]:placeholder:text-black",
      "[&_.email-field-wrapper>input]:text-white dark:[&_.email-field-wrapper>input]:text-black",
      "focus-within:[&_.email-field-wrapper]:ring-silver-light dark:focus-within:[&_.email-field-wrapper]:ring-silver-dark",
      floating == "outer" &&
        "[&_.email-field-wrapper_.floating-label]:bg-silver-light dark:[&_.email-field-wrapper_.floating-label]:bg-silver-dark"
    ]
  end

  defp color_variant("default", "dark", floating) do
    [
      "[&_.email-field-wrapper]:bg-default-dark-bg text-default-dark-bg [&_.email-field-wrapper]:text-white",
      "[&_.email-field-wrapper.email-field-error]:border-rose-700",
      "[&_.email-field-wrapper>input]:placeholder:text-white focus-within:[&_.email-field-wrapper]:ring-silver-hover-light",
      floating == "outer" && "[&_.email-field-wrapper_.floating-label]:bg-default-dark-bg"
    ]
  end

  defp color_variant("bordered", "white", floating) do
    [
      "[&_.email-field-wrapper]:bg-white [&_.email-field-wrapper]:border-transparent text-form-white-text",
      "[&_.email-field-wrapper>input]:placeholder:text-form-white-text",
      floating == "outer" && "[&_.email-field-wrapper_.floating-label]:bg-white"
    ]
  end

  defp color_variant("bordered", "natural", floating) do
    [
      "text-natural-bordered-text-light dark:text-natural-hover-dark [&_.email-field-wrapper:not(:has(.email-field-error))]:border-natural-bordered-text-light",
      "[&_.email-field-wrapper:not(:has(.email-field-error))]:bg-natural-bordered-bg-light",
      "dark:[&_.email-field-wrapper:not(:has(.email-field-error))]:bg-natural-bordered-bg-dark",
      "dark:[&_.email-field-wrapper:not(:has(.email-field-error))]:border-silver-light",
      "[&_.email-field-wrapper.email-field-error]:bg-rose-700",
      "[&_.email-field-wrapper>input]:placeholder:text-natural-bordered-text-light dark:[&_.email-field-wrapper>input]:placeholder:text-natural-hover-dark",
      "focus-within:[&_.email-field-wrapper]:ring-natural-light dark:focus-within:[&_.email-field-wrapper]:ring-natural-dark",
      floating == "outer" &&
        "[&_.email-field-wrapper_.floating-label]:bg-silver-light dark:[&_.email-field-wrapper_.floating-label]:bg-silver-dark"
    ]
  end

  defp color_variant("bordered", "primary", floating) do
    [
      "text-primary-bordered-text-light dark:text-primary-hover-dark [&_.email-field-wrapper:not(:has(.email-field-error))]:border-primary-bordered-text-light",
      "[&_.email-field-wrapper:not(:has(.email-field-error))]:bg-primary-bordered-bg-light",
      "dark:[&_.email-field-wrapper:not(:has(.email-field-error))]:bg-natural-bordered-bg-dark",
      "dark:[&_.email-field-wrapper:not(:has(.email-field-error))]:border-primary-hover-dark",
      "[&_.email-field-wrapper.email-field-error]:bg-rose-700",
      "[&_.email-field-wrapper>input]:placeholder:text-primary-bordered-text-light dark:[&_.email-field-wrapper>input]:placeholder:text-primary-hover-dark",
      "focus-within:[&_.email-field-wrapper]:ring-primary-light dark:focus-within:[&_.email-field-wrapper]:ring-primary-dark",
      floating == "outer" &&
        "[&_.email-field-wrapper_.floating-label]:bg-silver-light dark:[&_.email-field-wrapper_.floating-label]:bg-silver-dark"
    ]
  end

  defp color_variant("bordered", "secondary", floating) do
    [
      "text-secondary-bordered-text-light dark:text-secondary-hover-dark [&_.email-field-wrapper:not(:has(.email-field-error))]:border-secondary-bordered-text-light",
      "[&_.email-field-wrapper:not(:has(.email-field-error))]:bg-secondary-bordered-bg-light",
      "dark:[&_.email-field-wrapper:not(:has(.email-field-error))]:bg-secondary-bordered-bg-dark",
      "dark:[&_.email-field-wrapper:not(:has(.email-field-error))]:border-secondary-hover-dark",
      "[&_.email-field-wrapper.email-field-error]:bg-rose-700",
      "[&_.email-field-wrapper>input]:placeholder:text-secondary-bordered-text-light dark:[&_.email-field-wrapper>input]:placeholder:text-secondary-hover-dark",
      "focus-within:[&_.email-field-wrapper]:ring-secondary-light dark:focus-within:[&_.email-field-wrapper]:ring-secondary-dark",
      floating == "outer" &&
        "[&_.email-field-wrapper_.floating-label]:bg-silver-light dark:[&_.email-field-wrapper_.floating-label]:bg-silver-dark"
    ]
  end

  defp color_variant("bordered", "success", floating) do
    [
      "text-success-bordered-text-light dark:text-success-hover-dark [&_.email-field-wrapper:not(:has(.email-field-error))]:border-success-bordered-text-light",
      "[&_.email-field-wrapper:not(:has(.email-field-error))]:bg-success-bordered-bg-light",
      "dark:[&_.email-field-wrapper:not(:has(.email-field-error))]:bg-success-bordered-bg-dark",
      "dark:[&_.email-field-wrapper:not(:has(.email-field-error))]:border-success-hover-dark",
      "[&_.email-field-wrapper.email-field-error]:bg-rose-700",
      "[&_.email-field-wrapper>input]:placeholder:text-success-bordered-text-light dark:[&_.email-field-wrapper>input]:placeholder:text-success-hover-dark",
      "focus-within:[&_.email-field-wrapper]:ring-success-light dark:focus-within:[&_.email-field-wrapper]:ring-success-dark",
      floating == "outer" &&
        "[&_.email-field-wrapper_.floating-label]:bg-silver-light dark:[&_.email-field-wrapper_.floating-label]:bg-silver-dark"
    ]
  end

  defp color_variant("bordered", "warning", floating) do
    [
      "text-warning-bordered-text-light dark:text-warning-hover-dark [&_.email-field-wrapper:not(:has(.email-field-error))]:border-warning-bordered-text-light",
      "[&_.email-field-wrapper:not(:has(.email-field-error))]:bg-warning-bordered-bg-light",
      "dark:[&_.email-field-wrapper:not(:has(.email-field-error))]:bg-warning-bordered-bg-dark",
      "dark:[&_.email-field-wrapper:not(:has(.email-field-error))]:border-warning-hover-dark",
      "[&_.email-field-wrapper.email-field-error]:bg-rose-700",
      "[&_.email-field-wrapper>input]:placeholder:text-warning-bordered-text-light dark:[&_.email-field-wrapper>input]:placeholder:text-warning-hover-dark",
      "focus-within:[&_.email-field-wrapper]:ring-warning-light dark:focus-within:[&_.email-field-wrapper]:ring-warning-dark",
      floating == "outer" &&
        "[&_.email-field-wrapper_.floating-label]:bg-silver-light dark:[&_.email-field-wrapper_.floating-label]:bg-silver-dark"
    ]
  end

  defp color_variant("bordered", "danger", floating) do
    [
      "text-danger-bordered-text-light dark:text-danger-hover-dark [&_.email-field-wrapper:not(:has(.email-field-error))]:border-danger-bordered-text-light",
      "[&_.email-field-wrapper:not(:has(.email-field-error))]:bg-danger-bordered-bg-light",
      "dark:[&_.email-field-wrapper:not(:has(.email-field-error))]:bg-danger-bordered-bg-dark",
      "dark:[&_.email-field-wrapper:not(:has(.email-field-error))]:border-danger-hover-dark",
      "[&_.email-field-wrapper.email-field-error]:bg-rose-700",
      "[&_.email-field-wrapper>input]:placeholder:text-danger-bordered-text-light dark:[&_.email-field-wrapper>input]:placeholder:text-danger-hover-dark",
      "focus-within:[&_.email-field-wrapper]:ring-danger-light dark:focus-within:[&_.email-field-wrapper]:ring-danger-dark",
      floating == "outer" &&
        "[&_.email-field-wrapper_.floating-label]:bg-silver-light dark:[&_.email-field-wrapper_.floating-label]:bg-silver-dark"
    ]
  end

  defp color_variant("bordered", "info", floating) do
    [
      "text-info-light dark:text-info-hover-dark [&_.email-field-wrapper:not(:has(.email-field-error))]:border-info-light",
      "[&_.email-field-wrapper:not(:has(.email-field-error))]:bg-info-bordered-bg-light",
      "dark:[&_.email-field-wrapper:not(:has(.email-field-error))]:bg-info-bordered-bg-dark",
      "dark:[&_.email-field-wrapper:not(:has(.email-field-error))]:border-info-hover-dark",
      "[&_.email-field-wrapper.email-field-error]:bg-rose-700",
      "[&_.email-field-wrapper>input]:placeholder:text-info-light dark:[&_.email-field-wrapper>input]:placeholder:text-info-hover-dark",
      "focus-within:[&_.email-field-wrapper]:ring-info-light dark:focus-within:[&_.email-field-wrapper]:ring-info-dark",
      floating == "outer" &&
        "[&_.email-field-wrapper_.floating-label]:bg-silver-light dark:[&_.email-field-wrapper_.floating-label]:bg-silver-dark"
    ]
  end

  defp color_variant("bordered", "misc", floating) do
    [
      "text-misc-bordered-text-light dark:text-misc-hover-dark [&_.email-field-wrapper:not(:has(.email-field-error))]:border-misc-bordered-text-light",
      "[&_.email-field-wrapper:not(:has(.email-field-error))]:bg-misc-bordered-bg-light",
      "dark:[&_.email-field-wrapper:not(:has(.email-field-error))]:bg-misc-bordered-bg-dark",
      "dark:[&_.email-field-wrapper:not(:has(.email-field-error))]:border-misc-hover-dark",
      "[&_.email-field-wrapper.email-field-error]:bg-rose-700",
      "[&_.email-field-wrapper>input]:placeholder:text-misc-bordered-text-light dark:[&_.email-field-wrapper>input]:placeholder:text-misc-hover-dark",
      "focus-within:[&_.email-field-wrapper]:ring-misc-light dark:focus-within:[&_.email-field-wrapper]:ring-misc-dark",
      floating == "outer" &&
        "[&_.email-field-wrapper_.floating-label]:bg-silver-light dark:[&_.email-field-wrapper_.floating-label]:bg-silver-dark"
    ]
  end

  defp color_variant("bordered", "dawn", floating) do
    [
      "text-dawn-bordered-text-light dark:text-dawn-hover-dark [&_.email-field-wrapper:not(:has(.email-field-error))]:border-dawn-bordered-text-light",
      "[&_.email-field-wrapper:not(:has(.email-field-error))]:bg-dawn-bordered-bg-light",
      "dark:[&_.email-field-wrapper:not(:has(.email-field-error))]:bg-dawn-bordered-bg-dark",
      "dark:[&_.email-field-wrapper:not(:has(.email-field-error))]:border-dawn-hover-dark",
      "[&_.email-field-wrapper.email-field-error]:bg-rose-700",
      "[&_.email-field-wrapper>input]:placeholder:text-dawn-bordered-text-light dark:[&_.email-field-wrapper>input]:placeholder:text-dawn-hover-dark",
      "focus-within:[&_.email-field-wrapper]:ring-dawn-light dark:focus-within:[&_.email-field-wrapper]:ring-dawn-dark",
      floating == "outer" &&
        "[&_.email-field-wrapper_.floating-label]:bg-silver-light dark:[&_.email-field-wrapper_.floating-label]:bg-silver-dark"
    ]
  end

  defp color_variant("bordered", "silver", floating) do
    [
      "text-silver-hover-light dark:text-silver-hover-dark [&_.email-field-wrapper:not(:has(.email-field-error))]:border-silver-hover-light",
      "[&_.email-field-wrapper:not(:has(.email-field-error))]:bg-silver-bordered-bg-light",
      "dark:[&_.email-field-wrapper:not(:has(.email-field-error))]:bg-silver-bordered-bg-dark",
      "dark:[&_.email-field-wrapper:not(:has(.email-field-error))]:border-silver-hover-dark",
      "[&_.email-field-wrapper.email-field-error]:bg-rose-700",
      "[&_.email-field-wrapper>input]:placeholder:text-silver-hover-light dark:[&_.email-field-wrapper>input]:placeholder:text-silver-hover-dark",
      "focus-within:[&_.email-field-wrapper]:ring-silver-light dark:focus-within:[&_.email-field-wrapper]:ring-silver-dark",
      floating == "outer" &&
        "[&_.email-field-wrapper_.floating-label]:bg-silver-light dark:[&_.email-field-wrapper_.floating-label]:bg-silver-dark"
    ]
  end

  defp color_variant("bordered", "dark", floating) do
    [
      "[&_.email-field-wrapper]:bg-default-dark-bg text-default-dark-bg [&_.email-field-wrapper]:border-silver-hover-light text-white",
      "[&_.email-field-wrapper>input]:placeholder:text-white focus-within:[&_.email-field-wrapper]:ring-silver-hover-light",
      floating == "outer" && "[&_.email-field-wrapper_.floating-label]:bg-default-dark-bg"
    ]
  end

  defp color_variant("shadow", "natural", floating) do
    [
      "text-black dark:text-white [&_.email-field-wrapper:not(:has(.email-field-error))]:bg-natural-light",
      "dark:[&_.email-field-wrapper:not(:has(.email-field-error))]:bg-natural-dark",
      "[&_.email-field-wrapper.email-field-error]:bg-rose-700",
      "[&_.email-field-wrapper>input]:placeholder:text-white dark:[&_.email-field-wrapper>input]:placeholder:text-black",
      "[&_.email-field-wrapper>input]:text-white dark:[&_.email-field-wrapper>input]:text-black",
      "focus-within:[&_.email-field-wrapper]:ring-natural-light dark:focus-within:[&_.email-field-wrapper]:ring-natural-dark",
      "[&_.email-field-wrapper]:shadow-[0px_4px_6px_-4px_var(--color-shadow-natural)] [&_.email-field-wrapper]:shadow-[0px_10px_15px_-3px_var(--color-shadow-natural)]",
      "dark:[&_.email-field-wrapper]:shadow-none",
      floating == "outer" &&
        "[&_.email-field-wrapper_.floating-label]:bg-natural-light dark:[&_.email-field-wrapper_.floating-label]:bg-natural-dark"
    ]
  end

  defp color_variant("shadow", "primary", floating) do
    [
      "text-black dark:text-white [&_.email-field-wrapper:not(:has(.email-field-error))]:bg-primary-light",
      "dark:[&_.email-field-wrapper:not(:has(.email-field-error))]:bg-primary-dark",
      "[&_.email-field-wrapper.email-field-error]:bg-rose-700",
      "[&_.email-field-wrapper>input]:placeholder:text-white dark:[&_.email-field-wrapper>input]:placeholder:text-black",
      "[&_.email-field-wrapper>input]:text-white dark:[&_.email-field-wrapper>input]:text-black",
      "focus-within:[&_.email-field-wrapper]:ring-primary-light dark:focus-within:[&_.email-field-wrapper]:ring-primary-dark",
      "[&_.email-field-wrapper]:shadow-[0px_4px_6px_-4px_var(--color-shadow-primary)] [&_.email-field-wrapper]:shadow-[0px_10px_15px_-3px_var(--color-shadow-primary)]",
      "dark:[&_.email-field-wrapper]:shadow-none",
      floating == "outer" &&
        "[&_.email-field-wrapper_.floating-label]:bg-primary-light dark:[&_.email-field-wrapper_.floating-label]:bg-primary-dark"
    ]
  end

  defp color_variant("shadow", "secondary", floating) do
    [
      "text-black dark:text-white [&_.email-field-wrapper:not(:has(.email-field-error))]:bg-secondary-light",
      "dark:[&_.email-field-wrapper:not(:has(.email-field-error))]:bg-secondary-dark",
      "[&_.email-field-wrapper.email-field-error]:bg-rose-700",
      "[&_.email-field-wrapper>input]:placeholder:text-white dark:[&_.email-field-wrapper>input]:placeholder:text-black",
      "[&_.email-field-wrapper>input]:text-white dark:[&_.email-field-wrapper>input]:text-black",
      "focus-within:[&_.email-field-wrapper]:ring-secondary-light dark:focus-within:[&_.email-field-wrapper]:ring-secondary-dark",
      "[&_.email-field-wrapper]:shadow-[0px_4px_6px_-4px_var(--color-shadow-secondary)] [&_.email-field-wrapper]:shadow-[0px_10px_15px_-3px_var(--color-shadow-secondary)]",
      "dark:[&_.email-field-wrapper]:shadow-none",
      floating == "outer" &&
        "[&_.email-field-wrapper_.floating-label]:bg-secondary-light dark:[&_.email-field-wrapper_.floating-label]:bg-secondary-dark"
    ]
  end

  defp color_variant("shadow", "success", floating) do
    [
      "text-black dark:text-white [&_.email-field-wrapper:not(:has(.email-field-error))]:bg-success-light",
      "dark:[&_.email-field-wrapper:not(:has(.email-field-error))]:bg-success-dark",
      "[&_.email-field-wrapper.email-field-error]:bg-rose-700",
      "[&_.email-field-wrapper>input]:placeholder:text-white dark:[&_.email-field-wrapper>input]:placeholder:text-black",
      "[&_.email-field-wrapper>input]:text-white dark:[&_.email-field-wrapper>input]:text-black",
      "focus-within:[&_.email-field-wrapper]:ring-success-light dark:focus-within:[&_.email-field-wrapper]:ring-success-dark",
      "[&_.email-field-wrapper]:shadow-[0px_4px_6px_-4px_var(--color-shadow-success)] [&_.email-field-wrapper]:shadow-[0px_10px_15px_-3px_var(--color-shadow-success)]",
      "dark:[&_.email-field-wrapper]:shadow-none",
      floating == "outer" &&
        "[&_.email-field-wrapper_.floating-label]:bg-success-light dark:[&_.email-field-wrapper_.floating-label]:bg-success-dark"
    ]
  end

  defp color_variant("shadow", "warning", floating) do
    [
      "text-black dark:text-white [&_.email-field-wrapper:not(:has(.email-field-error))]:bg-warning-light",
      "dark:[&_.email-field-wrapper:not(:has(.email-field-error))]:bg-warning-dark",
      "[&_.email-field-wrapper.email-field-error]:bg-rose-700",
      "[&_.email-field-wrapper>input]:placeholder:text-white dark:[&_.email-field-wrapper>input]:placeholder:text-black",
      "[&_.email-field-wrapper>input]:text-white dark:[&_.email-field-wrapper>input]:text-black",
      "focus-within:[&_.email-field-wrapper]:ring-warning-light dark:focus-within:[&_.email-field-wrapper]:ring-warning-dark",
      "[&_.email-field-wrapper]:shadow-[0px_4px_6px_-4px_var(--color-shadow-warning)] [&_.email-field-wrapper]:shadow-[0px_10px_15px_-3px_var(--color-shadow-warning)]",
      "dark:[&_.email-field-wrapper]:shadow-none",
      floating == "outer" &&
        "[&_.email-field-wrapper_.floating-label]:bg-warning-light dark:[&_.email-field-wrapper_.floating-label]:bg-warning-dark"
    ]
  end

  defp color_variant("shadow", "danger", floating) do
    [
      "text-black dark:text-white [&_.email-field-wrapper:not(:has(.email-field-error))]:bg-danger-light",
      "dark:[&_.email-field-wrapper:not(:has(.email-field-error))]:bg-danger-dark",
      "[&_.email-field-wrapper.email-field-error]:bg-rose-700",
      "[&_.email-field-wrapper>input]:placeholder:text-white dark:[&_.email-field-wrapper>input]:placeholder:text-black",
      "[&_.email-field-wrapper>input]:text-white dark:[&_.email-field-wrapper>input]:text-black",
      "focus-within:[&_.email-field-wrapper]:ring-danger-light dark:focus-within:[&_.email-field-wrapper]:ring-danger-dark",
      "[&_.email-field-wrapper]:shadow-[0px_4px_6px_-4px_var(--color-shadow-danger)] [&_.email-field-wrapper]:shadow-[0px_10px_15px_-3px_var(--color-shadow-danger)]",
      "dark:[&_.email-field-wrapper]:shadow-none",
      floating == "outer" &&
        "[&_.email-field-wrapper_.floating-label]:bg-danger-light dark:[&_.email-field-wrapper_.floating-label]:bg-danger-dark"
    ]
  end

  defp color_variant("shadow", "info", floating) do
    [
      "text-black dark:text-white [&_.email-field-wrapper:not(:has(.email-field-error))]:bg-info-light",
      "dark:[&_.email-field-wrapper:not(:has(.email-field-error))]:bg-info-dark",
      "[&_.email-field-wrapper.email-field-error]:bg-rose-700",
      "[&_.email-field-wrapper>input]:placeholder:text-white dark:[&_.email-field-wrapper>input]:placeholder:text-black",
      "[&_.email-field-wrapper>input]:text-white dark:[&_.email-field-wrapper>input]:text-black",
      "focus-within:[&_.email-field-wrapper]:ring-info-light dark:focus-within:[&_.email-field-wrapper]:ring-info-dark",
      "[&_.email-field-wrapper]:shadow-[0px_4px_6px_-4px_var(--color-shadow-info)] [&_.email-field-wrapper]:shadow-[0px_10px_15px_-3px_var(--color-shadow-info)]",
      "dark:[&_.email-field-wrapper]:shadow-none",
      floating == "outer" &&
        "[&_.email-field-wrapper_.floating-label]:bg-info-light dark:[&_.email-field-wrapper_.floating-label]:bg-info-dark"
    ]
  end

  defp color_variant("shadow", "misc", floating) do
    [
      "text-black dark:text-white [&_.email-field-wrapper:not(:has(.email-field-error))]:bg-misc-light",
      "dark:[&_.email-field-wrapper:not(:has(.email-field-error))]:bg-misc-dark",
      "[&_.email-field-wrapper.email-field-error]:bg-rose-700",
      "[&_.email-field-wrapper>input]:placeholder:text-white dark:[&_.email-field-wrapper>input]:placeholder:text-black",
      "[&_.email-field-wrapper>input]:text-white dark:[&_.email-field-wrapper>input]:text-black",
      "focus-within:[&_.email-field-wrapper]:ring-misc-light dark:focus-within:[&_.email-field-wrapper]:ring-misc-dark",
      "[&_.email-field-wrapper]:shadow-[0px_4px_6px_-4px_var(--color-shadow-misc)] [&_.email-field-wrapper]:shadow-[0px_10px_15px_-3px_var(--color-shadow-misc)]",
      "dark:[&_.email-field-wrapper]:shadow-none",
      floating == "outer" &&
        "[&_.email-field-wrapper_.floating-label]:bg-misc-light dark:[&_.email-field-wrapper_.floating-label]:bg-misc-dark"
    ]
  end

  defp color_variant("shadow", "dawn", floating) do
    [
      "text-black dark:text-white [&_.email-field-wrapper:not(:has(.email-field-error))]:bg-dawn-light",
      "dark:[&_.email-field-wrapper:not(:has(.email-field-error))]:bg-dawn-dark",
      "[&_.email-field-wrapper.email-field-error]:bg-rose-700",
      "[&_.email-field-wrapper>input]:placeholder:text-white dark:[&_.email-field-wrapper>input]:placeholder:text-black",
      "[&_.email-field-wrapper>input]:text-white dark:[&_.email-field-wrapper>input]:text-black",
      "focus-within:[&_.email-field-wrapper]:ring-dawn-light dark:focus-within:[&_.email-field-wrapper]:ring-dawn-dark",
      "[&_.email-field-wrapper]:shadow-[0px_4px_6px_-4px_var(--color-shadow-dawn)] [&_.email-field-wrapper]:shadow-[0px_10px_15px_-3px_var(--color-shadow-dawn)]",
      "dark:[&_.email-field-wrapper]:shadow-none",
      floating == "outer" &&
        "[&_.email-field-wrapper_.floating-label]:bg-dawn-light dark:[&_.email-field-wrapper_.floating-label]:bg-dawn-dark"
    ]
  end

  defp color_variant("shadow", "silver", floating) do
    [
      "text-black dark:text-white [&_.email-field-wrapper:not(:has(.email-field-error))]:bg-silver-light",
      "dark:[&_.email-field-wrapper:not(:has(.email-field-error))]:bg-silver-dark",
      "[&_.email-field-wrapper.email-field-error]:bg-rose-700",
      "[&_.email-field-wrapper>input]:placeholder:text-white dark:[&_.email-field-wrapper>input]:placeholder:text-black",
      "[&_.email-field-wrapper>input]:text-white dark:[&_.email-field-wrapper>input]:text-black",
      "focus-within:[&_.email-field-wrapper]:ring-silver-light dark:focus-within:[&_.email-field-wrapper]:ring-silver-dark",
      "[&_.email-field-wrapper]:shadow-[0px_4px_6px_-4px_var(--color-shadow-silver)] [&_.email-field-wrapper]:shadow-[0px_10px_15px_-3px_var(--color-shadow-silver)]",
      "dark:[&_.email-field-wrapper]:shadow-none",
      floating == "outer" &&
        "[&_.email-field-wrapper_.floating-label]:bg-silver-light dark:[&_.email-field-wrapper_.floating-label]:bg-silver-dark"
    ]
  end

  defp color_variant("transparent", "natural", _) do
    [
      "text-natural-light dark:text-natural-dark",
      "[&_.email-field-wrapper>input]:placeholder:text-natural-light",
      "dark:[&_.email-field-wrapper>input]:placeholder:text-natural-dark",
      "focus-within:[&_.email-field-wrapper]:ring-transparent"
    ]
  end

  defp color_variant("transparent", "primary", _) do
    [
      "text-primary-light dark:text-primary-dark",
      "[&_.email-field-wrapper>input]:placeholder:text-primary-light",
      "dark:[&_.email-field-wrapper>input]:placeholder:text-primary-dark",
      "focus-within:[&_.email-field-wrapper]:ring-transparent"
    ]
  end

  defp color_variant("transparent", "secondary", _) do
    [
      "text-secondary-light dark:text-secondary-dark",
      "[&_.email-field-wrapper>input]:placeholder:text-secondary-light",
      "dark:[&_.email-field-wrapper>input]:placeholder:text-secondary-dark",
      "focus-within:[&_.email-field-wrapper]:ring-transparent"
    ]
  end

  defp color_variant("transparent", "success", _) do
    [
      "text-success-light dark:text-success-dark",
      "[&_.email-field-wrapper>input]:placeholder:text-success-light",
      "dark:[&_.email-field-wrapper>input]:placeholder:text-success-dark",
      "focus-within:[&_.email-field-wrapper]:ring-transparent"
    ]
  end

  defp color_variant("transparent", "warning", _) do
    [
      "text-warning-light dark:text-warning-dark",
      "[&_.email-field-wrapper>input]:placeholder:text-warning-light",
      "dark:[&_.email-field-wrapper>input]:placeholder:text-warning-dark",
      "focus-within:[&_.email-field-wrapper]:ring-transparent"
    ]
  end

  defp color_variant("transparent", "danger", _) do
    [
      "text-danger-light dark:text-danger-dark",
      "[&_.email-field-wrapper>input]:placeholder:text-danger-light",
      "dark:[&_.email-field-wrapper>input]:placeholder:text-danger-dark",
      "focus-within:[&_.email-field-wrapper]:ring-transparent"
    ]
  end

  defp color_variant("transparent", "info", _) do
    [
      "text-info-light dark:text-info-dark",
      "[&_.email-field-wrapper>input]:placeholder:text-info-light",
      "dark:[&_.email-field-wrapper>input]:placeholder:text-info-dark",
      "focus-within:[&_.email-field-wrapper]:ring-transparent"
    ]
  end

  defp color_variant("transparent", "misc", _) do
    [
      "text-misc-light dark:text-misc-dark",
      "[&_.email-field-wrapper>input]:placeholder:text-misc-light",
      "dark:[&_.email-field-wrapper>input]:placeholder:text-misc-dark",
      "focus-within:[&_.email-field-wrapper]:ring-transparent"
    ]
  end

  defp color_variant("transparent", "dawn", _) do
    [
      "text-dawn-light dark:text-dawn-dark",
      "[&_.email-field-wrapper>input]:placeholder:text-dawn-light",
      "dark:[&_.email-field-wrapper>input]:placeholder:text-dawn-dark",
      "focus-within:[&_.email-field-wrapper]:ring-transparent"
    ]
  end

  defp color_variant("transparent", "silver", _) do
    [
      "text-silver-light dark:text-silver-dark",
      "[&_.email-field-wrapper>input]:placeholder:text-silver-light",
      "dark:[&_.email-field-wrapper>input]:placeholder:text-silver-dark",
      "focus-within:[&_.email-field-wrapper]:ring-transparent"
    ]
  end

  defp color_variant(params, _, _) when is_binary(params), do: params

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
