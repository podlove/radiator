defmodule RadiatorWeb.Components.MegaMenu do
  @moduledoc """
  The `RadiatorWeb.Components.MegaMenu` module provides a customizable and interactive mega menu component
  for building sophisticated navigation systems in Phoenix LiveView applications.

  This component can be used to create multi-level navigation menus with various styling and
  layout options, making it ideal for sites with complex information architectures.

  ### Features

  - **Multiple Styling Options:** Choose from several variants, including `default` and `shadow`,
  to match your design needs.
  - **Color Customization:** Supports a wide range of color themes to integrate seamlessly with
  your application's style.
  - **Interactive Elements:** Allows for click or hover-based activation of the menu, giving users
  flexibility in interaction.
  - **Customizable Slots:** Utilize the `trigger` and `inner_block` slots to define custom content
  and layout within the mega menu.

  **Documentation:** https://mishka.tools/chelekom/docs/mega-menu
  """

  use Phoenix.Component
  alias Phoenix.LiveView.JS
  import RadiatorWeb.Components.Icon, only: [icon: 1]

  @doc """
  Renders a customizable `mega_menu` component that can display various sections of content.
  It includes slots for defining a trigger element, such as a button, and inner content blocks.

  ## Examples

  ```elixir
  <.mega_menu id="mega" space="small" rounded="large" padding="extra_small" top_gap="large" clickable>
    <:trigger>
      <button class="text-start w-full block">MegaMenu</button>
    </:trigger>

    <div>
      <div class="grid md:grid-cols-2 lg:grid-cols-3">
        <ul class="space-y-4 sm:mb-4 md:mb-0" aria-labelledby="mega-menu-full-cta-button">
          <li>
            <a href="#" class="hover:underline hover:text-blue-600">
              Online Stores
            </a>
          </li>
          <li>
            <a href="#" class="hover:underline hover:text-blue-600">
              Segmentation
            </a>
          </li>
          <li>
            <a href="#" class="hover:underline hover:text-blue-600">
              Marketing CRM
            </a>
          </li>
          <li>
            <a href="#" class="hover:underline hover:text-blue-600">
              Online Stores
            </a>
          </li>
        </ul>
        <ul class="hidden mb-4 space-y-4 md:mb-0 sm:block">
          <li>
            <a href="#" class="hover:underline hover:text-blue-600">
              Our Blog
            </a>
          </li>
          <li>
            <a href="#" class="hover:underline hover:text-blue-600">
              Terms & Conditions
            </a>
          </li>
          <li>
            <a href="#" class="hover:underline hover:text-blue-600">
              License
            </a>
          </li>
          <li>
            <a href="#" class="hover:underline hover:text-blue-600">
              Resources
            </a>
          </li>
        </ul>
        <div class="mt-4 md:mt-0">
          <h2 class="mb-2 font-semibold text-gray-900">Our brands</h2>
          <p class="mb-2 text-gray-500">
            At Flowbite, we have a portfolio of brands that cater to a variety of preferences.
          </p>
          <a
            href="#"
            class="inline-flex items-center text-sm font-medium text-blue-600 hover:underline hover:text-blue-600"
          >
            Explore our brands <span class="sr-only">Explore our brands </span>
            <svg
              class="w-3 h-3 ms-2 rtl:rotate-180"
              aria-hidden="true"
              xmlns="http://www.w3.org/2000/svg"
              fill="none"
              viewBox="0 0 14 10"
            >
              <path
                stroke="currentColor"
                stroke-linecap="round"
                stroke-linejoin="round"
                stroke-width="2"
                d="M1 5h12m0 0L9 1m4 4L9 9"
              />
            </svg>
          </a>
        </div>
      </div>
    </div>
  </.mega_menu>
  ```
  """
  @doc type: :component
  attr :id, :string,
    default: nil,
    doc: "A unique identifier is used to manage state and interaction"

  attr :clickable, :boolean,
    default: false,
    doc: "Determines if the element can be activated on click"

  attr :variant, :string, default: "base", doc: "Determines the style"
  attr :color, :string, default: "natural", doc: "Determines color theme"
  attr :rounded, :string, default: "", doc: "Determines the border radius"

  attr :size, :string,
    default: "",
    doc:
      "Determines the overall size of the elements, including padding, font size, and other items"

  attr :space, :string, default: "", doc: "Space between items"
  attr :width, :string, default: "full", doc: "Determines the element width"

  attr :font_weight, :string,
    default: "font-normal",
    doc: "Determines custom class for the font weight"

  attr :padding, :string, default: "", doc: "Determines padding for items"
  attr :icon, :string, default: nil, doc: "Icon displayed alongside of an item"
  attr :icon_class, :string, default: nil, doc: "Determines custom class for the icon"
  attr :title, :string, default: nil, doc: "Specifies the title of the element"
  attr :title_class, :string, default: nil, doc: "Determines custom class for the title"
  attr :content_class, :string, default: nil, doc: "Determines custom class for the content"
  attr :border, :string, default: "extra_small", doc: "Determines border style"
  attr :top_gap, :string, default: "extra_small", doc: "Determines top gap of the element"
  attr :class, :string, default: nil, doc: "Custom CSS class for additional styling"

  attr :rest, :global,
    doc:
      "Global attributes can define defaults which are merged with attributes provided by the caller"

  slot :inner_block, required: false, doc: "Inner block that renders HEEx content"

  slot :trigger, required: false do
    attr :class, :string, doc: "Custom CSS class for additional styling"
  end

  def mega_menu(assigns) do
    ~H"""
    <div
      id={@id}
      phx-open-mega={
        JS.toggle_class("show-mega-menu",
          to: "##{@id}-mega-menu-content",
          transition: "duration-100"
        )
      }
      class={[
        "[&>.mega-menu-content]:invisible [&>.mega-menu-content]:opacity-0",
        "[&>.mega-menu-content.show-mega-menu]:visible [&>.mega-menu-content.show-mega-menu]:opacity-100",
        !@clickable && trigger_mega_menu(),
        color_variant(@variant, @color),
        padding_size(@padding),
        rounded_size(@rounded),
        width_size(@width),
        border_class(@border, @variant),
        top_gap(@top_gap),
        space_class(@space),
        size_class(@size),
        @font_weight,
        @class
      ]}
      role="navigation"
      {@rest}
    >
      <button
        :if={!is_nil(@title)}
        role="button"
        aria-haspopup="true"
        phx-click={@id && JS.exec("phx-open-mega", to: "##{@id}")}
        class={["flex items-center", @title_class]}
      >
        <.icon :if={!is_nil(@icon)} name={@icon} class={["mega-menu-icon", @icon_class]} />
        <span>{@title}</span>
      </button>

      <div
        :if={@trigger}
        phx-click={@id && JS.exec("phx-open-mega", to: "##{@id}")}
        class={["cursor-pointer mega-menu-trigger", @trigger[:class]]}
      >
        {render_slot(@trigger)}
      </div>

      <div
        id={@id && "#{@id}-mega-menu-content"}
        phx-click-away={
          @id &&
            JS.remove_class("show-mega-menu",
              to: "##{@id}-mega-menu-content",
              transition: "duration-300"
            )
        }
        class={[
          "mega-menu-content inset-x-0 top-full absolute z-20 transition-all ease-in-out delay-100 duration-500 w-full",
          "invisible opacity-0",
          @content_class
        ]}
        role="menu"
      >
        {render_slot(@inner_block)}
      </div>
    </div>
    """
  end

  defp trigger_mega_menu(),
    do: "[&>.mega-menu-content]:hover:visible [&>.mega-menu-content]:hover:opacity-100"

  defp top_gap("none"), do: "[&>.mega-menu-content]:mt-0"
  defp top_gap("extra_small"), do: "[&>.mega-menu-content]:mt-1"
  defp top_gap("small"), do: "[&>.mega-menu-content]:mt-2"
  defp top_gap("medium"), do: "[&>.mega-menu-content]:mt-3"
  defp top_gap("large"), do: "[&>.mega-menu-content]:mt-4"
  defp top_gap("extra_large"), do: "[&>.mega-menu-content]:mt-5"
  defp top_gap(params) when is_binary(params), do: params

  defp width_size("full"), do: "[&>.mega-menu-content]:w-full"

  defp width_size("half"),
    do:
      "[&>.mega-menu-content]:w-full md:[&>.mega-menu-content]:w-1/2 md:[&>.mega-menu-content]:mx-auto"

  defp width_size(params) when is_binary(params), do: params

  defp border_class(_, variant) when variant in ["default", "shadow", "gradient"],
    do: nil

  defp border_class("none", _), do: "[&>.mega-menu-content]:border-0"
  defp border_class("extra_small", _), do: "[&>.mega-menu-content]:border"
  defp border_class("small", _), do: "[&>.mega-menu-content]:border-2"
  defp border_class("medium", _), do: "[&>.mega-menu-content]:border-[3px]"
  defp border_class("large", _), do: "[&>.mega-menu-content]:border-4"

  defp border_class("extra_large", _),
    do: "[&>.mega-menu-content]:border-[5px]"

  defp border_class(params, _) when is_binary(params), do: params

  defp rounded_size("extra_small"), do: "[&>.mega-menu-content]:rounded-sm"

  defp rounded_size("small"), do: "[&>.mega-menu-content]:rounded"

  defp rounded_size("medium"), do: "[&>.mega-menu-content]:rounded-md"

  defp rounded_size("large"), do: "[&>.mega-menu-content]:rounded-lg"

  defp rounded_size("extra_large"), do: "[&>.mega-menu-content]:rounded-xl"

  defp rounded_size(params) when is_binary(params), do: params

  defp size_class("extra_small"), do: "text-xs"

  defp size_class("small"), do: "text-sm"

  defp size_class("medium"), do: "text-base"

  defp size_class("large"), do: "text-lg"

  defp size_class("extra_large"), do: "text-xl"

  defp size_class(params) when is_binary(params), do: params

  defp padding_size("extra_small"), do: "[&>.mega-menu-content]:p-2"

  defp padding_size("small"), do: "[&>.mega-menu-content]:p-3"

  defp padding_size("medium"), do: "[&>.mega-menu-content]:p-4"

  defp padding_size("large"), do: "[&>.mega-menu-content]:p-5"

  defp padding_size("extra_large"), do: "[&>.mega-menu-content]:p-6"

  defp padding_size(params) when is_binary(params), do: params

  defp space_class("extra_small"), do: "[&>.mega-menu-content]:space-y-2"

  defp space_class("small"), do: "[&>.mega-menu-content]:space-y-3"

  defp space_class("medium"), do: "[&>.mega-menu-content]:space-y-4"

  defp space_class("large"), do: "[&>.mega-menu-content]:space-y-5"

  defp space_class("extra_large"), do: "[&>.mega-menu-content]:space-y-6"

  defp space_class(params) when is_binary(params), do: params

  defp color_variant("base", _) do
    [
      "[&>.mega-menu-content]:bg-white text-base-text-light [&>.mega-menu-content]:border-base-border-light [&>.mega-menu-content]:shadow-sm",
      "dark:[&>.mega-menu-content]:bg-base-bg-dark dark:text-base-text-dark dark:[&>.mega-menu-content]:border-base-border-dark"
    ]
  end

  defp color_variant("default", "white") do
    [
      "[&>.mega-menu-content]:bg-white text-black"
    ]
  end

  defp color_variant("default", "dark") do
    [
      "[&>.mega-menu-content]:bg-default-dark-bg text-white"
    ]
  end

  defp color_variant("default", "natural") do
    [
      "[&>.mega-menu-content]:bg-natural-bg-dark text-white dark:[&>.mega-menu-content]:bg-natural-dark dark:text-black"
    ]
  end

  defp color_variant("default", "primary") do
    [
      "[&>.mega-menu-content]:bg-primary-light text-white dark:[&>.mega-menu-content]:bg-primary-dark dark:text-black"
    ]
  end

  defp color_variant("default", "secondary") do
    [
      "[&>.mega-menu-content]:bg-secondary-light text-white dark:[&>.mega-menu-content]:bg-secondary-dark dark:text-black"
    ]
  end

  defp color_variant("default", "success") do
    [
      "[&>.mega-menu-content]:bg-success-light text-white dark:[&>.mega-menu-content]:bg-success-dark dark:text-black"
    ]
  end

  defp color_variant("default", "warning") do
    [
      "[&>.mega-menu-content]:bg-warning-light text-white dark:[&>.mega-menu-content]:bg-warning-dark dark:text-black"
    ]
  end

  defp color_variant("default", "danger") do
    [
      "[&>.mega-menu-content]:bg-danger-light text-white dark:[&>.mega-menu-content]:bg-danger-dark dark:text-black"
    ]
  end

  defp color_variant("default", "info") do
    [
      "[&>.mega-menu-content]:bg-info-light text-white dark:[&>.mega-menu-content]:bg-info-dark dark:text-black"
    ]
  end

  defp color_variant("default", "misc") do
    [
      "[&>.mega-menu-content]:bg-misc-light text-white dark:[&>.mega-menu-content]:bg-misc-dark dark:text-black"
    ]
  end

  defp color_variant("default", "dawn") do
    [
      "[&>.mega-menu-content]:bg-dawn-light text-white dark:[&>.mega-menu-content]:bg-dawn-dark dark:text-black"
    ]
  end

  defp color_variant("default", "silver") do
    [
      "[&>.mega-menu-content]:bg-silver-light text-white dark:[&>.mega-menu-content]:bg-silver-dark dark:text-black"
    ]
  end

  defp color_variant("outline", "natural") do
    [
      "text-natural-light [&>.mega-menu-content]:border-natural-light dark:text-natural-dark dark:[&>.mega-menu-content]:border-natural-dark"
    ]
  end

  defp color_variant("outline", "primary") do
    [
      "text-primary-light [&>.mega-menu-content]:border-primary-light dark:text-primary-dark dark:[&>.mega-menu-content]:border-primary-dark"
    ]
  end

  defp color_variant("outline", "secondary") do
    [
      "text-secondary-light [&>.mega-menu-content]:border-secondary-light dark:text-secondary-dark dark:[&>.mega-menu-content]:border-secondary-dark"
    ]
  end

  defp color_variant("outline", "success") do
    [
      "text-success-light [&>.mega-menu-content]:border-success-light dark:text-success-dark dark:[&>.mega-menu-content]:border-success-dark"
    ]
  end

  defp color_variant("outline", "warning") do
    [
      "text-warning-light [&>.mega-menu-content]:border-warning-light dark:text-warning-dark dark:[&>.mega-menu-content]:border-warning-dark"
    ]
  end

  defp color_variant("outline", "danger") do
    [
      "text-danger-light [&>.mega-menu-content]:border-danger-light dark:text-danger-dark dark:[&>.mega-menu-content]:border-danger-dark"
    ]
  end

  defp color_variant("outline", "info") do
    [
      "text-info-light [&>.mega-menu-content]:border-info-light dark:text-info-dark dark:[&>.mega-menu-content]:border-info-dark"
    ]
  end

  defp color_variant("outline", "misc") do
    [
      "text-misc-light [&>.mega-menu-content]:border-misc-light dark:text-misc-dark dark:[&>.mega-menu-content]:border-misc-dark"
    ]
  end

  defp color_variant("outline", "dawn") do
    [
      "text-dawn-light [&>.mega-menu-content]:border-dawn-light dark:text-dawn-dark dark:[&>.mega-menu-content]:border-dawn-dark"
    ]
  end

  defp color_variant("outline", "silver") do
    [
      "text-silver-light [&>.mega-menu-content]:border-silver-light dark:text-silver-dark dark:[&>.mega-menu-content]:border-silver-dark"
    ]
  end

  defp color_variant("shadow", "natural") do
    [
      "[&>.mega-menu-content]:bg-natural-bg-dark text-white dark:[&>.mega-menu-content]:bg-natural-dark dark:text-black",
      "[&>.mega-menu-content]:shadow-[0px_4px_6px_-4px_var(--color-shadow-natural)] [&>.mega-menu-content]:shadow-[0px_10px_15px_-3px_var(--color-shadow-natural)] dark:[&>.mega-menu-content]:shadow-none"
    ]
  end

  defp color_variant("shadow", "primary") do
    [
      "[&>.mega-menu-content]:bg-primary-light text-white dark:[&>.mega-menu-content]:bg-primary-dark dark:text-black",
      "[&>.mega-menu-content]:shadow-[0px_4px_6px_-4px_var(--color-shadow-primary)] [&>.mega-menu-content]:shadow-[0px_10px_15px_-3px_var(--color-shadow-primary)] dark:[&>.mega-menu-content]:shadow-none"
    ]
  end

  defp color_variant("shadow", "secondary") do
    [
      "[&>.mega-menu-content]:bg-secondary-light text-white dark:[&>.mega-menu-content]:bg-secondary-dark dark:text-black",
      "[&>.mega-menu-content]:shadow-[0px_4px_6px_-4px_var(--color-shadow-secondary)] [&>.mega-menu-content]:shadow-[0px_10px_15px_-3px_var(--color-shadow-secondary)] dark:[&>.mega-menu-content]:shadow-none"
    ]
  end

  defp color_variant("shadow", "success") do
    [
      "[&>.mega-menu-content]:bg-success-light text-white dark:[&>.mega-menu-content]:bg-success-dark dark:text-black",
      "[&>.mega-menu-content]:shadow-[0px_4px_6px_-4px_var(--color-shadow-success)] [&>.mega-menu-content]:shadow-[0px_10px_15px_-3px_var(--color-shadow-success)] dark:[&>.mega-menu-content]:shadow-none"
    ]
  end

  defp color_variant("shadow", "warning") do
    [
      "[&>.mega-menu-content]:bg-warning-light text-white dark:[&>.mega-menu-content]:bg-warning-dark dark:text-black",
      "[&>.mega-menu-content]:shadow-[0px_4px_6px_-4px_var(--color-shadow-warning)] [&>.mega-menu-content]:shadow-[0px_10px_15px_-3px_var(--color-shadow-warning)] dark:[&>.mega-menu-content]:shadow-none"
    ]
  end

  defp color_variant("shadow", "danger") do
    [
      "[&>.mega-menu-content]:bg-danger-light text-white dark:[&>.mega-menu-content]:bg-danger-dark dark:text-black",
      "[&>.mega-menu-content]:shadow-[0px_4px_6px_-4px_var(--color-shadow-danger)] [&>.mega-menu-content]:shadow-[0px_10px_15px_-3px_var(--color-shadow-danger)] dark:[&>.mega-menu-content]:shadow-none"
    ]
  end

  defp color_variant("shadow", "info") do
    [
      "[&>.mega-menu-content]:bg-info-light text-white dark:[&>.mega-menu-content]:bg-info-dark dark:text-black",
      "[&>.mega-menu-content]:shadow-[0px_4px_6px_-4px_var(--color-shadow-info)] [&>.mega-menu-content]:shadow-[0px_10px_15px_-3px_var(--color-shadow-info)] dark:[&>.mega-menu-content]:shadow-none"
    ]
  end

  defp color_variant("shadow", "misc") do
    [
      "[&>.mega-menu-content]:bg-misc-light text-white dark:[&>.mega-menu-content]:bg-misc-dark dark:text-black",
      "[&>.mega-menu-content]:shadow-[0px_4px_6px_-4px_var(--color-shadow-misc)] [&>.mega-menu-content]:shadow-[0px_10px_15px_-3px_var(--color-shadow-misc)] dark:[&>.mega-menu-content]:shadow-none"
    ]
  end

  defp color_variant("shadow", "dawn") do
    [
      "[&>.mega-menu-content]:bg-dawn-light text-white dark:[&>.mega-menu-content]:bg-dawn-dark dark:text-black",
      "[&>.mega-menu-content]:shadow-[0px_4px_6px_-4px_var(--color-shadow-dawn)] [&>.mega-menu-content]:shadow-[0px_10px_15px_-3px_var(--color-shadow-dawn)] dark:[&>.mega-menu-content]:shadow-none"
    ]
  end

  defp color_variant("shadow", "silver") do
    [
      "[&>.mega-menu-content]:bg-silver-light text-white dark:[&>.mega-menu-content]:bg-silver-dark dark:text-black",
      "[&>.mega-menu-content]:shadow-[0px_4px_6px_-4px_var(--color-shadow-silver)] [&>.mega-menu-content]:shadow-[0px_10px_15px_-3px_var(--color-shadow-silver)] dark:[&>.mega-menu-content]:shadow-none"
    ]
  end

  defp color_variant("bordered", "white") do
    [
      "[&>.mega-menu-content]:bg-white text-black [&>.mega-menu-content]:border-bordered-white-border"
    ]
  end

  defp color_variant("bordered", "dark") do
    [
      "[&>.mega-menu-content]:bg-bordered-dark-bg text-white [&>.mega-menu-content]:border-bordered-dark-border"
    ]
  end

  defp color_variant("bordered", "natural") do
    [
      "text-natural-bordered-text-light [&>.mega-menu-content]:border-natural-bordered-text-light [&>.mega-menu-content]:bg-natural-bordered-bg-light",
      "dark:text-natural-bordered-text-dark dark:[&>.mega-menu-content]:border-natural-border-dark dark:[&>.mega-menu-content]:bg-natural-bordered-bg-dark"
    ]
  end

  defp color_variant("bordered", "primary") do
    [
      "text-primary-bordered-text-light [&>.mega-menu-content]:border-primary-bordered-text-light [&>.mega-menu-content]:bg-primary-bordered-bg-light",
      "dark:text-primary-bordered-text-dark dark:[&>.mega-menu-content]:border-primary-bordered-text-dark dark:[&>.mega-menu-content]:bg-primary-bordered-bg-dark"
    ]
  end

  defp color_variant("bordered", "secondary") do
    [
      "text-secondary-bordered-text-light [&>.mega-menu-content]:border-secondary-bordered-text-light [&>.mega-menu-content]:bg-secondary-bordered-bg-light",
      "dark:text-secondary-bordered-text-dark dark:[&>.mega-menu-content]:border-secondary-bordered-text-dark dark:[&>.mega-menu-content]:bg-secondary-bordered-bg-dark"
    ]
  end

  defp color_variant("bordered", "success") do
    [
      "text-success-bordered-text-light [&>.mega-menu-content]:border-success-bordered-text-light [&>.mega-menu-content]:bg-success-bordered-bg-light",
      "dark:text-success-bordered-text-dark dark:[&>.mega-menu-content]:border-success-bordered-text-dark dark:[&>.mega-menu-content]:bg-success-bordered-bg-dark"
    ]
  end

  defp color_variant("bordered", "warning") do
    [
      "text-warning-bordered-text-light [&>.mega-menu-content]:border-warning-bordered-text-light [&>.mega-menu-content]:bg-warning-bordered-bg-light",
      "dark:text-warning-bordered-text-dark dark:[&>.mega-menu-content]:border-warning-bordered-text-dark dark:[&>.mega-menu-content]:bg-warning-bordered-bg-dark"
    ]
  end

  defp color_variant("bordered", "danger") do
    [
      "text-danger-bordered-text-light [&>.mega-menu-content]:border-danger-bordered-text-light [&>.mega-menu-content]:bg-danger-bordered-bg-light",
      "dark:text-danger-bordered-text-dark dark:[&>.mega-menu-content]:border-danger-bordered-text-dark dark:[&>.mega-menu-content]:bg-danger-bordered-bg-dark"
    ]
  end

  defp color_variant("bordered", "info") do
    [
      "text-info-bordered-text-light [&>.mega-menu-content]:border-info-bordered-text-light [&>.mega-menu-content]:bg-info-bordered-bg-light",
      "dark:text-info-bordered-text-dark dark:[&>.mega-menu-content]:border-info-bordered-text-dark dark:[&>.mega-menu-content]:bg-info-bordered-bg-dark"
    ]
  end

  defp color_variant("bordered", "misc") do
    [
      "text-misc-bordered-text-light [&>.mega-menu-content]:border-misc-bordered-text-light [&>.mega-menu-content]:bg-misc-bordered-bg-light",
      "dark:text-misc-bordered-text-dark dark:[&>.mega-menu-content]:border-misc-bordered-text-dark dark:[&>.mega-menu-content]:bg-misc-bordered-bg-dark"
    ]
  end

  defp color_variant("bordered", "dawn") do
    [
      "text-dawn-bordered-text-light [&>.mega-menu-content]:border-dawn-bordered-text-light [&>.mega-menu-content]:bg-dawn-bordered-bg-light",
      "dark:text-dawn-bordered-text-dark dark:[&>.mega-menu-content]:border-dawn-bordered-text-dark dark:[&>.mega-menu-content]:bg-dawn-bordered-bg-dark"
    ]
  end

  defp color_variant("bordered", "silver") do
    [
      "text-silver-bordered-text-light [&>.mega-menu-content]:border-silver-bordered-text-light [&>.mega-menu-content]:bg-silver-bordered-bg-light",
      "dark:text-silver-bordered-text-dark dark:[&>.mega-menu-content]:border-silver-bordered-text-dark dark:[&>.mega-menu-content]:bg-silver-bordered-bg-dark"
    ]
  end

  defp color_variant("gradient", "natural") do
    [
      "[&>.mega-menu-content]:bg-gradient-to-br from-gradient-natural-from-light to-gradient-natural-to-light text-white",
      "dark:from-gradient-natural-from-dark dark:to-white dark:text-black"
    ]
  end

  defp color_variant("gradient", "primary") do
    [
      "[&>.mega-menu-content]:bg-gradient-to-br from-gradient-primary-from-light to-gradient-primary-to-light text-white",
      "dark:from-gradient-primary-from-dark dark:to-gradient-primary-to-dark dark:text-black"
    ]
  end

  defp color_variant("gradient", "secondary") do
    [
      "[&>.mega-menu-content]:bg-gradient-to-br from-gradient-secondary-from-light to-gradient-secondary-to-light text-white",
      "dark:from-gradient-secondary-from-dark dark:to-gradient-secondary-to-dark dark:text-black"
    ]
  end

  defp color_variant("gradient", "success") do
    [
      "[&>.mega-menu-content]:bg-gradient-to-br from-gradient-success-from-light to-gradient-success-to-light text-white",
      "dark:from-gradient-success-from-dark dark:to-gradient-success-to-dark dark:text-black"
    ]
  end

  defp color_variant("gradient", "warning") do
    [
      "[&>.mega-menu-content]:bg-gradient-to-br from-gradient-warning-from-light to-gradient-warning-to-light text-white",
      "dark:from-gradient-warning-from-dark dark:to-gradient-warning-to-dark dark:text-black"
    ]
  end

  defp color_variant("gradient", "danger") do
    [
      "[&>.mega-menu-content]:bg-gradient-to-br from-gradient-danger-from-light to-gradient-danger-to-light text-white",
      "dark:from-gradient-danger-from-dark dark:to-gradient-danger-to-dark dark:text-black"
    ]
  end

  defp color_variant("gradient", "info") do
    [
      "[&>.mega-menu-content]:bg-gradient-to-br from-gradient-info-from-light to-gradient-info-to-light text-white",
      "dark:from-gradient-info-from-dark dark:to-gradient-info-to-dark dark:text-black"
    ]
  end

  defp color_variant("gradient", "misc") do
    [
      "[&>.mega-menu-content]:bg-gradient-to-br from-gradient-misc-from-light to-gradient-misc-to-light text-white",
      "dark:from-gradient-misc-from-dark dark:to-gradient-misc-to-dark dark:text-black"
    ]
  end

  defp color_variant("gradient", "dawn") do
    [
      "[&>.mega-menu-content]:bg-gradient-to-br from-gradient-dawn-from-light to-gradient-dawn-to-light text-white",
      "dark:from-gradient-dawn-from-dark dark:to-gradient-dawn-to-dark dark:text-black"
    ]
  end

  defp color_variant("gradient", "silver") do
    [
      "[&>.mega-menu-content]:bg-gradient-to-br from-gradient-silver-from-light to-gradient-silver-to-light text-white",
      "dark:from-gradient-silver-from-dark dark:to-gradient-silver-to-dark dark:text-black"
    ]
  end

  defp color_variant(params, _) when is_binary(params), do: params
end
