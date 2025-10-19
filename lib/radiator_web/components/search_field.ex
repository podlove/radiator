defmodule RadiatorWeb.Components.SearchField do
  @moduledoc """
  The `RadiatorWeb.Components.SearchField` module provides a highly customizable search input
  component for Phoenix LiveView applications. This component is designed to offer advanced
  search functionality with support for custom styles, layouts, and interactions.

  It includes features such as configurable size, border style, rounded corners, and color
  variants, making it adaptable to various design requirements. The component also supports
  optional start and end sections for icons or additional content, as well as a search button for executing queries.

  The `SearchField` component is ideal for implementing search forms, filters, or any other
  user interface elements where search functionality is needed. Its flexibility and ease of
  integration make it a powerful tool for enhancing user experiences in Phoenix LiveView applications.

  **Documentation:** https://mishka.tools/chelekom/docs/forms/search-field
  """
  use Phoenix.Component
  import RadiatorWeb.Components.Icon, only: [icon: 1]

  @doc """
  Renders a `search_field` component that allows users to input search queries.
  The component supports an optional search button and sections for custom content at the
  start and end of the input.

  ## Examples

  ```elixir
  <.search_field
    name="search_query"
    space="small"
    color="primary"
    size="small"
    description="Search for items"
    label="Search"
    placeholder="Type your search query here"
    floating="outer"
    search_button
  />

  <.search_field
    name="search_query"
    space="small"
    color="success"
    description="Custom search field"
    label="Search"
    placeholder="Search something"
    floating="outer"
  >
    <:start_section>
      <.icon name="hero-search" class="size-4" />
    </:start_section>
    <:end_section>
      <.icon name="hero-search" class="size-4" />
    </:end_section>
  </.search_field>
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
  attr :search_button_class, :string, default: nil, doc: "Custom CSS class for the show password"

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

  attr :search_button, :boolean, default: false, doc: "Specifies search button"
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
    include: ~w(autocomplete disabled form list maxlength minlength pattern placeholder
        readonly required size spellcheck inputmode title autofocus),
    doc:
      "Global attributes can define defaults which are merged with attributes provided by the caller"

  @spec search_field(map()) :: Phoenix.LiveView.Rendered.t()
  def search_field(%{field: %Phoenix.HTML.FormField{} = field} = assigns) do
    errors = if Phoenix.Component.used_input?(field), do: field.errors, else: []

    assigns
    |> assign(field: nil, id: assigns.id || field.id)
    |> assign(:errors, Enum.map(errors, &translate_error(&1)))
    |> assign_new(:name, fn -> field.name end)
    |> assign_new(:value, fn -> field.value end)
    |> search_field()
  end

  def search_field(%{floating: floating} = assigns) when floating in ["inner", "outer"] do
    ~H"""
    <div class={[
      color_variant(@variant, @color, @floating),
      rounded_size(@rounded),
      border_class(@border, @variant),
      size_class(@size),
      space_class(@space),
      @ring && "[&_.search-field-wrapper]:focus-within:ring-[0.03rem] leading-6",
      @class
    ]}>
      <div :if={@description} class={@description_class}>
        {@description}
      </div>
      <div class={[
        "search-field-wrapper transition-all ease-in-out duration-200 w-full flex flex-nowrap",
        @errors != [] && "search-field-error",
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
            type="search"
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
        <div
          :if={@search_button}
          class={["flex items-center justify-center shrink-0 pe-2", @search_button_class]}
        >
          <button class="flex items-center justify-center leading-5 focus:outline-none">
            <.icon name="hero-magnifying-glass" class="search-field-icon" />
          </button>
        </div>
      </div>

      <.error :for={msg <- @errors} icon={@error_icon}>{msg}</.error>
    </div>
    """
  end

  def search_field(assigns) do
    ~H"""
    <div class={[
      color_variant(@variant, @color, @floating),
      rounded_size(@rounded),
      border_class(@border, @variant),
      size_class(@size),
      space_class(@space),
      @ring && "[&_.search-field-wrapper]:focus-within:ring-[0.03rem] leading-6",
      @class
    ]}>
      <div
        :if={@label || @description}
        class={["search-label-wrapper", @description_wrapper_class]}
      >
        <.label :if={@label} for={@id} class={@label_class}>{@label}</.label>
        <div :if={@description} class={@description_class}>
          {@description}
        </div>
      </div>

      <div class={[
        "search-field-wrapper overflow-hidden transition-all ease-in-out duration-200 flex items-center flex-nowrap",
        @errors != [] && "search-field-error",
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
          type="search"
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
        <div
          :if={@search_button}
          class={["flex items-center justify-center shrink-0 pe-2", @search_button_class]}
        >
          <button class="flex items-center justify-center leading-5 focus:outline-none">
            <.icon name="hero-magnifying-glass" class="search-field-icon" />
          </button>
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

  defp size_class("extra_small") do
    "[&_.search-field-wrapper_input]:h-8 [&_.search-field-wrapper_.search-field-icon]:size-3.5"
  end

  defp size_class("small") do
    "[&_.search-field-wrapper_input]:h-9 [&_.search-field-wrapper_.search-field-icon]:size-4"
  end

  defp size_class("medium") do
    "[&_.search-field-wrapper_input]:h-10 [&_.search-field-wrapper_.search-field-icon]:size-5"
  end

  defp size_class("large") do
    "[&_.search-field-wrapper_input]:h-11 [&_.search-field-wrapper_.search-field-icon]:size-6"
  end

  defp size_class("extra_large") do
    "[&_.search-field-wrapper_input]:h-12 [&_.search-field-wrapper_.search-field-icon]:size-7"
  end

  defp size_class(params) when is_binary(params), do: params

  defp rounded_size("extra_small"), do: "[&_.search-field-wrapper]:rounded-sm"

  defp rounded_size("small"), do: "[&_.search-field-wrapper]:rounded"

  defp rounded_size("medium"), do: "[&_.search-field-wrapper]:rounded-md"

  defp rounded_size("large"), do: "[&_.search-field-wrapper]:rounded-lg"

  defp rounded_size("extra_large"), do: "[&_.search-field-wrapper]:rounded-xl"

  defp rounded_size("full"), do: "[&_.search-field-wrapper]:rounded-full"

  defp rounded_size("none"), do: nil

  defp rounded_size(params) when is_binary(params), do: params

  defp border_class(_, variant) when variant in ["default", "shadow", "transparent"],
    do: nil

  defp border_class("none", _), do: "[&_.search-field-wrapper]:border-0"
  defp border_class("extra_small", _), do: "[&_.search-field-wrapper]:border"
  defp border_class("small", _), do: "[&_.search-field-wrapper]:border-2"
  defp border_class("medium", _), do: "[&_.search-field-wrapper]:border-[3px]"
  defp border_class("large", _), do: "[&_.search-field-wrapper]:border-4"
  defp border_class("extra_large", _), do: "[&_.search-field-wrapper]:border-[5px]"
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
      "[&_.search-field-wrapper:not(:has(.search-field-error))]:bg-white",
      "dark:[&_.search-field-wrapper:not(:has(.search-field-error))]:bg-base-bg-dark",
      "text-base-text-light dark:text-base-text-dark [&_.search-field-wrapper:not(:has(.search-field-error))]:border-base-border-light",
      "dark:[&_.search-field-wrapper:not(:has(.search-field-error))]:border-base-border-dark",
      "[&_.search-field-wrapper.search-field-error]:border-rose-700",
      "[&_.search-field-wrapper>input]:placeholder:text-base-text-light dark:[&_.search-field-wrapper>input]:placeholder:text-base-text-dark",
      "focus-within:[&_.search-field-wrapper]:ring-base-border-light dark:focus-within:[&_.search-field-wrapper]:ring-base-border-light",
      "[&_.search-field-wrapper]:shadow-sm",
      floating == "outer" &&
        "[&_.search-field-wrapper_.floating-label]:bg-white dark:[&_.search-field-wrapper_.floating-label]:bg-base-bg-dark"
    ]
  end

  defp color_variant("outline", "natural", floating) do
    [
      "text-natural-light dark:text-natural-dark [&_.search-field-wrapper:not(:has(.search-field-error))]:border-natural-light",
      "dark:[&_.search-field-wrapper:not(:has(.search-field-error))]:border-natural-dark",
      "[&_.search-field-wrapper.search-field-error]:border-rose-700",
      "[&_.search-field-wrapper>input]:placeholder:text-natural-light dark:[&_.search-field-wrapper>input]:placeholder:text-natural-dark",
      "focus-within:[&_.search-field-wrapper]:ring-natural-light dark:focus-within:[&_.search-field-wrapper]:ring-natural-dark",
      floating == "outer" &&
        "[&_.search-field-wrapper_.floating-label]:bg-white dark:[&_.search-field-wrapper_.floating-label]:bg-default-dark-bg"
    ]
  end

  defp color_variant("outline", "primary", floating) do
    [
      "text-primary-light dark:text-primary-dark [&_.search-field-wrapper:not(:has(.search-field-error))]:border-primary-light",
      "dark:[&_.search-field-wrapper:not(:has(.search-field-error))]:border-primary-dark",
      "[&_.search-field-wrapper.search-field-error]:border-rose-700",
      "[&_.search-field-wrapper>input]:placeholder:text-primary-light dark:[&_.search-field-wrapper>input]:placeholder:text-primary-dark",
      "focus-within:[&_.search-field-wrapper]:ring-primary-light dark:focus-within:[&_.search-field-wrapper]:ring-primary-dark",
      floating == "outer" &&
        "[&_.search-field-wrapper_.floating-label]:bg-white dark:[&_.search-field-wrapper_.floating-label]:bg-default-dark-bg"
    ]
  end

  defp color_variant("outline", "secondary", floating) do
    [
      "text-secondary-light dark:text-secondary-dark [&_.search-field-wrapper:not(:has(.search-field-error))]:border-secondary-light",
      "dark:[&_.search-field-wrapper:not(:has(.search-field-error))]:border-secondary-dark",
      "[&_.search-field-wrapper.search-field-error]:border-rose-700",
      "[&_.search-field-wrapper>input]:placeholder:text-secondary-light dark:[&_.search-field-wrapper>input]:placeholder:text-secondary-dark",
      "focus-within:[&_.search-field-wrapper]:ring-secondary-light dark:focus-within:[&_.search-field-wrapper]:ring-secondary-dark",
      floating == "outer" &&
        "[&_.search-field-wrapper_.floating-label]:bg-white dark:[&_.search-field-wrapper_.floating-label]:bg-default-dark-bg"
    ]
  end

  defp color_variant("outline", "success", floating) do
    [
      "text-success-light dark:text-success-dark [&_.search-field-wrapper:not(:has(.search-field-error))]:border-success-light",
      "dark:[&_.search-field-wrapper:not(:has(.search-field-error))]:border-success-dark",
      "[&_.search-field-wrapper.search-field-error]:border-rose-700",
      "[&_.search-field-wrapper>input]:placeholder:text-success-light dark:[&_.search-field-wrapper>input]:placeholder:text-success-dark",
      "focus-within:[&_.search-field-wrapper]:ring-success-light dark:focus-within:[&_.search-field-wrapper]:ring-success-dark",
      floating == "outer" &&
        "[&_.search-field-wrapper_.floating-label]:bg-white dark:[&_.search-field-wrapper_.floating-label]:bg-default-dark-bg"
    ]
  end

  defp color_variant("outline", "warning", floating) do
    [
      "text-warning-light dark:text-warning-dark [&_.search-field-wrapper:not(:has(.search-field-error))]:border-warning-light",
      "dark:[&_.search-field-wrapper:not(:has(.search-field-error))]:border-warning-dark",
      "[&_.search-field-wrapper.search-field-error]:border-rose-700",
      "[&_.search-field-wrapper>input]:placeholder:text-warning-light dark:[&_.search-field-wrapper>input]:placeholder:text-warning-dark",
      "focus-within:[&_.search-field-wrapper]:ring-warning-light dark:focus-within:[&_.search-field-wrapper]:ring-warning-dark",
      floating == "outer" &&
        "[&_.search-field-wrapper_.floating-label]:bg-white dark:[&_.search-field-wrapper_.floating-label]:bg-default-dark-bg"
    ]
  end

  defp color_variant("outline", "danger", floating) do
    [
      "text-danger-light dark:text-danger-dark [&_.search-field-wrapper:not(:has(.search-field-error))]:border-danger-light",
      "dark:[&_.search-field-wrapper:not(:has(.search-field-error))]:border-danger-dark",
      "[&_.search-field-wrapper.search-field-error]:border-rose-700",
      "[&_.search-field-wrapper>input]:placeholder:text-danger-light dark:[&_.search-field-wrapper>input]:placeholder:text-danger-dark",
      "focus-within:[&_.search-field-wrapper]:ring-danger-light dark:focus-within:[&_.search-field-wrapper]:ring-danger-dark",
      floating == "outer" &&
        "[&_.search-field-wrapper_.floating-label]:bg-white dark:[&_.search-field-wrapper_.floating-label]:bg-default-dark-bg"
    ]
  end

  defp color_variant("outline", "info", floating) do
    [
      "text-info-light dark:text-info-dark [&_.search-field-wrapper:not(:has(.search-field-error))]:border-info-light",
      "dark:[&_.search-field-wrapper:not(:has(.search-field-error))]:border-info-dark",
      "[&_.search-field-wrapper.search-field-error]:border-rose-700",
      "[&_.search-field-wrapper>input]:placeholder:text-info-light dark:[&_.search-field-wrapper>input]:placeholder:text-info-dark",
      "focus-within:[&_.search-field-wrapper]:ring-info-light dark:focus-within:[&_.search-field-wrapper]:ring-info-dark",
      floating == "outer" &&
        "[&_.search-field-wrapper_.floating-label]:bg-white dark:[&_.search-field-wrapper_.floating-label]:bg-default-dark-bg"
    ]
  end

  defp color_variant("outline", "misc", floating) do
    [
      "text-misc-light dark:text-misc-dark [&_.search-field-wrapper:not(:has(.search-field-error))]:border-misc-light",
      "dark:[&_.search-field-wrapper:not(:has(.search-field-error))]:border-misc-dark",
      "[&_.search-field-wrapper.search-field-error]:border-rose-700",
      "[&_.search-field-wrapper>input]:placeholder:text-misc-light dark:[&_.search-field-wrapper>input]:placeholder:text-misc-dark",
      "focus-within:[&_.search-field-wrapper]:ring-misc-light dark:focus-within:[&_.search-field-wrapper]:ring-misc-dark",
      floating == "outer" &&
        "[&_.search-field-wrapper_.floating-label]:bg-white dark:[&_.search-field-wrapper_.floating-label]:bg-default-dark-bg"
    ]
  end

  defp color_variant("outline", "dawn", floating) do
    [
      "text-dawn-light dark:text-dawn-dark [&_.search-field-wrapper:not(:has(.search-field-error))]:border-dawn-light",
      "dark:[&_.search-field-wrapper:not(:has(.search-field-error))]:border-dawn-dark",
      "[&_.search-field-wrapper.search-field-error]:border-rose-700",
      "[&_.search-field-wrapper>input]:placeholder:text-dawn-light dark:[&_.search-field-wrapper>input]:placeholder:text-dawn-dark",
      "focus-within:[&_.search-field-wrapper]:ring-dawn-light dark:focus-within:[&_.search-field-wrapper]:ring-dawn-dark",
      floating == "outer" &&
        "[&_.search-field-wrapper_.floating-label]:bg-white dark:[&_.search-field-wrapper_.floating-label]:bg-default-dark-bg"
    ]
  end

  defp color_variant("outline", "silver", floating) do
    [
      "text-silver-light dark:text-silver-dark [&_.search-field-wrapper:not(:has(.search-field-error))]:border-silver-light",
      "dark:[&_.search-field-wrapper:not(:has(.search-field-error))]:border-silver-dark",
      "[&_.search-field-wrapper.search-field-error]:border-rose-700",
      "[&_.search-field-wrapper>input]:placeholder:text-silver-light dark:[&_.search-field-wrapper>input]:placeholder:text-silver-dark",
      "focus-within:[&_.search-field-wrapper]:ring-silver-light dark:focus-within:[&_.search-field-wrapper]:ring-silver-dark",
      floating == "outer" &&
        "[&_.search-field-wrapper_.floating-label]:bg-white dark:[&_.search-field-wrapper_.floating-label]:bg-default-dark-bg"
    ]
  end

  defp color_variant("default", "white", floating) do
    [
      "[&_.search-field-wrapper]:bg-white text-form-white-text",
      "[&_.search-field-wrapper.search-field-error]:border-rose-700",
      "[&_.search-field-wrapper>input]:placeholder:text-form-white-text focus-within:[&_.search-field-wrapper]:ring-form-white-focus",
      floating == "outer" && "[&_.search-field-wrapper_.floating-label]:bg-white"
    ]
  end

  defp color_variant("default", "natural", floating) do
    [
      "text-black dark:text-white [&_.search-field-wrapper:not(:has(.search-field-error))]:bg-natural-light",
      "dark:[&_.search-field-wrapper:not(:has(.search-field-error))]:bg-natural-dark",
      "[&_.search-field-wrapper.search-field-error]:bg-rose-700",
      "[&_.search-field-wrapper>input]:placeholder:text-white dark:[&_.search-field-wrapper>input]:placeholder:text-black",
      "[&_.search-field-wrapper>input]:text-white dark:[&_.search-field-wrapper>input]:text-black",
      "focus-within:[&_.search-field-wrapper]:ring-natural-light dark:focus-within:[&_.search-field-wrapper]:ring-natural-dark",
      floating == "outer" &&
        "[&_.search-field-wrapper_.floating-label]:bg-natural-light dark:[&_.search-field-wrapper_.floating-label]:bg-natural-dark"
    ]
  end

  defp color_variant("default", "primary", floating) do
    [
      "text-black dark:text-white [&_.search-field-wrapper:not(:has(.search-field-error))]:bg-primary-light",
      "dark:[&_.search-field-wrapper:not(:has(.search-field-error))]:bg-primary-dark",
      "[&_.search-field-wrapper.search-field-error]:bg-rose-700",
      "[&_.search-field-wrapper>input]:placeholder:text-white dark:[&_.search-field-wrapper>input]:placeholder:text-black",
      "[&_.search-field-wrapper>input]:text-white dark:[&_.search-field-wrapper>input]:text-black",
      "focus-within:[&_.search-field-wrapper]:ring-primary-light dark:focus-within:[&_.search-field-wrapper]:ring-primary-dark",
      floating == "outer" &&
        "[&_.search-field-wrapper_.floating-label]:bg-primary-light dark:[&_.search-field-wrapper_.floating-label]:bg-primary-dark"
    ]
  end

  defp color_variant("default", "secondary", floating) do
    [
      "text-black dark:text-white [&_.search-field-wrapper:not(:has(.search-field-error))]:bg-secondary-light",
      "dark:[&_.search-field-wrapper:not(:has(.search-field-error))]:bg-secondary-dark",
      "[&_.search-field-wrapper.search-field-error]:bg-rose-700",
      "[&_.search-field-wrapper>input]:placeholder:text-white dark:[&_.search-field-wrapper>input]:placeholder:text-black",
      "[&_.search-field-wrapper>input]:text-white dark:[&_.search-field-wrapper>input]:text-black",
      "focus-within:[&_.search-field-wrapper]:ring-secondary-light dark:focus-within:[&_.search-field-wrapper]:ring-secondary-dark",
      floating == "outer" &&
        "[&_.search-field-wrapper_.floating-label]:bg-secondary-light dark:[&_.search-field-wrapper_.floating-label]:bg-secondary-dark"
    ]
  end

  defp color_variant("default", "success", floating) do
    [
      "text-black dark:text-white [&_.search-field-wrapper:not(:has(.search-field-error))]:bg-success-light",
      "dark:[&_.search-field-wrapper:not(:has(.search-field-error))]:bg-success-dark",
      "[&_.search-field-wrapper.search-field-error]:bg-rose-700",
      "[&_.search-field-wrapper>input]:placeholder:text-white dark:[&_.search-field-wrapper>input]:placeholder:text-black",
      "[&_.search-field-wrapper>input]:text-white dark:[&_.search-field-wrapper>input]:text-black",
      "focus-within:[&_.search-field-wrapper]:ring-success-light dark:focus-within:[&_.search-field-wrapper]:ring-success-dark",
      floating == "outer" &&
        "[&_.search-field-wrapper_.floating-label]:bg-success-light dark:[&_.search-field-wrapper_.floating-label]:bg-success-dark"
    ]
  end

  defp color_variant("default", "warning", floating) do
    [
      "text-black dark:text-white [&_.search-field-wrapper:not(:has(.search-field-error))]:bg-warning-light",
      "dark:[&_.search-field-wrapper:not(:has(.search-field-error))]:bg-warning-dark",
      "[&_.search-field-wrapper.search-field-error]:bg-rose-700",
      "[&_.search-field-wrapper>input]:placeholder:text-white dark:[&_.search-field-wrapper>input]:placeholder:text-black",
      "[&_.search-field-wrapper>input]:text-white dark:[&_.search-field-wrapper>input]:text-black",
      "focus-within:[&_.search-field-wrapper]:ring-warning-light dark:focus-within:[&_.search-field-wrapper]:ring-warning-dark",
      floating == "outer" &&
        "[&_.search-field-wrapper_.floating-label]:bg-warning-light dark:[&_.search-field-wrapper_.floating-label]:bg-warning-dark"
    ]
  end

  defp color_variant("default", "danger", floating) do
    [
      "text-black dark:text-white [&_.search-field-wrapper:not(:has(.search-field-error))]:bg-danger-light",
      "dark:[&_.search-field-wrapper:not(:has(.search-field-error))]:bg-danger-dark",
      "[&_.search-field-wrapper.search-field-error]:bg-rose-700",
      "[&_.search-field-wrapper>input]:placeholder:text-white dark:[&_.search-field-wrapper>input]:placeholder:text-black",
      "[&_.search-field-wrapper>input]:text-white dark:[&_.search-field-wrapper>input]:text-black",
      "focus-within:[&_.search-field-wrapper]:ring-danger-light dark:focus-within:[&_.search-field-wrapper]:ring-danger-dark",
      floating == "outer" &&
        "[&_.search-field-wrapper_.floating-label]:bg-danger-light dark:[&_.search-field-wrapper_.floating-label]:bg-danger-dark"
    ]
  end

  defp color_variant("default", "info", floating) do
    [
      "text-black dark:text-white [&_.search-field-wrapper:not(:has(.search-field-error))]:bg-info-light",
      "dark:[&_.search-field-wrapper:not(:has(.search-field-error))]:bg-info-dark",
      "[&_.search-field-wrapper.search-field-error]:bg-rose-700",
      "[&_.search-field-wrapper>input]:placeholder:text-white dark:[&_.search-field-wrapper>input]:placeholder:text-black",
      "[&_.search-field-wrapper>input]:text-white dark:[&_.search-field-wrapper>input]:text-black",
      "focus-within:[&_.search-field-wrapper]:ring-info-light dark:focus-within:[&_.search-field-wrapper]:ring-info-dark",
      floating == "outer" &&
        "[&_.search-field-wrapper_.floating-label]:bg-info-light dark:[&_.search-field-wrapper_.floating-label]:bg-info-dark"
    ]
  end

  defp color_variant("default", "misc", floating) do
    [
      "text-black dark:text-white [&_.search-field-wrapper:not(:has(.search-field-error))]:bg-misc-light",
      "dark:[&_.search-field-wrapper:not(:has(.search-field-error))]:bg-misc-dark",
      "[&_.search-field-wrapper.search-field-error]:bg-rose-700",
      "[&_.search-field-wrapper>input]:placeholder:text-white dark:[&_.search-field-wrapper>input]:placeholder:text-black",
      "[&_.search-field-wrapper>input]:text-white dark:[&_.search-field-wrapper>input]:text-black",
      "focus-within:[&_.search-field-wrapper]:ring-misc-light dark:focus-within:[&_.search-field-wrapper]:ring-misc-dark",
      floating == "outer" &&
        "[&_.search-field-wrapper_.floating-label]:bg-misc-light dark:[&_.search-field-wrapper_.floating-label]:bg-misc-dark"
    ]
  end

  defp color_variant("default", "dawn", floating) do
    [
      "text-black dark:text-white [&_.search-field-wrapper:not(:has(.search-field-error))]:bg-dawn-light",
      "dark:[&_.search-field-wrapper:not(:has(.search-field-error))]:bg-dawn-dark",
      "[&_.search-field-wrapper.search-field-error]:bg-rose-700",
      "[&_.search-field-wrapper>input]:placeholder:text-white dark:[&_.search-field-wrapper>input]:placeholder:text-black",
      "[&_.search-field-wrapper>input]:text-white dark:[&_.search-field-wrapper>input]:text-black",
      "focus-within:[&_.search-field-wrapper]:ring-dawn-light dark:focus-within:[&_.search-field-wrapper]:ring-dawn-dark",
      floating == "outer" &&
        "[&_.search-field-wrapper_.floating-label]:bg-dawn-light dark:[&_.search-field-wrapper_.floating-label]:bg-dawn-dark"
    ]
  end

  defp color_variant("default", "silver", floating) do
    [
      "text-black dark:text-white [&_.search-field-wrapper:not(:has(.search-field-error))]:bg-silver-light",
      "dark:[&_.search-field-wrapper:not(:has(.search-field-error))]:bg-silver-dark",
      "[&_.search-field-wrapper.search-field-error]:bg-rose-700",
      "[&_.search-field-wrapper>input]:placeholder:text-white dark:[&_.search-field-wrapper>input]:placeholder:text-black",
      "[&_.search-field-wrapper>input]:text-white dark:[&_.search-field-wrapper>input]:text-black",
      "focus-within:[&_.search-field-wrapper]:ring-silver-light dark:focus-within:[&_.search-field-wrapper]:ring-silver-dark",
      floating == "outer" &&
        "[&_.search-field-wrapper_.floating-label]:bg-silver-light dark:[&_.search-field-wrapper_.floating-label]:bg-silver-dark"
    ]
  end

  defp color_variant("default", "dark", floating) do
    [
      "[&_.search-field-wrapper]:bg-default-dark-bg text-default-dark-bg [&_.search-field-wrapper]:text-base-text-dark",
      "[&_.search-field-wrapper.search-field-error]:border-rose-700",
      "[&_.search-field-wrapper>input]:placeholder:text-base-text-dark focus-within:[&_.search-field-wrapper]:ring-bordered-dark-border",
      floating == "outer" && "[&_.search-field-wrapper_.floating-label]:bg-default-dark-bg"
    ]
  end

  defp color_variant("bordered", "white", floating) do
    [
      "[&_.search-field-wrapper]:bg-white [&_.search-field-wrapper]:border-transparent text-form-white-text",
      "[&_.search-field-wrapper>input]:placeholder:text-form-white-text",
      floating == "outer" && "[&_.search-field-wrapper_.floating-label]:bg-white"
    ]
  end

  defp color_variant("bordered", "natural", floating) do
    [
      "text-natural-bordered-text-light dark:text-natural-bordered-text-dark [&_.search-field-wrapper:not(:has(.search-field-error))]:border-natural-bordered-text-light",
      "[&_.search-field-wrapper:not(:has(.search-field-error))]:bg-natural-bordered-bg-light",
      "dark:[&_.search-field-wrapper:not(:has(.search-field-error))]:bg-natural-bordered-bg-dark",
      "dark:[&_.search-field-wrapper:not(:has(.search-field-error))]:border-silver-light",
      "[&_.search-field-wrapper.search-field-error]:bg-rose-700",
      "[&_.search-field-wrapper>input]:placeholder:text-natural-bordered-text-light dark:[&_.search-field-wrapper>input]:placeholder:text-natural-bordered-text-dark",
      "focus-within:[&_.search-field-wrapper]:ring-natural-light dark:focus-within:[&_.search-field-wrapper]:ring-natural-dark",
      floating == "outer" &&
        "[&_.search-field-wrapper_.floating-label]:bg-silver-light dark:[&_.search-field-wrapper_.floating-label]:bg-silver-dark"
    ]
  end

  defp color_variant("bordered", "primary", floating) do
    [
      "text-primary-bordered-text-light dark:text-primary-bordered-text-dark [&_.search-field-wrapper:not(:has(.search-field-error))]:border-primary-bordered-text-light",
      "[&_.search-field-wrapper:not(:has(.search-field-error))]:bg-primary-bordered-bg-light",
      "dark:[&_.search-field-wrapper:not(:has(.search-field-error))]:bg-natural-bordered-bg-dark",
      "dark:[&_.search-field-wrapper:not(:has(.search-field-error))]:border-primary-bordered-text-dark",
      "[&_.search-field-wrapper.search-field-error]:bg-rose-700",
      "[&_.search-field-wrapper>input]:placeholder:text-primary-bordered-text-light dark:[&_.search-field-wrapper>input]:placeholder:text-primary-bordered-text-dark",
      "focus-within:[&_.search-field-wrapper]:ring-primary-light dark:focus-within:[&_.search-field-wrapper]:ring-primary-dark",
      floating == "outer" &&
        "[&_.search-field-wrapper_.floating-label]:bg-silver-light dark:[&_.search-field-wrapper_.floating-label]:bg-silver-dark"
    ]
  end

  defp color_variant("bordered", "secondary", floating) do
    [
      "text-secondary-bordered-text-light dark:text-secondary-bordered-text-dark [&_.search-field-wrapper:not(:has(.search-field-error))]:border-secondary-bordered-text-light",
      "[&_.search-field-wrapper:not(:has(.search-field-error))]:bg-secondary-bordered-bg-light",
      "dark:[&_.search-field-wrapper:not(:has(.search-field-error))]:bg-secondary-bordered-bg-dark",
      "dark:[&_.search-field-wrapper:not(:has(.search-field-error))]:border-secondary-bordered-text-dark",
      "[&_.search-field-wrapper.search-field-error]:bg-rose-700",
      "[&_.search-field-wrapper>input]:placeholder:text-secondary-bordered-text-light dark:[&_.search-field-wrapper>input]:placeholder:text-secondary-bordered-text-dark",
      "focus-within:[&_.search-field-wrapper]:ring-secondary-light dark:focus-within:[&_.search-field-wrapper]:ring-secondary-dark",
      floating == "outer" &&
        "[&_.search-field-wrapper_.floating-label]:bg-silver-light dark:[&_.search-field-wrapper_.floating-label]:bg-silver-dark"
    ]
  end

  defp color_variant("bordered", "success", floating) do
    [
      "text-success-bordered-text-light dark:text-success-bordered-text-dark [&_.search-field-wrapper:not(:has(.search-field-error))]:border-success-bordered-text-light",
      "[&_.search-field-wrapper:not(:has(.search-field-error))]:bg-success-bordered-bg-light",
      "dark:[&_.search-field-wrapper:not(:has(.search-field-error))]:bg-success-bordered-bg-dark",
      "dark:[&_.search-field-wrapper:not(:has(.search-field-error))]:border-success-bordered-text-dark",
      "[&_.search-field-wrapper.search-field-error]:bg-rose-700",
      "[&_.search-field-wrapper>input]:placeholder:text-success-bordered-text-light dark:[&_.search-field-wrapper>input]:placeholder:text-success-bordered-text-dark",
      "focus-within:[&_.search-field-wrapper]:ring-success-light dark:focus-within:[&_.search-field-wrapper]:ring-success-dark",
      floating == "outer" &&
        "[&_.search-field-wrapper_.floating-label]:bg-silver-light dark:[&_.search-field-wrapper_.floating-label]:bg-silver-dark"
    ]
  end

  defp color_variant("bordered", "warning", floating) do
    [
      "text-warning-bordered-text-light dark:text-warning-bordered-text-dark [&_.search-field-wrapper:not(:has(.search-field-error))]:border-warning-bordered-text-light",
      "[&_.search-field-wrapper:not(:has(.search-field-error))]:bg-warning-bordered-bg-light",
      "dark:[&_.search-field-wrapper:not(:has(.search-field-error))]:bg-warning-bordered-bg-dark",
      "dark:[&_.search-field-wrapper:not(:has(.search-field-error))]:border-warning-bordered-text-dark",
      "[&_.search-field-wrapper.search-field-error]:bg-rose-700",
      "[&_.search-field-wrapper>input]:placeholder:text-warning-bordered-text-light dark:[&_.search-field-wrapper>input]:placeholder:text-warning-bordered-text-dark",
      "focus-within:[&_.search-field-wrapper]:ring-warning-light dark:focus-within:[&_.search-field-wrapper]:ring-warning-dark",
      floating == "outer" &&
        "[&_.search-field-wrapper_.floating-label]:bg-silver-light dark:[&_.search-field-wrapper_.floating-label]:bg-silver-dark"
    ]
  end

  defp color_variant("bordered", "danger", floating) do
    [
      "text-danger-bordered-text-light dark:text-danger-bordered-text-dark [&_.search-field-wrapper:not(:has(.search-field-error))]:border-danger-bordered-text-light",
      "[&_.search-field-wrapper:not(:has(.search-field-error))]:bg-danger-bordered-bg-light",
      "dark:[&_.search-field-wrapper:not(:has(.search-field-error))]:bg-danger-bordered-bg-dark",
      "dark:[&_.search-field-wrapper:not(:has(.search-field-error))]:border-danger-bordered-text-dark",
      "[&_.search-field-wrapper.search-field-error]:bg-rose-700",
      "[&_.search-field-wrapper>input]:placeholder:text-danger-bordered-text-light dark:[&_.search-field-wrapper>input]:placeholder:text-danger-bordered-text-dark",
      "focus-within:[&_.search-field-wrapper]:ring-danger-light dark:focus-within:[&_.search-field-wrapper]:ring-danger-dark",
      floating == "outer" &&
        "[&_.search-field-wrapper_.floating-label]:bg-silver-light dark:[&_.search-field-wrapper_.floating-label]:bg-silver-dark"
    ]
  end

  defp color_variant("bordered", "info", floating) do
    [
      "text-info-light dark:text-info-hover-dark [&_.search-field-wrapper:not(:has(.search-field-error))]:border-info-light",
      "[&_.search-field-wrapper:not(:has(.search-field-error))]:bg-info-bordered-bg-light",
      "dark:[&_.search-field-wrapper:not(:has(.search-field-error))]:bg-info-bordered-bg-dark",
      "dark:[&_.search-field-wrapper:not(:has(.search-field-error))]:border-info-hover-dark",
      "[&_.search-field-wrapper.search-field-error]:bg-rose-700",
      "[&_.search-field-wrapper>input]:placeholder:text-info-light dark:[&_.search-field-wrapper>input]:placeholder:text-info-hover-dark",
      "focus-within:[&_.search-field-wrapper]:ring-info-light dark:focus-within:[&_.search-field-wrapper]:ring-info-dark",
      floating == "outer" &&
        "[&_.search-field-wrapper_.floating-label]:bg-silver-light dark:[&_.search-field-wrapper_.floating-label]:bg-silver-dark"
    ]
  end

  defp color_variant("bordered", "misc", floating) do
    [
      "text-misc-bordered-text-light dark:text-misc-bordered-text-dark [&_.search-field-wrapper:not(:has(.search-field-error))]:border-misc-bordered-text-light",
      "[&_.search-field-wrapper:not(:has(.search-field-error))]:bg-misc-bordered-bg-light",
      "dark:[&_.search-field-wrapper:not(:has(.search-field-error))]:bg-misc-bordered-bg-dark",
      "dark:[&_.search-field-wrapper:not(:has(.search-field-error))]:border-misc-bordered-text-dark",
      "[&_.search-field-wrapper.search-field-error]:bg-rose-700",
      "[&_.search-field-wrapper>input]:placeholder:text-misc-bordered-text-light dark:[&_.search-field-wrapper>input]:placeholder:text-misc-bordered-text-dark",
      "focus-within:[&_.search-field-wrapper]:ring-misc-light dark:focus-within:[&_.search-field-wrapper]:ring-misc-dark",
      floating == "outer" &&
        "[&_.search-field-wrapper_.floating-label]:bg-silver-light dark:[&_.search-field-wrapper_.floating-label]:bg-silver-dark"
    ]
  end

  defp color_variant("bordered", "dawn", floating) do
    [
      "text-dawn-bordered-text-light dark:text-dawn-bordered-text-dark [&_.search-field-wrapper:not(:has(.search-field-error))]:border-dawn-bordered-text-light",
      "[&_.search-field-wrapper:not(:has(.search-field-error))]:bg-dawn-bordered-bg-light",
      "dark:[&_.search-field-wrapper:not(:has(.search-field-error))]:bg-dawn-bordered-bg-dark",
      "dark:[&_.search-field-wrapper:not(:has(.search-field-error))]:border-dawn-bordered-text-dark",
      "[&_.search-field-wrapper.search-field-error]:bg-rose-700",
      "[&_.search-field-wrapper>input]:placeholder:text-dawn-bordered-text-light dark:[&_.search-field-wrapper>input]:placeholder:text-dawn-bordered-text-dark",
      "focus-within:[&_.search-field-wrapper]:ring-dawn-light dark:focus-within:[&_.search-field-wrapper]:ring-dawn-dark",
      floating == "outer" &&
        "[&_.search-field-wrapper_.floating-label]:bg-silver-light dark:[&_.search-field-wrapper_.floating-label]:bg-silver-dark"
    ]
  end

  defp color_variant("bordered", "silver", floating) do
    [
      "text-silver-bordered-text-light dark:text-silver-bordered-text-dark [&_.search-field-wrapper:not(:has(.search-field-error))]:border-silver-bordered-text-light",
      "[&_.search-field-wrapper:not(:has(.search-field-error))]:bg-silver-bordered-bg-light",
      "dark:[&_.search-field-wrapper:not(:has(.search-field-error))]:bg-silver-bordered-bg-dark",
      "dark:[&_.search-field-wrapper:not(:has(.search-field-error))]:border-silver-bordered-text-dark",
      "[&_.search-field-wrapper.search-field-error]:bg-rose-700",
      "[&_.search-field-wrapper>input]:placeholder:text-silver-bordered-text-light dark:[&_.search-field-wrapper>input]:placeholder:text-silver-bordered-text-dark",
      "focus-within:[&_.search-field-wrapper]:ring-silver-light dark:focus-within:[&_.search-field-wrapper]:ring-silver-dark",
      floating == "outer" &&
        "[&_.search-field-wrapper_.floating-label]:bg-silver-light dark:[&_.search-field-wrapper_.floating-label]:bg-silver-dark"
    ]
  end

  defp color_variant("bordered", "dark", floating) do
    [
      "[&_.search-field-wrapper]:bg-default-dark-bg text-default-dark-bg [&_.search-field-wrapper]:border-bordered-dark-border text-base-text-dark",
      "[&_.search-field-wrapper>input]:placeholder:text-base-text-dark focus-within:[&_.search-field-wrapper]:ring-bordered-dark-border",
      floating == "outer" && "[&_.search-field-wrapper_.floating-label]:bg-default-dark-bg"
    ]
  end

  defp color_variant("shadow", "natural", floating) do
    [
      "text-black dark:text-white [&_.search-field-wrapper:not(:has(.search-field-error))]:bg-natural-light",
      "dark:[&_.search-field-wrapper:not(:has(.search-field-error))]:bg-natural-dark",
      "[&_.search-field-wrapper.search-field-error]:bg-rose-700",
      "[&_.search-field-wrapper>input]:placeholder:text-white dark:[&_.search-field-wrapper>input]:placeholder:text-black",
      "[&_.search-field-wrapper>input]:text-white dark:[&_.search-field-wrapper>input]:text-black",
      "focus-within:[&_.search-field-wrapper]:ring-natural-light dark:focus-within:[&_.search-field-wrapper]:ring-natural-dark",
      "[&_.search-field-wrapper]:shadow-[0px_4px_6px_-4px_var(--color-shadow-natural)] [&_.search-field-wrapper]:shadow-[0px_10px_15px_-3px_var(--color-shadow-natural)]",
      "dark:[&_.search-field-wrapper]:shadow-none",
      floating == "outer" &&
        "[&_.search-field-wrapper_.floating-label]:bg-natural-light dark:[&_.search-field-wrapper_.floating-label]:bg-natural-dark"
    ]
  end

  defp color_variant("shadow", "primary", floating) do
    [
      "text-black dark:text-white [&_.search-field-wrapper:not(:has(.search-field-error))]:bg-primary-light",
      "dark:[&_.search-field-wrapper:not(:has(.search-field-error))]:bg-primary-dark",
      "[&_.search-field-wrapper.search-field-error]:bg-rose-700",
      "[&_.search-field-wrapper>input]:placeholder:text-white dark:[&_.search-field-wrapper>input]:placeholder:text-black",
      "[&_.search-field-wrapper>input]:text-white dark:[&_.search-field-wrapper>input]:text-black",
      "focus-within:[&_.search-field-wrapper]:ring-primary-light dark:focus-within:[&_.search-field-wrapper]:ring-primary-dark",
      "[&_.search-field-wrapper]:shadow-[0px_4px_6px_-4px_var(--color-shadow-primary)] [&_.search-field-wrapper]:shadow-[0px_10px_15px_-3px_var(--color-shadow-primary)]",
      "dark:[&_.search-field-wrapper]:shadow-none",
      floating == "outer" &&
        "[&_.search-field-wrapper_.floating-label]:bg-primary-light dark:[&_.search-field-wrapper_.floating-label]:bg-primary-dark"
    ]
  end

  defp color_variant("shadow", "secondary", floating) do
    [
      "text-black dark:text-white [&_.search-field-wrapper:not(:has(.search-field-error))]:bg-secondary-light",
      "dark:[&_.search-field-wrapper:not(:has(.search-field-error))]:bg-secondary-dark",
      "[&_.search-field-wrapper.search-field-error]:bg-rose-700",
      "[&_.search-field-wrapper>input]:placeholder:text-white dark:[&_.search-field-wrapper>input]:placeholder:text-black",
      "[&_.search-field-wrapper>input]:text-white dark:[&_.search-field-wrapper>input]:text-black",
      "focus-within:[&_.search-field-wrapper]:ring-secondary-light dark:focus-within:[&_.search-field-wrapper]:ring-secondary-dark",
      "[&_.search-field-wrapper]:shadow-[0px_4px_6px_-4px_var(--color-shadow-secondary)] [&_.search-field-wrapper]:shadow-[0px_10px_15px_-3px_var(--color-shadow-secondary)]",
      "dark:[&_.search-field-wrapper]:shadow-none",
      floating == "outer" &&
        "[&_.search-field-wrapper_.floating-label]:bg-secondary-light dark:[&_.search-field-wrapper_.floating-label]:bg-secondary-dark"
    ]
  end

  defp color_variant("shadow", "success", floating) do
    [
      "text-black dark:text-white [&_.search-field-wrapper:not(:has(.search-field-error))]:bg-success-light",
      "dark:[&_.search-field-wrapper:not(:has(.search-field-error))]:bg-success-dark",
      "[&_.search-field-wrapper.search-field-error]:bg-rose-700",
      "[&_.search-field-wrapper>input]:placeholder:text-white dark:[&_.search-field-wrapper>input]:placeholder:text-black",
      "[&_.search-field-wrapper>input]:text-white dark:[&_.search-field-wrapper>input]:text-black",
      "focus-within:[&_.search-field-wrapper]:ring-success-light dark:focus-within:[&_.search-field-wrapper]:ring-success-dark",
      "[&_.search-field-wrapper]:shadow-[0px_4px_6px_-4px_var(--color-shadow-success)] [&_.search-field-wrapper]:shadow-[0px_10px_15px_-3px_var(--color-shadow-success)]",
      "dark:[&_.search-field-wrapper]:shadow-none",
      floating == "outer" &&
        "[&_.search-field-wrapper_.floating-label]:bg-success-light dark:[&_.search-field-wrapper_.floating-label]:bg-success-dark"
    ]
  end

  defp color_variant("shadow", "warning", floating) do
    [
      "text-black dark:text-white [&_.search-field-wrapper:not(:has(.search-field-error))]:bg-warning-light",
      "dark:[&_.search-field-wrapper:not(:has(.search-field-error))]:bg-warning-dark",
      "[&_.search-field-wrapper.search-field-error]:bg-rose-700",
      "[&_.search-field-wrapper>input]:placeholder:text-white dark:[&_.search-field-wrapper>input]:placeholder:text-black",
      "[&_.search-field-wrapper>input]:text-white dark:[&_.search-field-wrapper>input]:text-black",
      "focus-within:[&_.search-field-wrapper]:ring-warning-light dark:focus-within:[&_.search-field-wrapper]:ring-warning-dark",
      "[&_.search-field-wrapper]:shadow-[0px_4px_6px_-4px_var(--color-shadow-warning)] [&_.search-field-wrapper]:shadow-[0px_10px_15px_-3px_var(--color-shadow-warning)]",
      "dark:[&_.search-field-wrapper]:shadow-none",
      floating == "outer" &&
        "[&_.search-field-wrapper_.floating-label]:bg-warning-light dark:[&_.search-field-wrapper_.floating-label]:bg-warning-dark"
    ]
  end

  defp color_variant("shadow", "danger", floating) do
    [
      "text-black dark:text-white [&_.search-field-wrapper:not(:has(.search-field-error))]:bg-danger-light",
      "dark:[&_.search-field-wrapper:not(:has(.search-field-error))]:bg-danger-dark",
      "[&_.search-field-wrapper.search-field-error]:bg-rose-700",
      "[&_.search-field-wrapper>input]:placeholder:text-white dark:[&_.search-field-wrapper>input]:placeholder:text-black",
      "[&_.search-field-wrapper>input]:text-white dark:[&_.search-field-wrapper>input]:text-black",
      "focus-within:[&_.search-field-wrapper]:ring-danger-light dark:focus-within:[&_.search-field-wrapper]:ring-danger-dark",
      "[&_.search-field-wrapper]:shadow-[0px_4px_6px_-4px_var(--color-shadow-danger)] [&_.search-field-wrapper]:shadow-[0px_10px_15px_-3px_var(--color-shadow-danger)]",
      "dark:[&_.search-field-wrapper]:shadow-none",
      floating == "outer" &&
        "[&_.search-field-wrapper_.floating-label]:bg-danger-light dark:[&_.search-field-wrapper_.floating-label]:bg-danger-dark"
    ]
  end

  defp color_variant("shadow", "info", floating) do
    [
      "text-black dark:text-white [&_.search-field-wrapper:not(:has(.search-field-error))]:bg-info-light",
      "dark:[&_.search-field-wrapper:not(:has(.search-field-error))]:bg-info-dark",
      "[&_.search-field-wrapper.search-field-error]:bg-rose-700",
      "[&_.search-field-wrapper>input]:placeholder:text-white dark:[&_.search-field-wrapper>input]:placeholder:text-black",
      "[&_.search-field-wrapper>input]:text-white dark:[&_.search-field-wrapper>input]:text-black",
      "focus-within:[&_.search-field-wrapper]:ring-info-light dark:focus-within:[&_.search-field-wrapper]:ring-info-dark",
      "[&_.search-field-wrapper]:shadow-[0px_4px_6px_-4px_var(--color-shadow-info)] [&_.search-field-wrapper]:shadow-[0px_10px_15px_-3px_var(--color-shadow-info)]",
      "dark:[&_.search-field-wrapper]:shadow-none",
      floating == "outer" &&
        "[&_.search-field-wrapper_.floating-label]:bg-info-light dark:[&_.search-field-wrapper_.floating-label]:bg-info-dark"
    ]
  end

  defp color_variant("shadow", "misc", floating) do
    [
      "text-black dark:text-white [&_.search-field-wrapper:not(:has(.search-field-error))]:bg-misc-light",
      "dark:[&_.search-field-wrapper:not(:has(.search-field-error))]:bg-misc-dark",
      "[&_.search-field-wrapper.search-field-error]:bg-rose-700",
      "[&_.search-field-wrapper>input]:placeholder:text-white dark:[&_.search-field-wrapper>input]:placeholder:text-black",
      "[&_.search-field-wrapper>input]:text-white dark:[&_.search-field-wrapper>input]:text-black",
      "focus-within:[&_.search-field-wrapper]:ring-misc-light dark:focus-within:[&_.search-field-wrapper]:ring-misc-dark",
      "[&_.search-field-wrapper]:shadow-[0px_4px_6px_-4px_var(--color-shadow-misc)] [&_.search-field-wrapper]:shadow-[0px_10px_15px_-3px_var(--color-shadow-misc)]",
      "dark:[&_.search-field-wrapper]:shadow-none",
      floating == "outer" &&
        "[&_.search-field-wrapper_.floating-label]:bg-misc-light dark:[&_.search-field-wrapper_.floating-label]:bg-misc-dark"
    ]
  end

  defp color_variant("shadow", "dawn", floating) do
    [
      "text-black dark:text-white [&_.search-field-wrapper:not(:has(.search-field-error))]:bg-dawn-light",
      "dark:[&_.search-field-wrapper:not(:has(.search-field-error))]:bg-dawn-dark",
      "[&_.search-field-wrapper.search-field-error]:bg-rose-700",
      "[&_.search-field-wrapper>input]:placeholder:text-white dark:[&_.search-field-wrapper>input]:placeholder:text-black",
      "[&_.search-field-wrapper>input]:text-white dark:[&_.search-field-wrapper>input]:text-black",
      "focus-within:[&_.search-field-wrapper]:ring-dawn-light dark:focus-within:[&_.search-field-wrapper]:ring-dawn-dark",
      "[&_.search-field-wrapper]:shadow-[0px_4px_6px_-4px_var(--color-shadow-dawn)] [&_.search-field-wrapper]:shadow-[0px_10px_15px_-3px_var(--color-shadow-dawn)]",
      "dark:[&_.search-field-wrapper]:shadow-none",
      floating == "outer" &&
        "[&_.search-field-wrapper_.floating-label]:bg-dawn-light dark:[&_.search-field-wrapper_.floating-label]:bg-dawn-dark"
    ]
  end

  defp color_variant("shadow", "silver", floating) do
    [
      "text-black dark:text-white [&_.search-field-wrapper:not(:has(.search-field-error))]:bg-silver-light",
      "dark:[&_.search-field-wrapper:not(:has(.search-field-error))]:bg-silver-dark",
      "[&_.search-field-wrapper.search-field-error]:bg-rose-700",
      "[&_.search-field-wrapper>input]:placeholder:text-white dark:[&_.search-field-wrapper>input]:placeholder:text-black",
      "[&_.search-field-wrapper>input]:text-white dark:[&_.search-field-wrapper>input]:text-black",
      "focus-within:[&_.search-field-wrapper]:ring-silver-light dark:focus-within:[&_.search-field-wrapper]:ring-silver-dark",
      "[&_.search-field-wrapper]:shadow-[0px_4px_6px_-4px_var(--color-shadow-silver)] [&_.search-field-wrapper]:shadow-[0px_10px_15px_-3px_var(--color-shadow-silver)]",
      "dark:[&_.search-field-wrapper]:shadow-none",
      floating == "outer" &&
        "[&_.search-field-wrapper_.floating-label]:bg-silver-light dark:[&_.search-field-wrapper_.floating-label]:bg-silver-dark"
    ]
  end

  defp color_variant("transparent", "natural", _) do
    [
      "text-natural-light dark:text-natural-dark",
      "[&_.search-field-wrapper>input]:placeholder:text-natural-light",
      "dark:[&_.search-field-wrapper>input]:placeholder:text-natural-dark",
      "focus-within:[&_.search-field-wrapper]:ring-transparent"
    ]
  end

  defp color_variant("transparent", "primary", _) do
    [
      "text-primary-light dark:text-primary-dark",
      "[&_.search-field-wrapper>input]:placeholder:text-primary-light",
      "dark:[&_.search-field-wrapper>input]:placeholder:text-primary-dark",
      "focus-within:[&_.search-field-wrapper]:ring-transparent"
    ]
  end

  defp color_variant("transparent", "secondary", _) do
    [
      "text-secondary-light dark:text-secondary-dark",
      "[&_.search-field-wrapper>input]:placeholder:text-secondary-light",
      "dark:[&_.search-field-wrapper>input]:placeholder:text-secondary-dark",
      "focus-within:[&_.search-field-wrapper]:ring-transparent"
    ]
  end

  defp color_variant("transparent", "success", _) do
    [
      "text-success-light dark:text-success-dark",
      "[&_.search-field-wrapper>input]:placeholder:text-success-light",
      "dark:[&_.search-field-wrapper>input]:placeholder:text-success-dark",
      "focus-within:[&_.search-field-wrapper]:ring-transparent"
    ]
  end

  defp color_variant("transparent", "warning", _) do
    [
      "text-warning-light dark:text-warning-dark",
      "[&_.search-field-wrapper>input]:placeholder:text-warning-light",
      "dark:[&_.search-field-wrapper>input]:placeholder:text-warning-dark",
      "focus-within:[&_.search-field-wrapper]:ring-transparent"
    ]
  end

  defp color_variant("transparent", "danger", _) do
    [
      "text-danger-light dark:text-danger-dark",
      "[&_.search-field-wrapper>input]:placeholder:text-danger-light",
      "dark:[&_.search-field-wrapper>input]:placeholder:text-danger-dark",
      "focus-within:[&_.search-field-wrapper]:ring-transparent"
    ]
  end

  defp color_variant("transparent", "info", _) do
    [
      "text-info-light dark:text-info-dark",
      "[&_.search-field-wrapper>input]:placeholder:text-info-light",
      "dark:[&_.search-field-wrapper>input]:placeholder:text-info-dark",
      "focus-within:[&_.search-field-wrapper]:ring-transparent"
    ]
  end

  defp color_variant("transparent", "misc", _) do
    [
      "text-misc-light dark:text-misc-dark",
      "[&_.search-field-wrapper>input]:placeholder:text-misc-light",
      "dark:[&_.search-field-wrapper>input]:placeholder:text-misc-dark",
      "focus-within:[&_.search-field-wrapper]:ring-transparent"
    ]
  end

  defp color_variant("transparent", "dawn", _) do
    [
      "text-dawn-light dark:text-dawn-dark",
      "[&_.search-field-wrapper>input]:placeholder:text-dawn-light",
      "dark:[&_.search-field-wrapper>input]:placeholder:text-dawn-dark",
      "focus-within:[&_.search-field-wrapper]:ring-transparent"
    ]
  end

  defp color_variant("transparent", "silver", _) do
    [
      "text-silver-light dark:text-silver-dark",
      "[&_.search-field-wrapper>input]:placeholder:text-silver-light",
      "dark:[&_.search-field-wrapper>input]:placeholder:text-silver-dark",
      "focus-within:[&_.search-field-wrapper]:ring-transparent"
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
