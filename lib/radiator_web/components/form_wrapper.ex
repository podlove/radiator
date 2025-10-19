defmodule RadiatorWeb.Components.FormWrapper do
  @moduledoc """
  The `RadiatorWeb.Components.FormWrapper` module provides a flexible and customizable form
  wrapper component for Phoenix applications. It offers various options for styling,
  size, and layout to suit different form designs and requirements.

  ### Features:
  - **Customizable Styles:** Choose from multiple color themes, border styles, and design variants.
  - **Layout Flexibility:** Control padding, spacing, and border radius to adjust the form's appearance.
  - **Form Slots:** Define inner content and actions slots to organize form elements and buttons.
  - **Global Attribute Support:** Allows for additional attributes like `autocomplete`, `method`,
  and more to be merged with component defaults.

  This component is ideal for wrapping forms with consistent styles and structure across an application.

  **Documentation:** https://mishka.tools/chelekom/docs/forms
  """

  use Phoenix.Component

  @doc """
  Renders a `form_wrapper` component that supports custom styles and input fields.

  It allows for the inclusion of multiple input fields and form actions, such as a submit button,
  within a consistent layout.

  ## Examples

  ```elixir
  <.form_wrapper class="space-y-10">
    <div class="grid lg:grid-cols-2 gap-2">
      <.text_field name="name1" space="small" color="light"/>
      ...
    </div>
  </.form_wrapper>
  ```
  """
  @doc type: :component
  attr :id, :string,
    default: nil,
    doc: "A unique identifier is used to manage state and interaction"

  attr :class, :string, default: nil, doc: "Custom CSS class for additional styling"
  attr :color, :string, default: "", doc: "Determines color theme"
  attr :variant, :string, default: "", doc: "Determines the style"
  attr :border, :string, default: "", doc: "Determines border style"
  attr :rounded, :string, default: "", doc: "Determines the border radius"
  attr :padding, :string, default: "", doc: "Determines padding for items"
  attr :space, :string, default: "", doc: "Space between items"
  attr :form_wrapper_class, :string, default: "", doc: "Custom classes form wrapper"
  attr :action_wrapper_class, :string, default: "", doc: "Custom classes action wrapper"

  attr :size, :string,
    default: "",
    doc:
      "Determines the overall size of the elements, including padding, font size, and other items"

  attr :for, :any, required: false, doc: "the data structure for the form"
  attr :as, :any, default: nil, doc: "the server side parameter to collect all input under"

  attr :rest, :global,
    include: ~w(autocomplete name rel action enctype method novalidate target multipart),
    doc:
      "Global attributes can define defaults which are merged with attributes provided by the caller"

  slot :inner_block, required: true, doc: "Inner block that renders HEEx content"
  slot :actions, required: false, doc: "the slot for form actions, such as a submit button"

  def form_wrapper(assigns) do
    ~H"""
    <.form
      :let={f}
      for={@for}
      as={@as}
      id={@id}
      class={[
        color_variant(@variant, @color),
        padding_class(@padding),
        rounded_size(@rounded),
        border_class(@border, @variant),
        space_class(@space),
        size_class(@size),
        @class
      ]}
      {@rest}
    >
      <div class={["wrapper-form", @form_wrapper_class]}>
        {render_slot(@inner_block, f)}
        <div :for={action <- @actions} class={["wrapper-form-actions", @action_wrapper_class]}>
          {render_slot(action, f)}
        </div>
      </div>
    </.form>
    """
  end

  @doc type: :component
  attr :id, :string,
    default: nil,
    doc: "A unique identifier is used to manage state and interaction"

  attr :for, :any, required: true, doc: "the data structure for the form"
  attr :as, :any, default: nil, doc: "the server side parameter to collect all input under"

  attr :extra_classes, :list,
    default: [
      "[&_.wrapper-form]:mt-10 [&_.wrapper-form]:space-y-8",
      "[&_.wrapper-form]:bg-white [&_.wrapper-form-actions]:mt-2",
      "[&_.wrapper-form-actions]:flex [&_.wrapper-form-actions]:items-center",
      "[&_.wrapper-form-actions]:justify-between [&_.wrapper-form-actions]:gap-6"
    ],
    doc: "additional classes to apply to the form wrapper"

  attr :rest, :global,
    include: ~w(autocomplete name rel action enctype method novalidate target multipart),
    doc: "the arbitrary HTML attributes to apply to the form tag"

  slot :inner_block, required: true
  slot :actions, doc: "the slot for form actions, such as a submit button"

  def simple_form(assigns) do
    ~H"""
    <.form_wrapper :let={f} class={@extra_classes} {assigns}>
      {render_slot(@inner_block, f)}
    </.form_wrapper>
    """
  end

  defp size_class("extra_small"), do: "text-xs"

  defp size_class("small"), do: "text-sm"

  defp size_class("medium"), do: "text-base"

  defp size_class("large"), do: "text-lg"

  defp size_class("extra_large"), do: "text-xl"

  defp size_class(params) when is_binary(params), do: params

  defp rounded_size("extra_small"), do: "rounded-sm"

  defp rounded_size("small"), do: "rounded"

  defp rounded_size("medium"), do: "rounded-md"

  defp rounded_size("large"), do: "rounded-lg"

  defp rounded_size("extra_large"), do: "rounded-xl"

  defp rounded_size("full"), do: "rounded-full"

  defp rounded_size(params) when is_binary(params), do: params

  defp border_class(_, variant) when variant in ["default", "shadow", "transparent"],
    do: nil

  defp border_class("extra_small", _), do: "border"
  defp border_class("small", _), do: "border-2"
  defp border_class("medium", _), do: "border-[3px]"
  defp border_class("large", _), do: "border-4"
  defp border_class("extra_large", _), do: "border-[5px]"
  defp border_class(params, _) when is_binary(params), do: params

  defp padding_class("extra_small"), do: "p-2"

  defp padding_class("small"), do: "p-3"

  defp padding_class("medium"), do: "p-4"

  defp padding_class("large"), do: "p-5"

  defp padding_class("extra_large"), do: "p-6"

  defp padding_class(params) when is_binary(params), do: params

  defp space_class("extra_small"), do: "[&_.wrapper-form]:space-y-2"

  defp space_class("small"), do: "[&_.wrapper-form]:space-y-3"

  defp space_class("medium"), do: "[&_.wrapper-form]:space-y-4"

  defp space_class("large"), do: "[&_.wrapper-form]:space-y-5"

  defp space_class("extra_large"), do: "[&_.wrapper-form]:space-y-6"

  defp space_class(params) when is_binary(params), do: params

  defp color_variant("base", _) do
    [
      "bg-white text-base-text-light border-base-border-light shadow-sm",
      "dark:bg-base-bg-dark dark:text-base-text-dark dark:border-base-border-dark"
    ]
  end

  defp color_variant("default", "white") do
    [
      "bg-white text-black"
    ]
  end

  defp color_variant("default", "dark") do
    [
      "bg-default-dark-bg text-white"
    ]
  end

  defp color_variant("default", "natural") do
    [
      "bg-natural-light text-white dark:bg-natural-dark dark:text-black"
    ]
  end

  defp color_variant("default", "primary") do
    [
      "bg-primary-light text-white dark:bg-primary-dark dark:text-black"
    ]
  end

  defp color_variant("default", "secondary") do
    [
      "bg-secondary-light text-white dark:bg-secondary-dark dark:text-black"
    ]
  end

  defp color_variant("default", "success") do
    [
      "bg-success-light text-white dark:bg-success-dark dark:text-black"
    ]
  end

  defp color_variant("default", "warning") do
    [
      "bg-warning-light text-white dark:bg-warning-dark dark:text-black"
    ]
  end

  defp color_variant("default", "danger") do
    [
      "bg-danger-light text-white dark:bg-danger-dark dark:text-black"
    ]
  end

  defp color_variant("default", "info") do
    [
      "bg-info-light text-white dark:bg-info-dark dark:text-black"
    ]
  end

  defp color_variant("default", "misc") do
    [
      "bg-misc-light text-white dark:bg-misc-dark dark:text-black"
    ]
  end

  defp color_variant("default", "dawn") do
    [
      "bg-dawn-light text-white dark:bg-dawn-dark dark:text-black"
    ]
  end

  defp color_variant("default", "silver") do
    [
      "bg-silver-light text-white dark:bg-silver-dark dark:text-black"
    ]
  end

  defp color_variant("outline", "natural") do
    [
      "text-natural-light border-natural-light dark:text-natural-dark dark:border-natural-dark"
    ]
  end

  defp color_variant("outline", "primary") do
    [
      "text-primary-light border-primary-light dark:text-primary-dark dark:border-primary-dark"
    ]
  end

  defp color_variant("outline", "secondary") do
    [
      "text-secondary-light border-secondary-light dark:text-secondary-dark dark:border-secondary-dark"
    ]
  end

  defp color_variant("outline", "success") do
    [
      "text-success-light border-success-light dark:text-success-dark dark:border-success-dark"
    ]
  end

  defp color_variant("outline", "warning") do
    [
      "text-warning-light border-warning-light dark:text-warning-dark dark:border-warning-dark"
    ]
  end

  defp color_variant("outline", "danger") do
    [
      "text-danger-light border-danger-light dark:text-danger-dark dark:border-danger-dark"
    ]
  end

  defp color_variant("outline", "info") do
    [
      "text-info-light border-info-light dark:text-info-dark dark:border-info-dark"
    ]
  end

  defp color_variant("outline", "misc") do
    [
      "text-misc-light border-misc-light dark:text-misc-dark dark:border-misc-dark"
    ]
  end

  defp color_variant("outline", "dawn") do
    [
      "text-dawn-light border-dawn-light dark:text-dawn-dark dark:border-dawn-dark"
    ]
  end

  defp color_variant("outline", "silver") do
    [
      "text-silver-light border-silver-light dark:text-silver-dark dark:border-silver-dark"
    ]
  end

  defp color_variant("shadow", "natural") do
    [
      "bg-natural-light text-white dark:bg-natural-dark dark:text-black",
      "shadow-[0px_4px_6px_-4px_var(--color-shadow-natural)] shadow-[0px_10px_15px_-3px_var(--color-shadow-natural)] dark:shadow-none"
    ]
  end

  defp color_variant("shadow", "primary") do
    [
      "bg-primary-light text-white dark:bg-primary-dark dark:text-black",
      "shadow-[0px_4px_6px_-4px_var(--color-shadow-primary)] shadow-[0px_10px_15px_-3px_var(--color-shadow-primary)] dark:shadow-none"
    ]
  end

  defp color_variant("shadow", "secondary") do
    [
      "bg-secondary-light text-white dark:bg-secondary-dark dark:text-black",
      "shadow-[0px_4px_6px_-4px_var(--color-shadow-secondary)] shadow-[0px_10px_15px_-3px_var(--color-shadow-secondary)] dark:shadow-none"
    ]
  end

  defp color_variant("shadow", "success") do
    [
      "bg-success-light text-white dark:bg-success-dark dark:text-black",
      "shadow-[0px_4px_6px_-4px_var(--color-shadow-success)] shadow-[0px_10px_15px_-3px_var(--color-shadow-success)] dark:shadow-none"
    ]
  end

  defp color_variant("shadow", "warning") do
    [
      "bg-warning-light text-white dark:bg-warning-dark dark:text-black",
      "shadow-[0px_4px_6px_-4px_var(--color-shadow-warning)] shadow-[0px_10px_15px_-3px_var(--color-shadow-warning)] dark:shadow-none"
    ]
  end

  defp color_variant("shadow", "danger") do
    [
      "bg-danger-light text-white dark:bg-danger-dark dark:text-black",
      "shadow-[0px_4px_6px_-4px_var(--color-shadow-danger)] shadow-[0px_10px_15px_-3px_var(--color-shadow-danger)] dark:shadow-none"
    ]
  end

  defp color_variant("shadow", "info") do
    [
      "bg-info-light text-white dark:bg-info-dark dark:text-black",
      "shadow-[0px_4px_6px_-4px_var(--color-shadow-info)] shadow-[0px_10px_15px_-3px_var(--color-shadow-info)] dark:shadow-none"
    ]
  end

  defp color_variant("shadow", "misc") do
    [
      "bg-misc-light text-white dark:bg-misc-dark dark:text-black",
      "shadow-[0px_4px_6px_-4px_var(--color-shadow-misc)] shadow-[0px_10px_15px_-3px_var(--color-shadow-misc)] dark:shadow-none"
    ]
  end

  defp color_variant("shadow", "dawn") do
    [
      "bg-dawn-light text-white dark:bg-dawn-dark dark:text-black",
      "shadow-[0px_4px_6px_-4px_var(--color-shadow-dawn)] shadow-[0px_10px_15px_-3px_var(--color-shadow-dawn)] dark:shadow-none"
    ]
  end

  defp color_variant("shadow", "silver") do
    [
      "bg-silver-light text-white dark:bg-silver-dark dark:text-black",
      "shadow-[0px_4px_6px_-4px_var(--color-shadow-silver)] shadow-[0px_10px_15px_-3px_var(--color-shadow-silver)] dark:shadow-none"
    ]
  end

  defp color_variant("bordered", "white") do
    [
      "bg-white text-black border-bordered-white-border"
    ]
  end

  defp color_variant("bordered", "dark") do
    [
      "bg-default-dark-bg text-white border-silver-hover-light"
    ]
  end

  defp color_variant("bordered", "natural") do
    [
      "text-natural-bordered-text-light border-natural-bordered-text-light bg-natural-bordered-bg-light",
      "dark:text-natural-hover-dark dark:border-natural-hover-dark dark:bg-natural-bordered-bg-dark"
    ]
  end

  defp color_variant("bordered", "primary") do
    [
      "text-primary-bordered-text-light border-primary-bordered-text-light bg-primary-bordered-bg-light",
      "dark:text-primary-hover-dark dark:border-primary-hover-dark dark:bg-primary-bordered-bg-dark"
    ]
  end

  defp color_variant("bordered", "secondary") do
    [
      "text-secondary-bordered-text-light border-secondary-bordered-text-light bg-secondary-bordered-bg-light",
      "dark:text-secondary-hover-dark dark:border-secondary-hover-dark dark:bg-secondary-bordered-bg-dark"
    ]
  end

  defp color_variant("bordered", "success") do
    [
      "text-success-bordered-text-light border-success-bordered-text-light bg-success-bordered-bg-light",
      "dark:text-success-hover-dark dark:border-success-hover-dark dark:bg-success-bordered-bg-dark"
    ]
  end

  defp color_variant("bordered", "warning") do
    [
      "text-warning-bordered-text-light border-warning-bordered-text-light bg-warning-bordered-bg-light",
      "dark:text-warning-hover-dark dark:border-warning-hover-dark dark:bg-warning-bordered-bg-dark"
    ]
  end

  defp color_variant("bordered", "danger") do
    [
      "text-danger-bordered-text-light border-danger-bordered-text-light bg-danger-bordered-bg-light",
      "dark:text-danger-hover-dark dark:border-danger-hover-dark dark:bg-danger-bordered-bg-dark"
    ]
  end

  defp color_variant("bordered", "info") do
    [
      "text-info-bordered-text-light border-info-bordered-text-light bg-info-bordered-bg-light",
      "dark:text-info-hover-dark dark:border-info-hover-dark dark:bg-info-bordered-bg-dark"
    ]
  end

  defp color_variant("bordered", "misc") do
    [
      "text-misc-bordered-text-light border-misc-bordered-text-light bg-misc-bordered-bg-light",
      "dark:text-misc-hover-dark dark:border-misc-hover-dark dark:bg-misc-bordered-bg-dark"
    ]
  end

  defp color_variant("bordered", "dawn") do
    [
      "text-dawn-bordered-text-light border-dawn-bordered-text-light bg-dawn-bordered-bg-light",
      "dark:text-dawn-hover-dark dark:border-dawn-hover-dark dark:bg-dawn-bordered-bg-dark"
    ]
  end

  defp color_variant("bordered", "silver") do
    [
      "text-silver-hover-light border-silver-hover-light bg-silver-bordered-bg-light",
      "dark:text-silver-hover-dark dark:border-silver-hover-dark dark:bg-silver-bordered-bg-dark"
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

  defp color_variant(params, _) when is_binary(params), do: params
end
