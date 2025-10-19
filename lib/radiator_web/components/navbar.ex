defmodule RadiatorWeb.Components.Navbar do
  @moduledoc """
  The `RadiatorWeb.Components.Navbar` module provides a flexible and customizable navigation
  bar component for Phoenix LiveView applications. It allows for a variety of styles,
  colors, and configurations to fit different design needs, including border styles,
  content alignment, and text positioning.

  This component supports nested elements through slots, enabling complex navigation structures.

  It also offers extensive theming options, such as rounded corners, shadow effects,
  and maximum width settings.

  With built-in support for icons and images, the `Navbar` module makes it easy to create
  visually appealing and interactive navigation bars that enhance the user experience.

  **Documentation:** https://mishka.tools/chelekom/docs/navbar
  """
  use Phoenix.Component
  import RadiatorWeb.Components.Icon, only: [icon: 1]
  use Gettext, backend: RadiatorWeb.Gettext

  @doc """
  Renders a customizable navigation bar (`navbar` component) that can include links,
  dropdowns, and other components.

  The navigation bar is designed to handle various styles, colors, and layouts.

  ## Examples

  ```elixir
  <.navbar id="nav-11" color="success" variant="shadow">
    <:list><.link navigate="/">Home</.link></:list>
    <:list><.link navigate="/examples/sidebar">List</.link></:list>

    <:list>
      <.dropdown relative="md:relative" width="w-full" clickable>
        <:trigger width="full" trigger_id="test-31">
          <button class="text-start w-full block">Dropdown</button>
        </:trigger>

        <:content space="small" id="test-31" rounded="large" width="large" padding="extra_small">
          <ul class="space-y-5">
            <li>
              <.dropdown width="w-full" position="right" clickable>
                <:trigger trigger_id="test-19">
                  <button class={[
                    "py-1 px-2 text-start w-full flex items-center justify-between hover:bg-gray-200"
                  ]}
                  >
                    Nested Dropdown <.icon name="hero-chevron-right" />
                  </button>
                </:trigger>

                <:content id="test-19" rounded="large" width="large" padding="extra_small">
                  <ul class="space-y-5">
                    <li>
                      <.link class="py-1 px-2 block hover:bg-gray-200" navigate="/examples/list">
                        Security
                      </.link>
                    </li>

                    <li>
                      <.link class="py-1 px-2 block hover:bg-gray-200" navigate="/examples/dropdown">
                        Memory
                      </.link>
                    </li>

                    <li>
                      <.link class="py-1 px-2 block hover:bg-gray-200" navigate="/examples/image">
                        Design
                      </.link>
                    </li>
                  </ul>
                </:content>
              </.dropdown>
            </li>

            <li>
              <.link class="py-1 px-2 block hover:bg-gray-200" navigate="/examples/dropdown">
                Memory
              </.link>
            </li>

            <li>
              <.link class="py-1 px-2 block hover:bg-gray-200" navigate="/examples/image">
                Design
              </.link>
            </li>
          </ul>
        </:content>
      </.dropdown>
    </:list>

    <:list><.link navigate="/examples/rating">Blog</.link></:list>
    <:list><.link navigate="/examples/sidebar">Calendar</.link></:list>
    <:list><.link navigate="/examples/rating">Booking</.link></:list>
    <:list><.link navigate="/examples/sidebar">Partners</.link></:list>
    <:list><.link navigate="/examples/rating">About</.link></:list>
  </.navbar>
  ```
  """
  @doc type: :component
  attr :id, :string,
    required: true,
    doc: "A unique identifier is used to manage state and interaction"

  attr :variant, :string, default: "base", doc: "Determines the style"
  attr :color, :string, default: "natural", doc: "Determines color theme"
  attr :border, :string, default: "extra_small", doc: "Determines border style"
  attr :text_position, :string, default: "", doc: "Determines the element's text position"
  attr :rounded, :string, default: "", doc: "Determines the border radius"
  attr :max_width, :string, default: "", doc: "Determines the style of element max width"

  attr :content_position, :string,
    default: "between",
    doc: "Determines the alignment of the element's content"

  attr :image, :string, default: nil, doc: "Image displayed alongside of an item"
  attr :image_class, :string, default: nil, doc: "Determines custom class for the image"
  attr :name, :string, default: nil, doc: "Specifies the name of the element"
  attr :relative, :boolean, default: false, doc: ""
  attr :link, :string, default: nil, doc: ""
  attr :space, :string, default: "", doc: "Space between items"

  attr :font_weight, :string,
    default: "font-normal",
    doc: "Determines custom class for the font weight"

  attr :padding, :string, default: "small", doc: "Determines padding for items"
  attr :class, :string, default: nil, doc: "Custom CSS class for additional styling"
  attr :nav_wrapper_class, :string, default: nil, doc: "Custom CSS class for nav wrapper"
  attr :link_class, :string, default: nil, doc: "Custom CSS class for link"
  attr :list_wrapper_class, :string, default: nil, doc: "Custom CSS class for list main wrapper"
  attr :list_class, :string, default: nil, doc: "Custom CSS class for list ul"

  attr :rest, :global,
    doc:
      "Global attributes can define defaults which are merged with attributes provided by the caller"

  slot :start_content, required: false do
    attr :class, :string, doc: "Custom CSS class for additional styling"
  end

  slot :inner_block, required: false, doc: "Inner block that renders HEEx content"

  slot :end_content, required: false do
    attr :class, :string, doc: "Custom CSS class for additional styling"
  end

  slot :list, required: false do
    attr :class, :string, doc: "Custom CSS class for additional styling"
    attr :padding, :string, doc: "Determines padding for items"
    attr :icon, :string, doc: "Icon displayed alongside of an item"
    attr :icon_class, :string, doc: "Determines custom class for the icon"
    attr :icon_position, :string, doc: "Determines icon position"
  end

  def navbar(assigns) do
    ~H"""
    <nav
      id={@id}
      role="navigation"
      class={[
        "relative",
        "[&.show-nav-menu_.nav-menu]:block [&.show-nav-menu_.nav-menu]:opacity-100",
        border_class(@border, @variant),
        content_position(@content_position),
        color_variant(@variant, @color),
        rounded_size(@rounded),
        padding_size(@padding),
        text_position(@text_position),
        maximum_width(@max_width),
        space_class(@space),
        @font_weight,
        @class
      ]}
      {@rest}
    >
      <div class={["nav-wrapper md:flex items-center gap-2 md:gap-5", @nav_wrapper_class]}>
        <div :if={@start_content != [] and !is_nil(@start_content)} class={@start_content[:class]}>
          {render_slot(@start_content)}
        </div>
        <.link
          :if={!is_nil(@link)}
          navigate={@link}
          class={["flex items-center space-x-3 rtl:space-x-reverse mb-5 md:mb-0", @link_class]}
        >
          <img :if={!is_nil(@image)} src={@image} class={@image_class} alt={gettext("Logo")} />
          <h1 :if={!is_nil(@name)} class="text-xl font-semibold">
            {@name}
          </h1>
        </.link>

        <div :if={!is_nil(@list) && length(@list) > 0} class={["w-auto", @list_wrapper_class]}>
          <ul
            role="menubar"
            class={["flex flex-wrap md:flex-nowrap gap-4", @relative && "relative", @list_class]}
          >
            <li
              :for={list <- @list}
              role="none"
              class={[
                "inline-flex items-center",
                list[:icon_position] == "end" && "flex-row-reverse",
                list[:class]
              ]}
            >
              <.icon :if={list[:icon]} name={list[:icon]} class={["list-icon", list[:icon_class]]} />
              {render_slot(list)}
            </li>
          </ul>
        </div>
        {render_slot(@inner_block)}
        <div :if={@end_content != [] and !is_nil(@end_content)} class={@end_content[:class]}>
          {render_slot(@end_content)}
        </div>
      </div>
    </nav>
    """
  end

  @doc """
  Renders a header with title.
  """
  @doc type: :component
  attr :class, :string, default: nil

  slot :inner_block, required: true
  slot :subtitle
  slot :actions

  def header(assigns) do
    ~H"""
    <header class={[@actions != [] && "flex items-center justify-between gap-6", @class]}>
      <div>
        <h1 class="text-lg font-semibold leading-8 text-zinc-800">
          {render_slot(@inner_block)}
        </h1>
        <p :if={@subtitle != []} class="mt-2 text-sm leading-6 text-zinc-600">
          {render_slot(@subtitle)}
        </p>
      </div>
      <div class="flex-none">{render_slot(@actions)}</div>
    </header>
    """
  end

  defp content_position("start") do
    "[&_.nav-wrapper]:justify-start"
  end

  defp content_position("end") do
    "[&_.nav-wrapper]:justify-end"
  end

  defp content_position("center") do
    "[&_.nav-wrapper]:justify-center"
  end

  defp content_position("between") do
    "[&_.nav-wrapper]:justify-between"
  end

  defp content_position("around") do
    "[&_.nav-wrapper]:justify-around"
  end

  defp content_position(params) when is_binary(params), do: params

  defp text_position("left"), do: "text-left"
  defp text_position("right"), do: "text-right"
  defp text_position("center"), do: "text-center"
  defp text_position(params) when is_binary(params), do: params

  defp space_class("extra_small"), do: "space-y-2"

  defp space_class("small"), do: "space-y-3"

  defp space_class("medium"), do: "space-y-4"

  defp space_class("large"), do: "space-y-5"

  defp space_class("extra_large"), do: "space-y-6"

  defp space_class(params) when is_binary(params), do: params

  defp maximum_width("extra_small"), do: "[&_.nav-wrapper]:max-w-3xl [&_.nav-wrapper]:mx-auto"
  defp maximum_width("small"), do: "[&_.nav-wrapper]:max-w-4xl [&_.nav-wrapper]:mx-auto"
  defp maximum_width("medium"), do: "[&_.nav-wrapper]:max-w-5xl [&_.nav-wrapper]:mx-auto"
  defp maximum_width("large"), do: "[&_.nav-wrapper]:max-w-6xl [&_.nav-wrapper]:mx-auto"
  defp maximum_width("extra_large"), do: "[&_.nav-wrapper]:max-w-7xl [&_.nav-wrapper]:mx-auto"
  defp maximum_width(params) when is_binary(params), do: params

  defp padding_size("extra_small"), do: "p-1"

  defp padding_size("small"), do: "p-2"

  defp padding_size("medium"), do: "p-3"

  defp padding_size("large"), do: "p-4"

  defp padding_size("extra_large"), do: "p-5"

  defp padding_size("none"), do: "p-0"

  defp padding_size(params) when is_binary(params), do: params

  defp border_class(_, variant) when variant in ["default", "shadow", "gradient"],
    do: nil

  defp border_class("none", _), do: "border-b-0"
  defp border_class("extra_small", _), do: "border-b"
  defp border_class("small", _), do: "border-b-2"
  defp border_class("medium", _), do: "border-b-[3px]"
  defp border_class("large", _), do: "border-b-4"
  defp border_class("extra_large", _), do: "border-b-[5px]"
  defp border_class(params, _) when is_binary(params), do: params

  defp rounded_size("extra_small"), do: "rounded-b-sm"

  defp rounded_size("small"), do: "rounded-b"

  defp rounded_size("medium"), do: "rounded-b-md"

  defp rounded_size("large"), do: "rounded-b-lg"

  defp rounded_size("extra_large"), do: "rounded-b-xl"

  defp rounded_size(params) when is_binary(params), do: params

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
      "bg-bordered-dark-bg text-white border-bordered-dark-border"
    ]
  end

  defp color_variant("bordered", "natural") do
    [
      "text-natural-bordered-text-light border-natural-bordered-text-light bg-natural-bordered-bg-light",
      "dark:text-natural-bordered-text-dark dark:border-natural-bordered-text-dark dark:bg-natural-bordered-bg-dark"
    ]
  end

  defp color_variant("bordered", "primary") do
    [
      "text-primary-bordered-text-light border-primary-bordered-text-light bg-primary-bordered-bg-light",
      "dark:text-primary-bordered-text-dark dark:border-primary-bordered-text-dark dark:bg-primary-bordered-bg-dark"
    ]
  end

  defp color_variant("bordered", "secondary") do
    [
      "text-secondary-bordered-text-light border-secondary-bordered-text-light bg-secondary-bordered-bg-light",
      "dark:text-secondary-bordered-text-dark dark:border-secondary-bordered-text-dark dark:bg-secondary-bordered-bg-dark"
    ]
  end

  defp color_variant("bordered", "success") do
    [
      "text-success-bordered-text-light border-success-bordered-text-light bg-success-bordered-bg-light",
      "dark:text-success-bordered-text-dark dark:border-success-bordered-text-dark dark:bg-success-bordered-bg-dark"
    ]
  end

  defp color_variant("bordered", "warning") do
    [
      "text-warning-bordered-text-light border-warning-bordered-text-light bg-warning-bordered-bg-light",
      "dark:text-warning-bordered-text-dark dark:border-warning-bordered-text-dark dark:bg-warning-bordered-bg-dark"
    ]
  end

  defp color_variant("bordered", "danger") do
    [
      "text-danger-bordered-text-light border-danger-bordered-text-light bg-danger-bordered-bg-light",
      "dark:text-danger-bordered-text-dark dark:border-danger-bordered-text-dark dark:bg-danger-bordered-bg-dark"
    ]
  end

  defp color_variant("bordered", "info") do
    [
      "text-info-bordered-text-light border-info-bordered-text-light bg-info-bordered-bg-light",
      "dark:text-info-bordered-text-dark dark:border-info-bordered-text-dark dark:bg-info-bordered-bg-dark"
    ]
  end

  defp color_variant("bordered", "misc") do
    [
      "text-misc-bordered-text-light border-misc-bordered-text-light bg-misc-bordered-bg-light",
      "dark:text-misc-bordered-text-dark dark:border-misc-bordered-text-dark dark:bg-misc-bordered-bg-dark"
    ]
  end

  defp color_variant("bordered", "dawn") do
    [
      "text-dawn-bordered-text-light border-dawn-bordered-text-light bg-dawn-bordered-bg-light",
      "dark:text-dawn-bordered-text-dark dark:border-dawn-bordered-text-dark dark:bg-dawn-bordered-bg-dark"
    ]
  end

  defp color_variant("bordered", "silver") do
    [
      "text-silver-bordered-text-light border-silver-bordered-text-light bg-silver-bordered-bg-light",
      "dark:text-silver-bordered-text-dark dark:border-silver-bordered-text-dark dark:bg-silver-bordered-bg-dark"
    ]
  end

  defp color_variant("gradient", "natural") do
    [
      "bg-gradient-to-br from-gradient-natural-from-light to-gradient-natural-to-light text-white",
      "dark:from-gradient-natural-from-dark dark:to-white dark:text-black"
    ]
  end

  defp color_variant("gradient", "primary") do
    [
      "bg-gradient-to-br from-gradient-primary-from-light to-gradient-primary-to-light text-white",
      "dark:from-gradient-primary-from-dark dark:to-gradient-primary-to-dark dark:text-black"
    ]
  end

  defp color_variant("gradient", "secondary") do
    [
      "bg-gradient-to-br from-gradient-secondary-from-light to-gradient-secondary-to-light text-white",
      "dark:from-gradient-secondary-from-dark dark:to-gradient-secondary-to-dark dark:text-black"
    ]
  end

  defp color_variant("gradient", "success") do
    [
      "bg-gradient-to-br from-gradient-success-from-light to-gradient-success-to-light text-white",
      "dark:from-gradient-success-from-dark dark:to-gradient-success-to-dark dark:text-black"
    ]
  end

  defp color_variant("gradient", "warning") do
    [
      "bg-gradient-to-br from-gradient-warning-from-light to-gradient-warning-to-light text-white",
      "dark:from-gradient-warning-from-dark dark:to-gradient-warning-to-dark dark:text-black"
    ]
  end

  defp color_variant("gradient", "danger") do
    [
      "bg-gradient-to-br from-gradient-danger-from-light to-gradient-danger-to-light text-white",
      "dark:from-gradient-danger-from-dark dark:to-gradient-danger-to-dark dark:text-black"
    ]
  end

  defp color_variant("gradient", "info") do
    [
      "bg-gradient-to-br from-gradient-info-from-light to-gradient-info-to-light text-white",
      "dark:from-gradient-info-from-dark dark:to-gradient-info-to-dark dark:text-black"
    ]
  end

  defp color_variant("gradient", "misc") do
    [
      "bg-gradient-to-br from-gradient-misc-from-light to-gradient-misc-to-light text-white",
      "dark:from-gradient-misc-from-dark dark:to-gradient-misc-to-dark dark:text-black"
    ]
  end

  defp color_variant("gradient", "dawn") do
    [
      "bg-gradient-to-br from-gradient-dawn-from-light to-gradient-dawn-to-light text-white",
      "dark:from-gradient-dawn-from-dark dark:to-gradient-dawn-to-dark dark:text-black"
    ]
  end

  defp color_variant("gradient", "silver") do
    [
      "bg-gradient-to-br from-gradient-silver-from-light to-gradient-silver-to-light text-white",
      "dark:from-gradient-silver-from-dark dark:to-gradient-silver-to-dark dark:text-black"
    ]
  end

  defp color_variant(params, _) when is_binary(params), do: params
end
