defmodule RadiatorWeb.Components.Spinner do
  @moduledoc """
  The `RadiatorWeb.Components.Spinner` module provides a dynamic and customizable loading spinner
  component for Phoenix LiveView applications. It supports various animation styles and
  configurations to visually indicate ongoing processes or loading states within an application.

  This module includes several types of spinners, offering a range of visual effects, such as
  traditional spinning animations, bouncing dots, bars, and more intricate radial patterns.
  It also allows extensive customization, including color themes and size variations,
  making it adaptable to different UI designs and user interfaces.

  With its flexible design, the `RadiatorWeb.Components.Spinner` module enables developers to provide
  visual feedback for asynchronous operations, enhancing user experience and maintaining engagement
  during content loading or background processes.

  **Documentation:** https://mishka.tools/chelekom/docs/spinner
  """

  use Phoenix.Component
  use Gettext, backend: RadiatorWeb.Gettext

  @spinner_types [
    "default",
    "dots",
    "bars",
    "pinging"
  ]

  @doc """
  Renders a customizable `spinner` component to indicate loading or processing states.
  The spinner can be adjusted in size, color, and type to match the desired style and theme.

  ## Examples

  ```elixir
  <.spinner color="danger" size="extra_small" type="pinging" />
  <.spinner color="misc" type="pinging" />
  <.spinner color="warning" size="medium" type="pinging" />
  <.spinner color="success" size="large" type="pinging" />
  <.spinner color="primary" size="extra_large" type="pinging" />
  ```
  """
  @doc type: :component
  attr :id, :string,
    default: nil,
    doc: "A unique identifier is used to manage state and interaction"

  attr :type, :string,
    values: @spinner_types,
    default: "default",
    doc: "Determines the spinner animation type (default, dots, bars, pinging)"

  attr :class, :string, default: nil, doc: "Custom CSS class for additional styling"
  attr :color, :string, default: "base", doc: "Determines color theme"

  attr :size, :string,
    default: "small",
    doc:
      "Determines the overall size of the elements, including padding, font size, and other items"

  attr :rest, :global,
    doc:
      "Global attributes can define defaults which are merged with attributes provided by the caller"

  def spinner(assigns) do
    ~H"""
    <span
      id={@id}
      class={[
        default_class(@type),
        size_class(@type, @size),
        color_class(@color),
        @class
      ]}
      role="status"
      {@rest}
    >
      <.spinner_content type={@type} />
    </span>
    """
  end

  @doc type: :component
  attr :type, :string, values: @spinner_types

  defp spinner_content(%{type: "pinging"} = assigns) do
    ~H"""
    <span class="sr-only">{gettext("Loading...")}</span>
    <svg viewBox="0 0 45 45" xmlns="http://www.w3.org/2000/svg">
      <g fill="none" fill-rule="evenodd" transform="translate(1 1)" stroke-width="2">
        <circle cx="22" cy="22" r="6" stroke-opacity="0">
          <animate
            attributeName="r"
            begin="1.5s"
            dur="3s"
            values="6;22"
            calcMode="linear"
            repeatCount="indefinite"
          >
          </animate>
          <animate
            attributeName="stroke-opacity"
            begin="1.5s"
            dur="3s"
            values="1;0"
            calcMode="linear"
            repeatCount="indefinite"
          >
          </animate>
          <animate
            attributeName="stroke-width"
            begin="1.5s"
            dur="3s"
            values="2;0"
            calcMode="linear"
            repeatCount="indefinite"
          >
          </animate>
        </circle>
        <circle cx="22" cy="22" r="6" stroke-opacity="0">
          <animate
            attributeName="r"
            begin="3s"
            dur="3s"
            values="6;22"
            calcMode="linear"
            repeatCount="indefinite"
          >
          </animate>
          <animate
            attributeName="stroke-opacity"
            begin="3s"
            dur="3s"
            values="1;0"
            calcMode="linear"
            repeatCount="indefinite"
          >
          </animate>
          <animate
            attributeName="stroke-width"
            begin="3s"
            dur="3s"
            values="2;0"
            calcMode="linear"
            repeatCount="indefinite"
          >
          </animate>
        </circle>
        <circle cx="22" cy="22" r="8">
          <animate
            attributeName="r"
            begin="0s"
            dur="1.5s"
            values="6;1;2;3;4;5;6"
            calcMode="linear"
            repeatCount="indefinite"
          >
          </animate>
        </circle>
      </g>
    </svg>
    """
  end

  defp spinner_content(%{type: "dots"} = assigns) do
    ~H"""
    <span class="sr-only">{gettext("Loading...")}</span>
    <span class="block rounded-full animate-bounce"></span>
    <span class="block rounded-full animate-bounce [animation-delay:-0.2s]"></span>
    <span class="block rounded-full animate-bounce [animation-delay:-0.4s]"></span>
    """
  end

  defp spinner_content(%{type: "bars"} = assigns) do
    ~H"""
    <span class="sr-only">{gettext("Loading...")}</span>
    <span class="block rounded-sm animate-bounce [animation-delay:-0.4s]"></span>
    <span class="block rounded-sm animate-bounce [animation-delay:-0.2s]"></span>
    <span class="block rounded-sm animate-bounce"></span>
    """
  end

  defp spinner_content(assigns) do
    ~H"""
    <span class="sr-only">{gettext("Loading...")}</span>
    """
  end

  defp default_class("dots") do
    "w-fit flex space-x-2 justify-center items-center"
  end

  defp default_class("bars") do
    "w-fit flex gap-2"
  end

  defp default_class("pinging"), do: "block"

  defp default_class(_) do
    "animate-spin border-t-transparent rounded-full border-current block"
  end

  defp size_class("dots", "extra_small"), do: "[&>span]:size-1"

  defp size_class("dots", "small"), do: "[&>span]:size-1.5"

  defp size_class("dots", "medium"), do: "[&>span]:size-2"

  defp size_class("dots", "large"), do: "[&>span]:size-2.5"

  defp size_class("dots", "extra_large"), do: "[&>span]:size-3"

  defp size_class("dots", "double_large"), do: "[&>span]:size-3.5"

  defp size_class("dots", "triple_large"), do: "[&>span]:size-4"

  defp size_class("dots", "quadruple_large"), do: "[&>span]:size-5"

  defp size_class("bars", "extra_small"), do: "[&>span]:w-1 [&>span]:h-5"

  defp size_class("bars", "small"), do: "[&>span]:w-1 [&>span]:h-6"

  defp size_class("bars", "medium"), do: "[&>span]:w-1.5 [&>span]:h-7"

  defp size_class("bars", "large"), do: "[&>span]:w-1.5 [&>span]:h-8"

  defp size_class("bars", "extra_large"), do: "[&>span]:w-2 [&>span]:h-9"

  defp size_class("bars", "double_large"), do: "[&>span]:w-2 [&>span]:h-10"

  defp size_class("bars", "triple_large"), do: "[&>span]:w-2.5 [&>span]:h-11"

  defp size_class("bars", "quadruple_large"), do: "[&>span]:w-2.5 [&>span]:h-12"

  defp size_class("pinging", "extra_small"), do: "[&>svg]:size-6"

  defp size_class("pinging", "small"), do: "[&>svg]:size-7"

  defp size_class("pinging", "medium"), do: "[&>svg]:size-8"

  defp size_class("pinging", "large"), do: "[&>svg]:size-9"

  defp size_class("pinging", "extra_large"), do: "[&>svg]:size-10"

  defp size_class("pinging", "double_large"), do: "[&>svg]:size-12"

  defp size_class("pinging", "triple_large"), do: "[&>svg]:size-14"

  defp size_class("pinging", "quadruple_large"), do: "[&>svg]:size-16"

  defp size_class("default", "extra_small"), do: "size-3.5 border-2"

  defp size_class("default", "small"), do: "size-4 border-[3px]"

  defp size_class("default", "medium"), do: "size-5 border-4"

  defp size_class("default", "large"), do: "size-6 border-[5px]"

  defp size_class("default", "extra_large"), do: "size-7 border-[5px]"

  defp size_class("default", "double_large"), do: "size-8 border-[5px]"

  defp size_class("default", "triple_large"), do: "size-9 border-[6px]"

  defp size_class("default", "quadruple_large"), do: "size-10 border-[6px]"

  defp size_class(_, params) when is_binary(params), do: params

  defp color_class("base") do
    [
      "[&>span]:bg-base-border-light [&>svg]:stroke-base-border-light text-base-border-light",
      "dark:[&>span]:bg-base-border-dark dark:[&>svg]:stroke-base-border-dark dark:text-base-border-dark"
    ]
  end

  defp color_class("white") do
    ["[&>span]:bg-white [&>svg]:stroke-white text-white"]
  end

  defp color_class("dark") do
    ["[&>span]:bg-default-dark-bg [&>svg]:stroke-default-dark-bg text-default-dark-bg"]
  end

  defp color_class("natural") do
    [
      "[&>span]:bg-natural-light [&>svg]:stroke-natural-light text-natural-light",
      "dark:[&>span]:bg-natural-dark dark:[&>svg]:stroke-natural-dark dark:text-natural-dark"
    ]
  end

  defp color_class("primary") do
    [
      "[&>span]:bg-primary-light [&>svg]:stroke-primary-light text-primary-light",
      "dark:[&>span]:bg-primary-dark dark:[&>svg]:stroke-primary-dark dark:text-primary-dark"
    ]
  end

  defp color_class("secondary") do
    [
      "[&>span]:bg-secondary-light [&>svg]:stroke-secondary-light text-secondary-light",
      "dark:[&>span]:bg-secondary-dark dark:[&>svg]:stroke-secondary-dark dark:text-secondary-dark"
    ]
  end

  defp color_class("success") do
    [
      "[&>span]:bg-success-light [&>svg]:stroke-success-light text-success-light",
      "dark:[&>span]:bg-success-dark dark:[&>svg]:stroke-success-dark dark:text-success-dark"
    ]
  end

  defp color_class("warning") do
    [
      "[&>span]:bg-warning-light [&>svg]:stroke-warning-light text-warning-light",
      "dark:[&>span]:bg-warning-dark dark:[&>svg]:stroke-warning-dark dark:text-warning-dark"
    ]
  end

  defp color_class("danger") do
    [
      "[&>span]:bg-danger-light [&>svg]:stroke-danger-light text-danger-light",
      "dark:[&>span]:bg-danger-dark dark:[&>svg]:stroke-danger-dark dark:text-danger-dark"
    ]
  end

  defp color_class("info") do
    [
      "[&>span]:bg-info-light [&>svg]:stroke-info-light text-info-light",
      "dark:[&>span]:bg-info-dark dark:[&>svg]:stroke-info-dark dark:text-info-dark"
    ]
  end

  defp color_class("misc") do
    [
      "[&>span]:bg-misc-light [&>svg]:stroke-misc-light text-misc-light",
      "dark:[&>span]:bg-misc-dark dark:[&>svg]:stroke-misc-dark dark:text-misc-dark"
    ]
  end

  defp color_class("dawn") do
    [
      "[&>span]:bg-dawn-light [&>svg]:stroke-dawn-light text-dawn-light",
      "dark:[&>span]:bg-dawn-dark dark:[&>svg]:stroke-dawn-dark dark:text-dawn-dark"
    ]
  end

  defp color_class("silver") do
    [
      "[&>span]:bg-silver-light [&>svg]:stroke-silver-light text-silver-light",
      "dark:[&>span]:bg-silver-dark dark:[&>svg]:stroke-silver-dark dark:text-silver-dark"
    ]
  end

  defp color_class(params) when is_binary(params), do: params
end
