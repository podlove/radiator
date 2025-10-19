defmodule RadiatorWeb.Components.Fieldset do
  @moduledoc """
  The `RadiatorWeb.Components.Fieldset` module provides a reusable and customizable
  component for creating styled fieldsets in Phoenix LiveView applications.

  It offers various options for styling, layout, and interaction, including:

  - Customizable color themes, border styles, and sizes.
  - Support for displaying error messages alongside form fields.
  - Flexible layout options using slots for adding controls and content inside the fieldset.
  - Global attributes support for enhanced configurability and integration.

  This component is designed to enhance the user interface of forms by providing consistent
  and visually appealing fieldsets that can be easily integrated into any LiveView application.

  **Documentation:** https://mishka.tools/chelekom/docs/forms/fieldset
  """
  use Phoenix.Component
  import RadiatorWeb.Components.Icon, only: [icon: 1]

  @doc """
  Renders a `fieldset` component that groups related form elements visually and semantically.

  ## Examples

  ```elixir
  <.fieldset space="small" color="success" variant="outline">
    <:control>
      <.radio_field name="home" value="Home" space="small" color="success" label="This is label"/>
    </:control>

    <:control>
      <.radio_field
        name="home"
        value="Home"
        space="small"
        color="success"
        label="This is label of radio"
      />
    </:control>

    <:control>
      <.radio_field
        name="home"
        value="Home"
        space="small"
        color="success"
        label="This is label of radio"
      />
    </:control>
  </.fieldset>
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
  attr :padding, :string, default: "small", doc: "Determines padding for items"
  attr :variant, :string, default: "base", doc: "Determines the style"
  attr :space, :string, default: "medium", doc: "Space between items"
  attr :fieldset_class, :string, default: nil, doc: "Custom class for fieldset"
  attr :legend_class, :string, default: nil, doc: "Custom class for legend"
  attr :fieldset_wrapper_class, :string, default: nil, doc: "Custom class for wrapper"

  attr :size, :string,
    default: "extra_large",
    doc:
      "Determines the overall size of the elements, including padding, font size, and other items"

  attr :error_icon, :string, default: nil, doc: "Icon to be displayed alongside error messages"
  attr :legend, :string, default: nil, doc: "Determines a caption for the content of its parent"

  attr :errors, :list, default: [], doc: "List of error messages to be displayed"
  attr :name, :any, doc: "Name of input"
  attr :value, :any, doc: "Value of input"

  attr :rest, :global,
    include: ~w(disabled form title),
    doc:
      "Global attributes can define defaults which are merged with attributes provided by the caller"

  slot :control, required: false, doc: "Defines a collection of elements inside the fieldset"

  def fieldset(assigns) do
    ~H"""
    <div class={[
      color_variant(@variant, @color),
      rounded_size(@rounded),
      border_class(@border, @variant),
      padding_class(@padding),
      size_class(@size),
      space_class(@space),
      @class
    ]}>
      <fieldset class={["fieldset-field", @fieldset_class]}>
        <legend
          :if={@legend}
          class={["fieldset-legend py-0.5 px-1 leading-7", @legend_class]}
          for={@id}
        >
          {@legend}
        </legend>

        <div
          :for={{control, index} <- Enum.with_index(@control, 1)}
          id={"#{@id}-control-#{index}"}
          class={@fieldset_wrapper_class}
        >
          {render_slot(control)}
        </div>
      </fieldset>

      <.error :for={msg <- @errors} icon={@error_icon}>{msg}</.error>
    </div>
    """
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
      <.icon :if={!is_nil(@icon)} name={@icon} class="shrink-0" /> {render_slot(@inner_block)}
    </p>
    """
  end

  defp size_class("extra_small"), do: "text-xs"

  defp size_class("small"), do: "text-sm"

  defp size_class("medium"), do: "text-base"

  defp size_class("large"), do: "text-lg"

  defp size_class("extra_large"), do: "text-xl"

  defp size_class(params) when is_binary(params), do: params

  defp rounded_size("none"), do: nil

  defp rounded_size("extra_small") do
    "[&_.fieldset-field]:rounded-sm [&_.fieldset-legend]:rounded-t-sm"
  end

  defp rounded_size("small") do
    "[&_.fieldset-field]:rounded [&_.fieldset-legend]:rounded-t"
  end

  defp rounded_size("medium") do
    "[&_.fieldset-field]:rounded-md [&_.fieldset-legend]:rounded-t-md"
  end

  defp rounded_size("large") do
    "[&_.fieldset-field]:rounded-lg [&_.fieldset-legend]:rounded-t-lg"
  end

  defp rounded_size("extra_large") do
    "[&_.fieldset-field]:rounded-xl [&_.fieldset-legend]:rounded-t-xl"
  end

  defp rounded_size("full"), do: "[&_.fieldset-field]:rounded-full"

  defp rounded_size(params) when is_binary(params), do: params

  defp border_class(_, variant) when variant in ["default", "shadow", "transparent", "gradient"],
    do: nil

  defp border_class("none", _), do: nil
  defp border_class("extra_small", _), do: "[&_.fieldset-field]:border"
  defp border_class("small", _), do: "[&_.fieldset-field]:border-2"
  defp border_class("medium", _), do: "[&_.fieldset-field]:border-[3px]"
  defp border_class("large", _), do: "[&_.fieldset-field]:border-4"
  defp border_class("extra_large", _), do: "[&_.fieldset-field]:border-[5px]"
  defp border_class(params, _) when is_binary(params), do: params

  defp padding_class("extra_small"), do: "[&_.fieldset-field]:p-2"

  defp padding_class("small"), do: "[&_.fieldset-field]:p-3"

  defp padding_class("medium"), do: "[&_.fieldset-field]:p-4"

  defp padding_class("large"), do: "[&_.fieldset-field]:p-5"

  defp padding_class("extra_large"), do: "[&_.fieldset-field]:p-6"

  defp padding_class(params) when is_binary(params), do: params

  defp space_class("none"), do: nil

  defp space_class("extra_small"), do: "[&_fieldset]:space-y-1"

  defp space_class("small"), do: "[&_fieldset]:space-y-1.5"

  defp space_class("medium"), do: "[&_fieldset]:space-y-2"

  defp space_class("large"), do: "[&_fieldset]:space-y-2.5"

  defp space_class("extra_large"), do: "[&_fieldset]:space-y-3"

  defp space_class(params) when is_binary(params), do: params

  defp color_variant("base", _) do
    [
      "text-base-text-light [&_.fieldset-field]:border-base-border-light [&_.fieldset-field]:bg-white [&_.fieldset-field]:shadow-sm",
      "dark:text-base-text-dark dark:[&_.fieldset-field]:border-base-border-dark dark:[&_.fieldset-field]:bg-base-bg-dark"
    ]
  end

  defp color_variant("default", "white") do
    [
      "[&_.fieldset-field]:bg-white text-black",
      "[&_.fieldset-legend]:bg-white"
    ]
  end

  defp color_variant("default", "dark") do
    [
      "[&_.fieldset-field]:bg-default-dark-bg text-white",
      "[&_.fieldset-legend]:bg-default-dark-bg dark:[&_.fieldset-legend]:bg-base-bg-dark"
    ]
  end

  defp color_variant("default", "natural") do
    [
      "[&_.fieldset-field]:bg-natural-light text-white dark:[&_.fieldset-field]:bg-natural-dark dark:text-black",
      "[&_.fieldset-legend]:bg-natural-light dark:[&_.fieldset-legend]:bg-natural-dark"
    ]
  end

  defp color_variant("default", "primary") do
    [
      "[&_.fieldset-field]:bg-primary-light text-white dark:[&_.fieldset-field]:bg-primary-dark dark:text-black",
      "[&_.fieldset-legend]:bg-primary-light dark:[&_.fieldset-legend]:bg-primary-dark"
    ]
  end

  defp color_variant("default", "secondary") do
    [
      "[&_.fieldset-field]:bg-secondary-light text-white dark:[&_.fieldset-field]:bg-secondary-dark dark:text-black",
      "[&_.fieldset-legend]:bg-secondary-light dark:[&_.fieldset-legend]:bg-secondary-dark"
    ]
  end

  defp color_variant("default", "success") do
    [
      "[&_.fieldset-field]:bg-success-light text-white dark:[&_.fieldset-field]:bg-success-dark dark:text-black",
      "[&_.fieldset-legend]:bg-success-light dark:[&_.fieldset-legend]:bg-success-dark"
    ]
  end

  defp color_variant("default", "warning") do
    [
      "[&_.fieldset-field]:bg-warning-light text-white dark:[&_.fieldset-field]:bg-warning-dark dark:text-black",
      "[&_.fieldset-legend]:bg-warning-light dark:[&_.fieldset-legend]:bg-warning-dark"
    ]
  end

  defp color_variant("default", "danger") do
    [
      "[&_.fieldset-field]:bg-danger-light text-white dark:[&_.fieldset-field]:bg-danger-dark dark:text-black",
      "[&_.fieldset-legend]:bg-danger-light dark:[&_.fieldset-legend]:bg-danger-dark"
    ]
  end

  defp color_variant("default", "info") do
    [
      "[&_.fieldset-field]:bg-info-light text-white dark:[&_.fieldset-field]:bg-info-dark dark:text-black",
      "[&_.fieldset-legend]:bg-info-light dark:[&_.fieldset-legend]:bg-info-dark"
    ]
  end

  defp color_variant("default", "misc") do
    [
      "[&_.fieldset-field]:bg-misc-light text-white dark:[&_.fieldset-field]:bg-misc-dark dark:text-black",
      "[&_.fieldset-legend]:bg-misc-light dark:[&_.fieldset-legend]:bg-misc-dark"
    ]
  end

  defp color_variant("default", "dawn") do
    [
      "[&_.fieldset-field]:bg-dawn-light text-white dark:[&_.fieldset-field]:bg-dawn-dark dark:text-black",
      "[&_.fieldset-legend]:bg-dawn-light dark:[&_.fieldset-legend]:bg-dawn-dark"
    ]
  end

  defp color_variant("default", "silver") do
    [
      "[&_.fieldset-field]:bg-silver-light text-white dark:[&_.fieldset-field]:bg-silver-dark dark:text-black",
      "[&_.fieldset-legend]:bg-silver-light dark:[&_.fieldset-legend]:bg-silver-dark"
    ]
  end

  defp color_variant("outline", "natural") do
    [
      "text-natural-light [&_.fieldset-field]:border-natural-light dark:text-natural-dark dark:[&_.fieldset-field]:border-natural-dark"
    ]
  end

  defp color_variant("outline", "primary") do
    [
      "text-primary-light [&_.fieldset-field]:border-primary-light dark:text-primary-dark dark:[&_.fieldset-field]:border-primary-dark"
    ]
  end

  defp color_variant("outline", "secondary") do
    [
      "text-secondary-light [&_.fieldset-field]:border-secondary-light dark:text-secondary-dark dark:[&_.fieldset-field]:border-secondary-dark"
    ]
  end

  defp color_variant("outline", "success") do
    [
      "text-success-light [&_.fieldset-field]:border-success-light dark:text-success-dark dark:[&_.fieldset-field]:border-success-dark"
    ]
  end

  defp color_variant("outline", "warning") do
    [
      "text-warning-light [&_.fieldset-field]:border-warning-light dark:text-warning-dark dark:[&_.fieldset-field]:border-warning-dark"
    ]
  end

  defp color_variant("outline", "danger") do
    [
      "text-danger-light [&_.fieldset-field]:border-danger-light dark:text-danger-dark dark:[&_.fieldset-field]:border-danger-dark"
    ]
  end

  defp color_variant("outline", "info") do
    [
      "text-info-light [&_.fieldset-field]:border-info-light dark:text-info-dark dark:[&_.fieldset-field]:border-info-dark"
    ]
  end

  defp color_variant("outline", "misc") do
    [
      "text-misc-light [&_.fieldset-field]:border-misc-light dark:text-misc-dark dark:[&_.fieldset-field]:border-misc-dark"
    ]
  end

  defp color_variant("outline", "dawn") do
    [
      "text-dawn-light [&_.fieldset-field]:border-dawn-light dark:text-dawn-dark dark:[&_.fieldset-field]:border-dawn-dark"
    ]
  end

  defp color_variant("outline", "silver") do
    [
      "text-silver-light [&_.fieldset-field]:border-silver-light dark:text-silver-dark dark:[&_.fieldset-field]:border-silver-dark"
    ]
  end

  defp color_variant("shadow", "natural") do
    [
      "[&_.fieldset-field]:bg-natural-light text-white dark:[&_.fieldset-field]:bg-natural-dark dark:text-black",
      "shadow-[0px_4px_6px_-4px_var(--color-shadow-natural)] shadow-[0px_10px_15px_-3px_var(--color-shadow-natural)] dark:shadow-none",
      "[&_.fieldset-legend]:bg-natural-light dark:[&_.fieldset-legend]:bg-natural-dark"
    ]
  end

  defp color_variant("shadow", "primary") do
    [
      "[&_.fieldset-field]:bg-primary-light text-white dark:[&_.fieldset-field]:bg-primary-dark dark:text-black",
      "shadow-[0px_4px_6px_-4px_var(--color-shadow-primary)] shadow-[0px_10px_15px_-3px_var(--color-shadow-primary)] dark:shadow-none",
      "[&_.fieldset-legend]:bg-primary-light dark:[&_.fieldset-legend]:bg-primary-dark"
    ]
  end

  defp color_variant("shadow", "secondary") do
    [
      "[&_.fieldset-field]:bg-secondary-light text-white dark:[&_.fieldset-field]:bg-secondary-dark dark:text-black",
      "shadow-[0px_4px_6px_-4px_var(--color-shadow-secondary)] shadow-[0px_10px_15px_-3px_var(--color-shadow-secondary)] dark:shadow-none",
      "[&_.fieldset-legend]:bg-secondary-light dark:[&_.fieldset-legend]:bg-secondary-dark"
    ]
  end

  defp color_variant("shadow", "success") do
    [
      "[&_.fieldset-field]:bg-success-light text-white dark:[&_.fieldset-field]:bg-success-dark dark:text-black",
      "shadow-[0px_4px_6px_-4px_var(--color-shadow-success)] shadow-[0px_10px_15px_-3px_var(--color-shadow-success)] dark:shadow-none",
      "[&_.fieldset-legend]:bg-success-light dark:[&_.fieldset-legend]:bg-success-dark"
    ]
  end

  defp color_variant("shadow", "warning") do
    [
      "[&_.fieldset-field]:bg-warning-light text-white dark:[&_.fieldset-field]:bg-warning-dark dark:text-black",
      "shadow-[0px_4px_6px_-4px_var(--color-shadow-warning)] shadow-[0px_10px_15px_-3px_var(--color-shadow-warning)] dark:shadow-none",
      "[&_.fieldset-legend]:bg-warning-light dark:[&_.fieldset-legend]:bg-warning-dark"
    ]
  end

  defp color_variant("shadow", "danger") do
    [
      "[&_.fieldset-field]:bg-danger-light text-white dark:[&_.fieldset-field]:bg-danger-dark dark:text-black",
      "shadow-[0px_4px_6px_-4px_var(--color-shadow-danger)] shadow-[0px_10px_15px_-3px_var(--color-shadow-danger)] dark:shadow-none",
      "[&_.fieldset-legend]:bg-danger-light dark:[&_.fieldset-legend]:bg-danger-dark"
    ]
  end

  defp color_variant("shadow", "info") do
    [
      "[&_.fieldset-field]:bg-info-light text-white dark:[&_.fieldset-field]:bg-info-dark dark:text-black",
      "shadow-[0px_4px_6px_-4px_var(--color-shadow-info)] shadow-[0px_10px_15px_-3px_var(--color-shadow-info)] dark:shadow-none",
      "[&_.fieldset-legend]:bg-info-light dark:[&_.fieldset-legend]:bg-info-dark"
    ]
  end

  defp color_variant("shadow", "misc") do
    [
      "[&_.fieldset-field]:bg-misc-light text-white dark:[&_.fieldset-field]:bg-misc-dark dark:text-black",
      "shadow-[0px_4px_6px_-4px_var(--color-shadow-misc)] shadow-[0px_10px_15px_-3px_var(--color-shadow-misc)] dark:shadow-none",
      "[&_.fieldset-legend]:bg-misc-light dark:[&_.fieldset-legend]:bg-misc-dark"
    ]
  end

  defp color_variant("shadow", "dawn") do
    [
      "[&_.fieldset-field]:bg-dawn-light text-white dark:[&_.fieldset-field]:bg-dawn-dark dark:text-black",
      "shadow-[0px_4px_6px_-4px_var(--color-shadow-dawn)] shadow-[0px_10px_15px_-3px_var(--color-shadow-dawn)] dark:shadow-none",
      "[&_.fieldset-legend]:bg-dawn-light dark:[&_.fieldset-legend]:bg-dawn-dark"
    ]
  end

  defp color_variant("shadow", "silver") do
    [
      "[&_.fieldset-field]:bg-silver-light text-white dark:[&_.fieldset-field]:bg-silver-dark dark:text-black",
      "shadow-[0px_4px_6px_-4px_var(--color-shadow-silver)] shadow-[0px_10px_15px_-3px_var(--color-shadow-silver)] dark:shadow-none",
      "[&_.fieldset-legend]:bg-silver-light dark:[&_.fieldset-legend]:bg-silver-dark"
    ]
  end

  defp color_variant("bordered", "white") do
    [
      "[&_.fieldset-field]:bg-white text-black [&_.fieldset-field]:border-bordered-white-border",
      "[&_.fieldset-legend]:bg-white"
    ]
  end

  defp color_variant("bordered", "dark") do
    [
      "[&_.fieldset-field]:bg-default-dark-bg text-white [&_.fieldset-field]:border-silver-hover-light",
      "[&_.fieldset-legend]:bg-default-dark-bg"
    ]
  end

  defp color_variant("bordered", "natural") do
    [
      "text-natural-bordered-text-light [&_.fieldset-field]:border-natural-bordered-text-light [&_.fieldset-field]:bg-natural-bordered-bg-light",
      "dark:text-natural-hover-dark dark:[&_.fieldset-field]:border-natural-hover-dark dark:[&_.fieldset-field]:bg-natural-bordered-bg-dark",
      "[&_.fieldset-legend]:bg-natural-bordered-bg-light dark:[&_.fieldset-legend]:bg-natural-bordered-bg-dark"
    ]
  end

  defp color_variant("bordered", "primary") do
    [
      "text-primary-bordered-text-light [&_.fieldset-field]:border-primary-bordered-text-light [&_.fieldset-field]:bg-primary-bordered-bg-light",
      "dark:text-primary-hover-dark dark:[&_.fieldset-field]:border-primary-hover-dark dark:[&_.fieldset-field]:bg-primary-bordered-bg-dark",
      "[&_.fieldset-legend]:bg-primary-bordered-bg-light dark:[&_.fieldset-legend]:bg-primary-bordered-bg-dark"
    ]
  end

  defp color_variant("bordered", "secondary") do
    [
      "text-secondary-bordered-text-light [&_.fieldset-field]:border-secondary-bordered-text-light [&_.fieldset-field]:bg-secondary-bordered-bg-light",
      "dark:text-secondary-hover-dark dark:[&_.fieldset-field]:border-secondary-hover-dark dark:[&_.fieldset-field]:bg-secondary-bordered-bg-dark",
      "[&_.fieldset-legend]:bg-secondary-bordered-bg-light dark:[&_.fieldset-legend]:bg-secondary-bordered-bg-dark"
    ]
  end

  defp color_variant("bordered", "success") do
    [
      "text-success-bordered-text-light [&_.fieldset-field]:border-success-bordered-text-light [&_.fieldset-field]:bg-success-bordered-bg-light",
      "dark:text-success-hover-dark dark:[&_.fieldset-field]:border-success-hover-dark dark:[&_.fieldset-field]:bg-success-bordered-bg-dark",
      "[&_.fieldset-legend]:bg-success-bordered-bg-light dark:[&_.fieldset-legend]:bg-success-bordered-bg-dark"
    ]
  end

  defp color_variant("bordered", "warning") do
    [
      "text-warning-bordered-text-light [&_.fieldset-field]:border-warning-bordered-text-light [&_.fieldset-field]:bg-warning-bordered-bg-light",
      "dark:text-warning-hover-dark dark:[&_.fieldset-field]:border-warning-hover-dark dark:[&_.fieldset-field]:bg-warning-bordered-bg-dark",
      "[&_.fieldset-legend]:bg-warning-bordered-bg-light dark:[&_.fieldset-legend]:bg-warning-bordered-bg-dark"
    ]
  end

  defp color_variant("bordered", "danger") do
    [
      "text-danger-bordered-text-light [&_.fieldset-field]:border-danger-bordered-text-light [&_.fieldset-field]:bg-danger-bordered-bg-light",
      "dark:text-danger-hover-dark dark:[&_.fieldset-field]:border-danger-hover-dark dark:[&_.fieldset-field]:bg-danger-bordered-bg-dark",
      "[&_.fieldset-legend]:bg-danger-bordered-bg-light dark:[&_.fieldset-legend]:bg-danger-bordered-bg-dark"
    ]
  end

  defp color_variant("bordered", "info") do
    [
      "text-info-bordered-text-light [&_.fieldset-field]:border-info-bordered-text-light [&_.fieldset-field]:bg-info-bordered-bg-light",
      "dark:text-info-hover-dark dark:[&_.fieldset-field]:border-info-hover-dark dark:[&_.fieldset-field]:bg-info-bordered-bg-dark",
      "[&_.fieldset-legend]:bg-info-bordered-bg-light dark:[&_.fieldset-legend]:bg-info-bordered-bg-dark"
    ]
  end

  defp color_variant("bordered", "misc") do
    [
      "text-misc-bordered-text-light [&_.fieldset-field]:border-misc-bordered-text-light [&_.fieldset-field]:bg-misc-bordered-bg-light",
      "dark:text-misc-hover-dark dark:[&_.fieldset-field]:border-misc-hover-dark dark:[&_.fieldset-field]:bg-misc-bordered-bg-dark",
      "[&_.fieldset-legend]:bg-misc-bordered-bg-light dark:[&_.fieldset-legend]:bg-misc-bordered-bg-dark"
    ]
  end

  defp color_variant("bordered", "dawn") do
    [
      "text-dawn-bordered-text-light [&_.fieldset-field]:border-dawn-bordered-text-light [&_.fieldset-field]:bg-dawn-bordered-bg-light",
      "dark:text-dawn-hover-dark dark:[&_.fieldset-field]:border-dawn-hover-dark dark:[&_.fieldset-field]:bg-dawn-bordered-bg-dark",
      "[&_.fieldset-legend]:bg-dawn-bordered-bg-light dark:[&_.fieldset-legend]:bg-dawn-bordered-bg-dark"
    ]
  end

  defp color_variant("bordered", "silver") do
    [
      "text-silver-hover-light [&_.fieldset-field]:border-silver-hover-light [&_.fieldset-field]:bg-silver-bordered-bg-light",
      "dark:text-silver-hover-dark dark:[&_.fieldset-field]:border-silver-hover-dark dark:[&_.fieldset-field]:bg-silver-bordered-bg-dark",
      "[&_.fieldset-legend]:bg-silver-bordered-bg-light dark:[&_.fieldset-legend]:bg-silver-bordered-bg-dark"
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

  defp color_variant("gradient", "natural") do
    [
      "[&_.fieldset-field]:bg-gradient-to-br from-gradient-natural-from-light to-gradient-natural-to-light text-white",
      "dark:from-gradient-natural-from-dark dark:to-white dark:text-black",
      "[&_.fieldset-legend]:bg-gradient-natural-from-light dark:[&_.fieldset-legend]:bg-gradient-natural-from-dark"
    ]
  end

  defp color_variant("gradient", "primary") do
    [
      "[&_.fieldset-field]:bg-gradient-to-br from-gradient-primary-from-light to-gradient-primary-to-light text-white",
      "dark:from-gradient-primary-from-dark dark:to-gradient-primary-to-dark dark:text-black",
      "[&_.fieldset-legend]:bg-gradient-primary-from-light dark:[&_.fieldset-legend]:bg-gradient-primary-from-dark"
    ]
  end

  defp color_variant("gradient", "secondary") do
    [
      "[&_.fieldset-field]:bg-gradient-to-br from-gradient-secondary-from-light to-gradient-secondary-to-light text-white",
      "dark:from-gradient-secondary-from-dark dark:to-gradient-secondary-to-dark dark:text-black",
      "[&_.fieldset-legend]:bg-gradient-secondary-from-light dark:[&_.fieldset-legend]:bg-gradient-secondary-from-dark"
    ]
  end

  defp color_variant("gradient", "success") do
    [
      "[&_.fieldset-field]:bg-gradient-to-br from-gradient-success-from-light to-gradient-success-to-light text-white",
      "dark:from-gradient-success-from-dark dark:to-gradient-success-to-dark dark:text-black",
      "[&_.fieldset-legend]:bg-gradient-success-from-light dark:[&_.fieldset-legend]:bg-gradient-success-from-dark"
    ]
  end

  defp color_variant("gradient", "warning") do
    [
      "[&_.fieldset-field]:bg-gradient-to-br from-gradient-warning-from-light to-gradient-warning-to-light text-white",
      "dark:from-gradient-warning-from-dark dark:to-gradient-warning-to-dark dark:text-black",
      "[&_.fieldset-legend]:bg-gradient-warning-from-light dark:[&_.fieldset-legend]:bg-gradient-warning-from-dark"
    ]
  end

  defp color_variant("gradient", "danger") do
    [
      "[&_.fieldset-field]:bg-gradient-to-br from-gradient-danger-from-light to-gradient-danger-to-light text-white",
      "dark:from-gradient-danger-from-dark dark:to-gradient-danger-to-dark dark:text-black",
      "[&_.fieldset-legend]:bg-gradient-danger-from-light dark:[&_.fieldset-legend]:bg-gradient-danger-from-dark"
    ]
  end

  defp color_variant("gradient", "info") do
    [
      "[&_.fieldset-field]:bg-gradient-to-br from-gradient-info-from-light to-gradient-info-to-light text-white",
      "dark:from-gradient-info-from-dark dark:to-gradient-info-to-dark dark:text-black",
      "[&_.fieldset-legend]:bg-gradient-info-from-light dark:[&_.fieldset-legend]:bg-gradient-info-from-dark"
    ]
  end

  defp color_variant("gradient", "misc") do
    [
      "[&_.fieldset-field]:bg-gradient-to-br from-gradient-misc-from-light to-gradient-misc-to-light text-white",
      "dark:from-gradient-misc-from-dark dark:to-gradient-misc-to-dark dark:text-black",
      "[&_.fieldset-legend]:bg-gradient-misc-from-light dark:[&_.fieldset-legend]:bg-gradient-misc-from-dark"
    ]
  end

  defp color_variant("gradient", "dawn") do
    [
      "[&_.fieldset-field]:bg-gradient-to-br from-gradient-dawn-from-light to-gradient-dawn-to-light text-white",
      "dark:from-gradient-dawn-from-dark dark:to-gradient-dawn-to-dark dark:text-black",
      "[&_.fieldset-legend]:bg-gradient-dawn-from-light dark:[&_.fieldset-legend]:bg-gradient-dawn-from-dark"
    ]
  end

  defp color_variant("gradient", "silver") do
    [
      "[&_.fieldset-field]:bg-gradient-to-br from-gradient-silver-from-light to-gradient-silver-to-light text-white",
      "dark:from-gradient-silver-from-dark dark:to-gradient-silver-to-dark dark:text-black",
      "[&_.fieldset-legend]:bg-gradient-silver-from-light dark:[&_.fieldset-legend]:bg-gradient-silver-from-dark"
    ]
  end

  defp color_variant(params, _) when is_binary(params), do: params
end
