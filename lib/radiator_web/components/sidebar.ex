defmodule RadiatorWeb.Components.Sidebar do
  @moduledoc """
  The `RadiatorWeb.Components.Sidebar` module provides a versatile and customizable sidebar
  component for Phoenix LiveView applications. This component is designed to create a
  navigation or information panel that can be toggled in and out of view, enhancing the user
  experience by offering easy access to additional content or navigation links.

  The component supports various configuration options, such as color themes, border styles,
  size, and positioning. It also allows developers to control the visibility and behavior of
  the sidebar through custom JavaScript actions. The sidebar can be positioned on either side of
  the screen, and it includes options for different visual variants, such as shadowed or transparent styles.

  The `Sidebar` component is ideal for building dynamic user interfaces that require collapsible
  navigation or content panels, and it integrates seamlessly with other Phoenix LiveView components
  for a cohesive and interactive application experience.

  **Documentation:** https://mishka.tools/chelekom/docs/sidebar
  """
  use Phoenix.Component
  use Gettext, backend: RadiatorWeb.Gettext
  alias Phoenix.LiveView.JS
  import RadiatorWeb.Components.Icon, only: [icon: 1]
  import Phoenix.LiveView.Utils, only: [random_id: 0]

  @doc """
  Renders a `sidebar` component that can be shown or hidden based on user interactions.

  The sidebar supports various customizations such as size, color theme, and border style.

  ## Examples

  ```elixir
  <.sidebar id="left" size="extra_small" color="dark" hide_position="left">
    <div class="px-4 py-2">
      <h2 class="text-white">Menu</h2>
      ...
    </div>
  </.sidebar>
  ```
  """
  @doc type: :component
  attr :id, :string,
    required: true,
    doc: "A unique identifier is used to manage state and interaction"

  attr :variant, :string, default: "base", doc: "Determines the style"
  attr :color, :string, default: "natural", doc: "Determines color theme"

  attr :size, :string,
    default: "large",
    doc:
      "Determines the overall size of the elements, including padding, font size, and other items"

  attr :border, :string, default: "extra_small", doc: "Determines border style"

  attr :minimize, :boolean,
    default: false,
    doc: "Determines Minimize button show or hide"

  attr :position, :string, default: "start", doc: "Determines the element position"

  attr :hide_position, :string,
    values: ["left", "right"],
    doc: "Determines what position should be hidden"

  attr :class, :string, default: nil, doc: "Custom CSS class for additional styling"
  attr :hide_button_class, :string, default: nil, doc: "Custom CSS class for additional styling"

  attr :minimize_wrapper_class, :string,
    default: nil,
    doc: "Custom CSS class for additional styling"

  attr :close_wrapper_class, :string, default: nil, doc: "Custom CSS class for additional styling"
  attr :content_class, :string, default: nil, doc: "Custom CSS class for additional styling"
  attr :minimize_icon_class, :string, default: nil, doc: "Custom CSS class for additional styling"
  attr :close_icon_class, :string, default: nil, doc: "Custom CSS class for additional styling"

  attr :close_button_class, :string,
    default: nil,
    doc: "Custom CSS class for additional styling for button"

  attr :list_wrapper_class, :string,
    default: nil,
    doc: "Custom CSS class for additional to list wrapper"

  attr :on_hide, JS, default: %JS{}, doc: "Custom JS module for on_hide action"
  attr :on_show, JS, default: %JS{}, doc: "Custom JS module for on_show action"
  attr :on_hide_away, JS, default: %JS{}, doc: "Custom JS module for on_hide_away action"

  attr :rest, :global,
    doc:
      "Global attributes can define defaults which are merged with attributes provided by the caller"

  slot :item, doc: "Menu item slot for sidebar navigation items" do
    attr :icon, :string, doc: "Icon name to display"
    attr :icon_class, :string, doc: "CSS class for the icon"
    attr :label, :string, doc: "Text label for the menu item"
    attr :label_class, :string, doc: "CSS class for the label text"
    attr :link, :string, doc: "URL for the item link"
    attr :class, :string, doc: "CSS class for the entire item"
    attr :link_class, :string, doc: "CSS class for the link"
  end

  slot :inner_block, required: false, doc: "Inner block that renders HEEx content"

  @spec sidebar(map()) :: Phoenix.LiveView.Rendered.t()
  def sidebar(assigns) do
    assigns =
      assigns
      |> assign_new(:id, fn -> "sidebar-#{random_id()}" end)

    ~H"""
    <aside
      id={@id}
      phx-click-away={hide_sidebar(@on_hide_away, @id, @hide_position)}
      phx-remove={hide_sidebar(@id, @hide_position)}
      role="complementary"
      class={[
        "fixed h-screen transition-transform z-10 overflow-x-hidden",
        border_class(@border, @position, @variant),
        hide_position(@hide_position),
        color_variant(@variant, @color),
        position_class(@position),
        size_class(@size),
        @class
      ]}
      {@rest}
    >
      <div class={["h-full overflow-y-auto overflow-x-hidden", @content_class]}>
        <div :if={@minimize} class={["flex mb-0.5 justify-end", @minimize_wrapper_class]}>
          <button
            type="button"
            phx-hook="Sidebar"
            data-original-width={size_class(@size)}
            id={"toggle-button-#{@id}"}
            data-sidebar-selector={"##{@id}"}
            aria-label={gettext("Minimize sidebar")}
            class={[
              "size-8 flex items-center justify-center leading-5",
              "rounded focus:outline-none bg-gray-500/10 border",
              "dark:border-gray-700 m-2 text-gray-500",
              @hide_button_class
            ]}
          >
            <.icon name="hero-chevron-right" class={["minimize-icon size-5", @minimize_icon_class]} />
            <span class="sr-only">{gettext("Minimize sidebar")}</span>
          </button>
        </div>
        <div class={[
          "flex justify-end pt-2 px-2 mb-1 md:hidden dismiss-sidebar-wrapper",
          @close_wrapper_class
        ]}>
          <button
            type="button"
            class={["dismiss-sidebar-button focus:outline-none", @close_button_class]}
            aria-label={gettext("Close sidebar")}
            phx-click={JS.exec(@on_hide, "phx-remove", to: "##{@id}")}
          >
            <.icon name="hero-x-mark" class={@close_icon_class} />
            <span class="sr-only">{gettext("Close menu")}</span>
          </button>
        </div>

        <ul :if={@item != []} class={@list_wrapper_class} role="list">
          <li :for={item <- @item} class={item[:class]}>
            <.link
              href={item[:link]}
              class={["sidebar-item-link flex items-center leading-5", item[:link_class]]}
            >
              <.icon :if={item[:icon]} name={item[:icon]} class={["shrink-0", item[:icon_class]]} />
              <span class={["sidebar-text block ms-1", item[:label_class]]} data-item-label>
                {item[:label] || render_slot(item)}
              </span>
            </.link>
          </li>
        </ul>
        {render_slot(@inner_block)}
      </div>
    </aside>
    """
  end

  @doc """
  Shows the sidebar by applying specific CSS classes to animate it onto the screen.

  ## Parameters

    - `js`: A `Phoenix.LiveView.JS` struct used for managing client-side JavaScript interactions. Defaults to an empty `%JS{}`.
    - `id`: A unique identifier (string) for the sidebar element to be shown. This should correspond to the `id` attribute of the sidebar HTML element.
    - `position`: A string representing the initial position of the sidebar when hidden. Valid values include `"left"` or `"right"`, indicating whether the sidebar is off-screen to the left or right.

  ## Returns

    - Returns an updated `Phoenix.LiveView.JS` struct with the appropriate class changes applied to show the sidebar.

  ## Example

    ```elixir
    show_sidebar(%JS{}, "sidebar-id", "right")
    ```
  This will show the sidebar with the ID "sidebar-id" by sliding it onto the screen from the right.
  """

  def show_sidebar(js \\ %JS{}, id, position) when is_binary(id) do
    JS.remove_class(js, hide_position(position), to: "##{id}")
    |> JS.add_class("transform-none", to: "##{id}")
  end

  @doc """
  Hides the sidebar by applying specific CSS classes to animate it off-screen.

  ## Parameters

    - `js`: A `Phoenix.LiveView.JS` struct used for managing client-side JavaScript interactions. Defaults to an empty `%JS{}`.
    - `id`: A unique identifier (string) for the sidebar element to be hidden. The ID should correspond to the `id` attribute of the sidebar HTML element.
    - `position`: A string representing the direction in which the sidebar should be hidden. Valid values include `"left"` or `"right"`, indicating whether the sidebar will slide off the screen to the left or right, respectively.

  ## Returns

    - Returns an updated `Phoenix.LiveView.JS` struct with the appropriate class changes applied to hide the sidebar.

  ## Example

    ```elixir
    hide_sidebar(%JS{}, "sidebar-id", "left")
    ```

  This will hide the sidebar with the ID "sidebar-id" by sliding it off-screen to the left.
  """

  def hide_sidebar(js \\ %JS{}, id, position) do
    JS.remove_class(js, "transform-none", to: "##{id}")
    |> JS.add_class(hide_position(position), to: "##{id}")
  end

  defp hide_position("left"), do: "-translate-x-full md:translate-x-0"
  defp hide_position("right"), do: "translate-x-full md:translate-x-0"
  defp hide_position(_), do: nil

  defp position_class("start"), do: "top-0 start-0"
  defp position_class("end"), do: "top-0 end-0"
  defp position_class(params) when is_binary(params), do: params

  defp border_class(_, _, variant)
       when variant in ["default", "shadow", "transparent", "gradient"],
       do: nil

  defp border_class("none", _, _), do: "border-0"
  defp border_class("extra_small", "start", _), do: "border-e"
  defp border_class("small", "start", _), do: "border-e-2"
  defp border_class("medium", "start", _), do: "border-e-[3px]"
  defp border_class("large", "start", _), do: "border-e-4"
  defp border_class("extra_large", "start", _), do: "border-e-[5px]"

  defp border_class("extra_small", "end", _), do: "border-s"
  defp border_class("small", "end", _), do: "border-s-2"
  defp border_class("medium", "end", _), do: "border-s-[3px]"
  defp border_class("large", "end", _), do: "border-s-4"
  defp border_class("extra_large", "end", _), do: "border-s-[5px]"

  defp border_class(params, _, _) when is_binary(params), do: params

  defp size_class("extra_small"), do: "w-60"

  defp size_class("small"), do: "w-64"

  defp size_class("medium"), do: "w-72"

  defp size_class("large"), do: "w-80"

  defp size_class("extra_large"), do: "w-96"

  defp size_class(params) when is_binary(params), do: params

  defp color_variant("base", _) do
    [
      "bg-white text-base-text-light border-base-border-light",
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
      "bg-natural-light text-white",
      "dark:bg-natural-dark dark:text-black"
    ]
  end

  defp color_variant("default", "primary") do
    [
      "bg-primary-light text-white",
      "dark:bg-primary-dark dark:text-black"
    ]
  end

  defp color_variant("default", "secondary") do
    [
      "bg-secondary-light text-white",
      "dark:bg-secondary-dark dark:text-black"
    ]
  end

  defp color_variant("default", "success") do
    [
      "bg-success-light text-white",
      "dark:bg-success-dark dark:text-black"
    ]
  end

  defp color_variant("default", "warning") do
    [
      "bg-danger-light text-white",
      "dark:bg-danger-dark dark:text-black"
    ]
  end

  defp color_variant("default", "danger") do
    [
      "bg-danger-light text-white",
      "dark:bg-danger-dark dark:text-black"
    ]
  end

  defp color_variant("default", "info") do
    [
      "bg-info-light text-white",
      "dark:bg-info-dark dark:text-black"
    ]
  end

  defp color_variant("default", "misc") do
    [
      "bg-misc-light text-white",
      "dark:bg-misc-dark dark:text-black"
    ]
  end

  defp color_variant("default", "dawn") do
    [
      "bg-dawn-light text-white",
      "dark:bg-dawn-dark dark:text-black"
    ]
  end

  defp color_variant("default", "silver") do
    [
      "bg-silver-light text-white",
      "dark:bg-silver-dark dark:text-black"
    ]
  end

  defp color_variant("outline", "natural") do
    [
      "bg-transparent text-natural-light border-natural-light",
      "dark:text-natural-dark dark:border-natural-dark"
    ]
  end

  defp color_variant("outline", "primary") do
    [
      "bg-transparent text-primary-light border-primary-light",
      "dark:text-primary-dark dark:border-primary-dark"
    ]
  end

  defp color_variant("outline", "secondary") do
    [
      "bg-transparent text-secondary-light border-secondary-light",
      "dark:text-secondary-dark dark:border-secondary-dark"
    ]
  end

  defp color_variant("outline", "success") do
    [
      "bg-transparent text-success-light border-success-light",
      "dark:text-success-dark dark:border-success-dark"
    ]
  end

  defp color_variant("outline", "warning") do
    [
      "bg-transparent text-warning-light border-warning-light",
      "dark:text-warning-dark dark:border-warning-dark"
    ]
  end

  defp color_variant("outline", "danger") do
    [
      "bg-transparent text-danger-light border-danger-light",
      "dark:text-danger-dark dark:border-danger-dark"
    ]
  end

  defp color_variant("outline", "info") do
    [
      "bg-transparent text-info-light border-info-light",
      "dark:text-info-dark dark:border-info-dark"
    ]
  end

  defp color_variant("outline", "misc") do
    [
      "bg-transparent text-misc-light border-misc-light",
      "dark:text-misc-dark dark:border-misc-dark"
    ]
  end

  defp color_variant("outline", "dawn") do
    [
      "bg-transparent text-dawn-light border-dawn-light",
      "dark:text-dawn-dark dark:border-dawn-dark"
    ]
  end

  defp color_variant("outline", "silver") do
    [
      "bg-transparent text-silver-light border-silver-light",
      "dark:text-silver-dark dark:border-silver-dark"
    ]
  end

  defp color_variant("transparent", "natural") do
    [
      "bg-transparent text-natural-light",
      "dark:text-natural-dark border-transparent"
    ]
  end

  defp color_variant("transparent", "primary") do
    [
      "bg-transparent text-primary-light",
      "dark:text-primary-dark border-transparent"
    ]
  end

  defp color_variant("transparent", "secondary") do
    [
      "bg-transparent text-secondary-light",
      "dark:text-secondary-dark border-transparent"
    ]
  end

  defp color_variant("transparent", "success") do
    [
      "bg-transparent text-success-light",
      "dark:text-success-dark border-transparent"
    ]
  end

  defp color_variant("transparent", "warning") do
    [
      "bg-transparent text-warning-light",
      "dark:text-warning-dark border-transparent"
    ]
  end

  defp color_variant("transparent", "danger") do
    [
      "bg-transparent text-danger-light",
      "dark:text-danger-dark border-transparent"
    ]
  end

  defp color_variant("transparent", "info") do
    [
      "bg-transparent text-info-light",
      "dark:text-info-dark border-transparent"
    ]
  end

  defp color_variant("transparent", "misc") do
    [
      "bg-transparent text-misc-light",
      "dark:text-misc-dark border-transparent"
    ]
  end

  defp color_variant("transparent", "dawn") do
    [
      "bg-transparent text-dawn-light",
      "dark:text-dawn-dark border-transparent"
    ]
  end

  defp color_variant("transparent", "silver") do
    [
      "bg-transparent text-silver-light",
      "dark:text-silver-dark border-transparent"
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
