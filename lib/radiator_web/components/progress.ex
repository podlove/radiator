defmodule RadiatorWeb.Components.Progress do
  @moduledoc """
  The `RadiatorWeb.Components.Progress` module provides a customizable progress bar component for
  Phoenix LiveView applications.

  It offers a range of styling options, including different sizes, colors, and variants,
  allowing developers to create both horizontal and vertical progress bars tailored to
  their design requirements.

  This component supports a variety of visual configurations, such as gradient backgrounds
  and rounded corners, and can be used in diverse use cases, from displaying loading states
  to indicating progress in forms and surveys.

  The module's flexibility is further enhanced by its use of `slots`, enabling developers
  to include custom label within the progress bar, making it a versatile choice for building
  interactive and dynamic UIs.

  **Documentation:** https://mishka.tools/chelekom/docs/progress
  """
  use Phoenix.Component
  alias Phoenix.LiveView.JS
  import Phoenix.LiveView.Utils, only: [random_id: 0]

  @doc """
  Renders a `progress` bar component that visually represents the completion status of a task.

  It supports both horizontal and vertical orientations and can be customized with various colors and styles.

  ## Examples

  ```elixir
  <.progress value={10} />
  <.progress color="primary" value={20} />
  <.progress color="secondary" value={30} />
  <.progress variation="vertical" color="primary" value={20} />

  <.progress>
    <.progress_section color="primary" value={10} />
    <.progress_section color="secondary" value={15} />
    <.progress_section color="misc" value={10} />
    <.progress_section color="danger" value={5} />
    <.progress_section color="warning" value={10} />
    <.progress_section color="success" value={10} />
    <.progress_section color="info" value={5} />
  </.progress>

  <.progress variation="horizontal" size="large" value={70}>
    <div class="absolute inset-y-0 left-0 flex items-center pl-3 text-white">
      70%
    </div>
  </.progress>

  <.progress variation="vertical" size="extra_large" value={80}>
    <div class="absolute bottom-0 left-0 flex items-center text-white">
      80%
    </div>
  </.progress>
  ```
  """
  @doc type: :component
  attr :id, :string,
    default: nil,
    doc: "A unique identifier is used to manage state and interaction"

  attr :value, :integer, default: nil, doc: "Value of input"

  attr :variation, :string,
    values: ["horizontal", "vertical"],
    default: "horizontal",
    doc: "Defines the layout orientation of the component"

  attr :color, :string, default: "natural", doc: "Determines color theme"
  attr :rounded, :string, default: "full", doc: "Determines the border radius"
  attr :variant, :string, default: "base", doc: "Determines the style"

  attr :size, :string,
    default: "small",
    doc:
      "Determines the overall size of the elements, including padding, font size, and other items"

  attr :class, :string, default: nil, doc: "Custom CSS class for additional styling"
  attr :csp_nonce, :string, default: nil, doc: "csp nonce"

  attr :rest, :global,
    doc:
      "Global attributes can define defaults which are merged with attributes provided by the caller"

  slot :inner_block, doc: "Inner block that renders HEEx label"

  def progress(assigns) do
    ~H"""
    <div
      role="progressbar"
      aria-valuenow={@value}
      class={[
        "bg-default-light-gray dark:bg-default-gray overflow-hidden",
        @variation == "vertical" && "flex items-end vertical-progress overflow-y-hidden",
        size_class(@size, @variation),
        rounded_size(@rounded)
      ]}
      {@rest}
    >
      <.progress_section :if={@value} {assigns} />
      <div
        :if={msg = render_slot(@inner_block)}
        class={[
          "flex",
          (@variation == "horizontal" && "flex-row") || "flex-col flex-col-reverse w-full h-full"
        ]}
      >
        {msg}
      </div>
    </div>
    """
  end

  @doc """
  Displays a semicircular progress indicator.

  ## Attributes
    - value: The progress value (0 to 100)
    - size: The SVG size (width), default is 100
    - thickness: The stroke width of the circle, default is 10
    - color: Determines the color theme; default is "natural"
  """
  attr :id, :string, default: nil, doc: "HTML ID for the container"
  attr :value, :integer, required: true, doc: "Progress value (0 to 100)"
  attr :size, :integer, default: 200, doc: "Diameter of the circle in px"
  attr :thickness, :integer, default: 12, doc: "Stroke width"
  attr :orientation, :string, default: "up", doc: "'up' or 'down'"
  attr :fill_direction, :string, default: "left-to-right", doc: "Direction of fill"
  attr :transition_duration, :integer, default: 300, doc: "Transition duration in ms"
  attr :class, :string, default: nil, doc: "Custom CSS class for additional styling"
  attr :linecap, :string, default: nil, doc: "add radius to progress"
  attr :color, :string, default: "natural", doc: "Determines color theme"

  attr :label, :string, default: nil, doc: "Optional label"

  attr :rest, :global,
    doc:
      "Global attributes can define defaults which are merged with attributes provided by the caller"

  def semi_circle_progress(assigns) do
    coordinate = assigns.size / 2
    radius = (assigns.size - 2 * assigns.thickness) / 2
    circumference = :math.pi() * radius
    progress = clamp(assigns.value, 0, 100) * (circumference / 100)

    assigns =
      assigns
      |> assign(:coordinate, coordinate)
      |> assign(:radius, radius)
      |> assign(:circumference, circumference)
      |> assign(:progress, progress)

    ~H"""
    <div
      id={@id}
      role="progressbar"
      aria-valuenow={@value}
      class={[
        "relative overflow-hidden w-fit",
        color_variant(nil, @color),
        @class
      ]}
      {@rest}
    >
      <svg
        width={@size}
        height={@size / 2}
        viewBox={"0 0 #{@size} #{@size / 2}"}
        class={["block", progress_rotation_class(@orientation, @fill_direction)]}
      >
        <circle
          cx={@coordinate}
          cy={@coordinate}
          r={@radius}
          fill="none"
          class="semi-circle-progress-base stroke-default-light-gray dark:stroke-default-gray"
          stroke-width={@thickness}
          stroke-dasharray={@circumference}
          stroke-dashoffset={@circumference}
        />

        <circle
          cx={@coordinate}
          cy={@coordinate}
          r={@radius}
          fill="none"
          stroke-linecap={@linecap}
          stroke-width={@thickness}
          stroke-dasharray={@circumference}
          stroke-dashoffset={@progress}
          class={[
            "semi-circle-progress-bar transition-all ease-in-out",
            "duration-[#{@transition_duration}ms]",
            @color
          ]}
        />
      </svg>

      <div
        :if={@label || @value}
        class={[
          "z-10 absolute left-1/2 transform -translate-x-1/2 font-medium",
          @orientation == "up" && "top-1/2",
          @orientation == "down" && "top-0 translate-y-1/2"
        ]}
      >
        {@label || "#{@value}%"}
      </div>
    </div>
    """
  end

  @doc """
  A function component that displays a ring progress bar.

  Usage:
      <.ring_progress id="example" value={50} />

  Attributes:
    - id: unique identifier (required)
    - value: current progress value (required)
    - max: maximum progress value (default is 100)
    - size: size of the SVG (width and height, default is 120)
    - thickness: width of the circle stroke (default is 10)
    - progress_color: stroke color for the progress circle (default is "#00aaff")
  """
  @doc type: :component
  attr :id, :string,
    required: true,
    doc: "A unique identifier used to manage state and interaction."

  attr :color, :string, default: "natural", doc: "Determines color theme"

  attr :value, :integer,
    required: true,
    doc: "The current value representing the progress completion (e.g., between 0 and max)."

  attr :max, :integer,
    default: 100,
    doc: "The maximum value the progress can reach. Default is 100."

  attr :size, :integer,
    default: 120,
    doc: "The overall size of the progress element, typically in pixels. Default is 120."

  attr :thickness, :integer,
    default: 10,
    doc: "The thickness of the progress stroke in pixels. Default is 10."

  attr :label, :string,
    default: nil,
    doc: "Optional label to be displayed along with the progress element."

  attr :class, :string,
    default: nil,
    doc: "Custom CSS class for additional styling."

  attr :linecap, :string,
    default: nil,
    doc: "Controls the shape of the stroke ends. Use 'round' for rounded corners."

  attr :rest, :global,
    doc:
      "Global attributes can define defaults which are merged with attributes provided by the caller"

  def ring_progress(assigns) do
    radius = (assigns.size - assigns.thickness) / 2
    circumference = 2 * :math.pi() * radius
    progress_fraction = (assigns.max > 0 && assigns.value / assigns.max) || 0
    dash_offset = circumference * (1 - progress_fraction)

    assigns =
      assigns
      |> assign(:radius, radius)
      |> assign(:circumference, circumference)
      |> assign(:dash_offset, dash_offset)

    ~H"""
    <div
      id={@id}
      role="progressbar"
      aria-valuenow={@value}
      class={["circular-progress", color_variant(nil, @color), @class]}
      {@rest}
    >
      <svg width={@size} height={@size} viewBox={"0 0 #{@size} #{@size}"}>
        <circle
          cx={@size / 2}
          cy={@size / 2}
          r={@radius}
          class="semi-circle-progress-base stroke-default-light-gray dark:stroke-default-gray"
          stroke-width={@thickness}
          fill="none"
        />
        <circle
          cx={@size / 2}
          cy={@size / 2}
          r={@radius}
          stroke-width={@thickness}
          class="semi-circle-progress-bar"
          fill="none"
          stroke-linecap={@linecap}
          stroke-dasharray={@circumference}
          stroke-dashoffset={@dash_offset}
          transform={"rotate(-90, #{@size / 2}, #{@size / 2})"}
        />
        <text
          x="50%"
          y="50%"
          dominant-baseline="central"
          text-anchor="middle"
          class="ring-progress-text font-semibold fill-current"
        >
          {@label || "#{@value}%"}
        </text>
      </svg>
    </div>
    """
  end

  @doc """
  Renders a section of a progress bar component (`progress_section`).

  Each section represents a part of the progress with its own value and color, allowing for
  segmented progress bars.

  ## Examples

  ```elixir
  <.progress>
    <.progress_section color="primary" value={10} />
    <.progress_section color="secondary" value={15} />
    <.progress_section color="misc" value={10} />
    <.progress_section color="danger" value={5} />
    <.progress_section color="warning" value={10} />
    <.progress_section color="success" value={10} />
    <.progress_section color="info" value={5} />
  </.progress>
  ```
  """
  @doc type: :component
  attr :value, :integer, default: 0, doc: "Progress value (0 to 100)"
  attr :class, :string, default: nil, doc: "Custom CSS class for additional styling"

  attr :variation, :string,
    values: ["horizontal", "vertical"],
    default: "horizontal",
    doc: "Defines the layout orientation of the component"

  attr :color, :string, default: "natural", doc: "Determines color theme"
  attr :variant, :string, default: "base", doc: "Determines the style"
  attr :csp_nonce, :string, default: nil, doc: "csp nonce"

  attr :rest, :global,
    doc:
      "Global attributes can define defaults which are merged with attributes provided by the caller"

  slot :label, required: false do
    attr :class, :string, doc: "Custom CSS class for additional styling"
  end

  slot :tooltip, required: false do
    attr :label, :string, doc: "Determines element's text"
    attr :position, :string, doc: "Determines element's position"
    attr :clickable, :boolean, doc: "Determines element's click"
    attr :class, :string, doc: "Custom CSS class for additional styling"
  end

  def progress_section(assigns) do
    assigns =
      assigns
      |> assign_new(:tooltip, fn -> [] end)
      |> assign(:value, (is_integer(assigns.value) && assigns.value) || 0)
      |> assign_new(:id, fn -> random_id() end)

    ~H"""
    <.progress_section_with_tooltip :if={is_list(@tooltip) and @tooltip != []} {assigns} />
    <.progress_section_simple :if={@tooltip == [] or @tooltip == nil} {assigns} />
    """
  end

  defp progress_section_with_tooltip(assigns) do
    ~H"""
    <style :if={@csp_nonce} nonce={@csp_nonce}>
      #<%= @id %> {
        <%= if @variation == "horizontal" do %>
          width: <%= @value %>%;
        <% else %>
          height: <%= @value %>%;
        <% end %>
      }
    </style>

    <div
      phx-mounted={
        is_nil(@csp_nonce) &&
          JS.set_attribute({"style", dimension_style(@variation, @value)})
      }
      id={@id}
      role="presentation"
      aria-hidden="true"
      class={[
        "progress-section cursor-pointer",
        @variation == "vertical" && "progress-vertical",
        @variation == "horizontal" && "flex justify-center items-center",
        color_variant(@variant, @color),
        @class
      ]}
      {@rest}
    >
      <div
        :for={tooltip <- @tooltip}
        id={"tooltip-wrapper-#{@id}"}
        phx-hook="Floating"
        data-floating-type="tooltip"
        data-position={Map.get(tooltip, :position, "top")}
        data-smart-position="false"
        data-clickable={to_string(tooltip[:clickable])}
        aria-describedby={"#{@id}-tooltip"}
        class={[
          "w-full h-full",
          tooltip[:class]
        ]}
      >
        <div
          data-floating-trigger="true"
          aria-describedby={"#{@id}-tooltip"}
          class={[
            "w-full h-full flex items-center justify-center",
            @variation == "vertical" && "w-full"
          ]}
        >
          {tooltip[:label]}
        </div>

        <div
          id={"#{@id}-tooltip"}
          role="tooltip"
          data-floating-content="true"
          aria-hidden="false"
          role="tooltip"
          tabindex="0"
          aria-live="polite"
          hidden
          id={"#{@id}-tooltip"}
          class={[
            "absolute z-50 transition-all ease-in-out delay-100 duration-200 w-fit max-w-52",
            "progress-tooltip p-1 text-center bg-natural-light text-white dark:bg-natural-disabled-light dark:text-black rounded",
            tooltip[:class]
          ]}
        >
          <span class={[
            "block absolute size-[8px] bg-inherit rotate-45 -z-[1] tooltip-arrow",
            position_class(tooltip[:position])
          ]}>
          </span>
          {render_slot(tooltip)}
        </div>
      </div>
    </div>
    """
  end

  defp progress_section_simple(assigns) do
    ~H"""
    <style :if={@csp_nonce} nonce={@csp_nonce}>
      #<%= @id %> {
        <%= if @variation == "horizontal" do %>
          width: <%= @value %>%;
        <% else %>
          height: <%= @value %>%;
        <% end %>
      }
    </style>

    <div
      phx-mounted={
        is_nil(@csp_nonce) &&
          JS.set_attribute({"style", dimension_style(@variation, @value)})
      }
      id={@id}
      role="presentation"
      aria-hidden="true"
      class={[
        "w-full progress-section",
        if(@variation == "vertical", do: "progress-vertical"),
        if(@variation == "horizontal" && !is_nil(@label),
          do: "flex justify-center items-center [&_span]:text-[11px]"
        ),
        color_variant(@variant, @color),
        @class
      ]}
      {@rest}
    >
      <span :for={label <- @label} class={label[:class]} aria-hidden="false">
        {render_slot(label)}
      </span>
    </div>
    """
  end

  defp dimension_style("horizontal", value), do: "width: #{value}%;"
  defp dimension_style("vertical", value), do: "height: #{value}%;"

  defp position_class("top") do
    [
      "-bottom-[3px] -translate-x-1/2 left-1/2"
    ]
  end

  defp position_class("bottom") do
    [
      "-top-[3px] -translate-x-1/2 left-1/2"
    ]
  end

  defp position_class("left") do
    [
      "-right-[3px] -translate-y-1/2 top-1/2"
    ]
  end

  defp position_class("right") do
    [
      "-left-[3px] -translate-y-1/2 top-1/2"
    ]
  end

  defp position_class(_), do: position_class("top")

  defp rounded_size("extra_small") do
    "rounded-sm [&:not(.vertical-progress)_.progress-section:last-of-type]:rounded-e-sm"
  end

  defp rounded_size("small") do
    "rounded [&:not(.vertical-progress)_.progress-section:last-of-type]:rounded-e"
  end

  defp rounded_size("medium") do
    "rounded-md [&:not(.vertical-progress)_.progress-section:last-of-type]:rounded-e-md"
  end

  defp rounded_size("large") do
    "rounded-lg [&:not(.vertical-progress)_.progress-section:last-of-type]:rounded-e-lg"
  end

  defp rounded_size("extra_large") do
    "rounded-xl [&:not(.vertical-progress)_.progress-section:last-of-type]:rounded-e-xl"
  end

  defp rounded_size("full") do
    "rounded-full [&:not(.vertical-progress)_.progress-section:last-of-type]:rounded-e-full"
  end

  defp rounded_size(params) when is_binary(params), do: params

  defp size_class("extra_small", "horizontal"), do: "text-xs h-1.5 [&>*]:h-1.5"

  defp size_class("small", "horizontal"), do: "text-sm h-2 [&>*]:h-2"

  defp size_class("medium", "horizontal"), do: "text-base h-3 [&>*]:h-3"

  defp size_class("large", "horizontal"), do: "text-lg h-4 [&>*]:h-4"

  defp size_class("extra_large", "horizontal"), do: "text-xl h-5 [&>*]:h-5"

  defp size_class("double_large", "horizontal"), do: "text-xl h-6 [&>*]:h-6"

  defp size_class("triple_large", "horizontal"), do: "text-xl h-7 [&>*]:h-7"

  defp size_class("quadruple_large", "horizontal"), do: "text-xl h-8 [&>*]:h-8"

  defp size_class("extra_small", "vertical"), do: "text-xs w-1 h-[5rem]"

  defp size_class("small", "vertical"), do: "text-sm w-2 h-[6rem]"

  defp size_class("medium", "vertical"), do: "text-base w-3 h-[7rem]"

  defp size_class("large", "vertical"), do: "text-lg w-4 h-[8rem]"

  defp size_class("extra_large", "vertical"), do: "text-xl w-5 h-[9rem]"

  defp size_class("double_large", "vertical"), do: "text-xl w-6 h-[10rem]"

  defp size_class("triple_large", "vertical"), do: "text-xl w-7 h-[11rem]"

  defp size_class("quadruple_large", "vertical"), do: "text-xl w-8 h-[12rem]"

  defp size_class(params, _) when is_binary(params), do: params

  defp color_variant("base", _) do
    [
      "text-base-text-light bg-base-border-light dark:text-base-text-dark dark:bg-base-border-dark"
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

  defp color_variant("gradient", "natural") do
    [
      "[&:not(.progress-vertical)]:bg-gradient-to-r rtl:[&:not(.progress-vertical)]:bg-gradient-to-l",
      "[&:not(.progress-vertical)]:from-gradient-natural-from-light [&:not(.progress-vertical)]:via-gradient-natural-to-light [&:not(.progress-vertical)]:to-progress-bg text-white",
      "[&.progress-vertical]:bg-gradient-to-b [&.progress-vertical]:from-progress-bg [&.progress-vertical]:to-gradient-natural-to-light [&.progress-vertical]:via-gradient-natural-to-light",
      "dark:[&:not(.progress-vertical)]:from-gradient-natural-from-dark dark:[&:not(.progress-vertical)]:via-white dark:[&:not(.progress-vertical)]:to-progress-bg text-black",
      "dark:[&.progress-vertical]:to-gradient-natural-from-dark dark:[&.progress-vertical]:via-gradient-natural-from-dark dark:[&.progress-vertical]:from-progress-bg"
    ]
  end

  defp color_variant("gradient", "primary") do
    [
      "[&:not(.progress-vertical)]:bg-gradient-to-r rtl:[&:not(.progress-vertical)]:bg-gradient-to-l",
      "[&:not(.progress-vertical)]:from-gradient-primary-from-light [&:not(.progress-vertical)]:via-gradient-primary-to-light [&:not(.progress-vertical)]:to-progress-bg text-white",
      "[&.progress-vertical]:bg-gradient-to-b [&.progress-vertical]:from-progress-bg [&.progress-vertical]:to-gradient-primary-to-light [&.progress-vertical]:via-gradient-primary-to-light",
      "dark:[&:not(.progress-vertical)]:from-gradient-primary-from-dark dark:[&:not(.progress-vertical)]:via-gradient-primary-to-dark dark:[&:not(.progress-vertical)]:to-progress-bg text-black",
      "dark:[&.progress-vertical]:to-gradient-primary-to-dark dark:[&.progress-vertical]:via-gradient-primary-to-dark dark:[&.progress-vertical]:from-progress-bg"
    ]
  end

  defp color_variant("gradient", "secondary") do
    [
      "[&:not(.progress-vertical)]:bg-gradient-to-r rtl:[&:not(.progress-vertical)]:bg-gradient-to-l",
      "[&:not(.progress-vertical)]:from-gradient-secondary-from-light [&:not(.progress-vertical)]:via-gradient-secondary-to-light [&:not(.progress-vertical)]:to-progress-bg text-white",
      "[&.progress-vertical]:bg-gradient-to-b [&.progress-vertical]:from-progress-bg [&.progress-vertical]:to-gradient-secondary-to-light [&.progress-vertical]:via-gradient-secondary-to-light",
      "dark:[&:not(.progress-vertical)]:from-gradient-secondary-from-dark dark:[&:not(.progress-vertical)]:via-gradient-secondary-to-dark dark:[&:not(.progress-vertical)]:to-progress-bg text-black",
      "dark:[&.progress-vertical]:to-gradient-secondary-to-dark dark:[&.progress-vertical]:via-gradient-secondary-to-dark dark:[&.progress-vertical]:from-progress-bg"
    ]
  end

  defp color_variant("gradient", "success") do
    [
      "[&:not(.progress-vertical)]:bg-gradient-to-r rtl:[&:not(.progress-vertical)]:bg-gradient-to-l",
      "[&:not(.progress-vertical)]:from-gradient-success-from-light [&:not(.progress-vertical)]:via-gradient-success-to-light [&:not(.progress-vertical)]:to-progress-bg text-white",
      "[&.progress-vertical]:bg-gradient-to-b [&.progress-vertical]:from-progress-bg [&.progress-vertical]:to-gradient-success-to-light [&.progress-vertical]:via-gradient-success-to-light",
      "dark:[&:not(.progress-vertical)]:from-gradient-success-from-dark dark:[&:not(.progress-vertical)]:via-gradient-success-to-dark dark:[&:not(.progress-vertical)]:to-progress-bg text-black",
      "dark:[&.progress-vertical]:to-gradient-success-to-dark dark:[&.progress-vertical]:via-gradient-success-to-dark dark:[&.progress-vertical]:from-progress-bg"
    ]
  end

  defp color_variant("gradient", "warning") do
    [
      "[&:not(.progress-vertical)]:bg-gradient-to-r rtl:[&:not(.progress-vertical)]:bg-gradient-to-l",
      "[&:not(.progress-vertical)]:from-gradient-warning-from-light [&:not(.progress-vertical)]:via-gradient-warning-to-light [&:not(.progress-vertical)]:to-progress-bg text-white",
      "[&.progress-vertical]:bg-gradient-to-b [&.progress-vertical]:from-progress-bg [&.progress-vertical]:to-gradient-warning-to-light [&.progress-vertical]:via-gradient-warning-from-light",
      "dark:[&:not(.progress-vertical)]:from-gradient-warning-from-dark dark:[&:not(.progress-vertical)]:via-gradient-warning-to-dark dark:[&:not(.progress-vertical)]:to-progress-bg text-black",
      "dark:[&.progress-vertical]:to-gradient-warning-to-dark dark:[&.progress-vertical]:via-gradient-warning-to-dark dark:[&.progress-vertical]:from-progress-bg"
    ]
  end

  defp color_variant("gradient", "danger") do
    [
      "[&:not(.progress-vertical)]:bg-gradient-to-r rtl:[&:not(.progress-vertical)]:bg-gradient-to-l",
      "[&:not(.progress-vertical)]:from-gradient-danger-from-light [&:not(.progress-vertical)]:via-gradient-danger-to-light [&:not(.progress-vertical)]:to-progress-bg text-white",
      "[&.progress-vertical]:bg-gradient-to-b [&.progress-vertical]:from-progress-bg [&.progress-vertical]:to-gradient-danger-to-light [&.progress-vertical]:via-gradient-danger-to-light",
      "dark:[&:not(.progress-vertical)]:from-gradient-danger-from-dark dark:[&:not(.progress-vertical)]:via-gradient-danger-to-dark dark:[&:not(.progress-vertical)]:to-progress-bg text-black",
      "dark:[&.progress-vertical]:to-gradient-danger-to-dark dark:[&.progress-vertical]:via-gradient-danger-to-dark dark:[&.progress-vertical]:from-progress-bg"
    ]
  end

  defp color_variant("gradient", "info") do
    [
      "[&:not(.progress-vertical)]:bg-gradient-to-r rtl:[&:not(.progress-vertical)]:bg-gradient-to-l",
      "[&:not(.progress-vertical)]:from-gradient-info-from-light [&:not(.progress-vertical)]:via-gradient-info-to-light [&:not(.progress-vertical)]:to-progress-bg text-white",
      "[&.progress-vertical]:bg-gradient-to-b [&.progress-vertical]:from-progress-bg [&.progress-vertical]:to-gradient-info-to-light [&.progress-vertical]:via-gradient-info-to-light",
      "dark:[&:not(.progress-vertical)]:from-gradient-info-from-dark dark:[&:not(.progress-vertical)]:via-gradient-info-to-dark dark:[&:not(.progress-vertical)]:to-progress-bg text-black",
      "dark:[&.progress-vertical]:to-gradient-info-to-dark dark:[&.progress-vertical]:via-gradient-info-to-dark dark:[&.progress-vertical]:from-progress-bg"
    ]
  end

  defp color_variant("gradient", "misc") do
    [
      "[&:not(.progress-vertical)]:bg-gradient-to-r rtl:[&:not(.progress-vertical)]:bg-gradient-to-l",
      "[&:not(.progress-vertical)]:from-gradient-misc-from-light [&:not(.progress-vertical)]:via-gradient-misc-to-light [&:not(.progress-vertical)]:to-progress-bg text-white",
      "[&.progress-vertical]:bg-gradient-to-b [&.progress-vertical]:from-progress-bg [&.progress-vertical]:to-gradient-misc-to-light [&.progress-vertical]:via-gradient-misc-to-light",
      "dark:[&:not(.progress-vertical)]:from-gradient-misc-from-dark dark:[&:not(.progress-vertical)]:via-gradient-misc-to-dark dark:[&:not(.progress-vertical)]:to-progress-bg text-black",
      "dark:[&.progress-vertical]:to-gradient-misc-to-dark dark:[&.progress-vertical]:via-gradient-misc-to-dark dark:[&.progress-vertical]:from-progress-bg"
    ]
  end

  defp color_variant("gradient", "dawn") do
    [
      "[&:not(.progress-vertical)]:bg-gradient-to-r rtl:[&:not(.progress-vertical)]:bg-gradient-to-l",
      "[&:not(.progress-vertical)]:from-gradient-dawn-from-light [&:not(.progress-vertical)]:via-gradient-dawn-to-light [&:not(.progress-vertical)]:to-progress-bg text-white",
      "[&.progress-vertical]:bg-gradient-to-b [&.progress-vertical]:from-progress-bg [&.progress-vertical]:to-gradient-dawn-to-light [&.progress-vertical]:via-gradient-dawn-to-light",
      "dark:[&:not(.progress-vertical)]:from-gradient-dawn-from-dark dark:[&:not(.progress-vertical)]:via-gradient-dawn-to-dark dark:[&:not(.progress-vertical)]:to-progress-bg text-black",
      "dark:[&.progress-vertical]:to-gradient-dawn-to-dark dark:[&.progress-vertical]:via-gradient-dawn-to-dark dark:[&.progress-vertical]:from-progress-bg"
    ]
  end

  defp color_variant("gradient", "silver") do
    [
      "[&:not(.progress-vertical)]:bg-gradient-to-r rtl:[&:not(.progress-vertical)]:bg-gradient-to-l",
      "[&:not(.progress-vertical)]:from-gradient-silver-from-light [&:not(.progress-vertical)]:via-gradient-silver-to-light [&:not(.progress-vertical)]:to-progress-bg text-white",
      "[&.progress-vertical]:bg-gradient-to-b [&.progress-vertical]:from-progress-bg [&.progress-vertical]:to-gradient-silver-to-light [&.progress-vertical]:via-gradient-silver-from-light",
      "dark:[&:not(.progress-vertical)]:from-gradient-silver-from-dark dark:[&:not(.progress-vertical)]:via-gradient-silver-to-dark dark:[&:not(.progress-vertical)]:to-progress-bg text-black",
      "dark:[&.progress-vertical]:to-gradient-silver-to-dark dark:[&.progress-vertical]:via-gradient-silver-to-dark dark:[&.progress-vertical]:from-progress-bg"
    ]
  end

  defp color_variant(nil, "natural") do
    [
      "[&_.semi-circle-progress-bar]:stroke-natural-light dark:[&_.semi-circle-progress-bar]:stroke-natural-dark"
    ]
  end

  defp color_variant(nil, "primary") do
    [
      "[&_.semi-circle-progress-bar]:stroke-primary-light dark:[&_.semi-circle-progress-bar]:stroke-primary-dark"
    ]
  end

  defp color_variant(nil, "secondary") do
    [
      "[&_.semi-circle-progress-bar]:stroke-secondary-light dark:[&_.semi-circle-progress-bar]:stroke-secondary-dark"
    ]
  end

  defp color_variant(nil, "success") do
    [
      "[&_.semi-circle-progress-bar]:stroke-success-light dark:[&_.semi-circle-progress-bar]:stroke-success-dark"
    ]
  end

  defp color_variant(nil, "warning") do
    [
      "[&_.semi-circle-progress-bar]:stroke-warning-light dark:[&_.semi-circle-progress-bar]:stroke-warning-dark"
    ]
  end

  defp color_variant(nil, "danger") do
    [
      "[&_.semi-circle-progress-bar]:stroke-danger-light dark:[&_.semi-circle-progress-bar]:stroke-danger-dark"
    ]
  end

  defp color_variant(nil, "info") do
    [
      "[&_.semi-circle-progress-bar]:stroke-info-light dark:[&_.semi-circle-progress-bar]:stroke-info-dark"
    ]
  end

  defp color_variant(nil, "misc") do
    [
      "[&_.semi-circle-progress-bar]:stroke-misc-light dark:[&_.semi-circle-progress-bar]:stroke-misc-dark"
    ]
  end

  defp color_variant(nil, "dawn") do
    [
      "[&_.semi-circle-progress-bar]:stroke-dawn-light dark:[&_.semi-circle-progress-bar]:stroke-dawn-dark"
    ]
  end

  defp color_variant(nil, "silver") do
    [
      "[&_.semi-circle-progress-bar]:stroke-silver-light dark:[&_.semi-circle-progress-bar]:stroke-silver-dark"
    ]
  end

  defp color_variant(params, _) when is_binary(params), do: params

  defp progress_rotation_class("down", "right-to-left"), do: "rotate-180 scale-x-[-1]"
  defp progress_rotation_class("down", _), do: "rotate-180"
  defp progress_rotation_class("up", "left-to-right"), do: "scale-x-[-1]"
  defp progress_rotation_class(_, _), do: ""

  defp clamp(val, min, max), do: max(min, min(val, max))
end
