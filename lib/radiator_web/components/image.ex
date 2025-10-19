defmodule RadiatorWeb.Components.Image do
  @moduledoc """
  The `RadiatorWeb.Components.Image` module provides a component for rendering images in a Phoenix application.
  It supports various attributes to control the display, loading behavior, and styling of the image.

  This module simplifies the use of images with various configurations and styling
  options in a Phoenix application.

  **Documentation:** https://mishka.tools/chelekom/docs/image
  """

  use Phoenix.Component

  @doc """
  Renders an `image` component with various customization options such as border `radius`, `shadow`,
  and `loading` behavior.

  It supports additional attributes like width, height, and srcset for responsive images.

  ## Examples

  ```elixir
  <.image src="https://example.com/1.jpg" />
  <.image src="https://example.com/1.jpg" loading="lazy"/>
  <.image shadow="large" src="https://example.com/1.jpg" width={100} height={100}/>
  <.image rounded="full" src="https://example.com/1.jpg" width={100} height={100}/>
  <.image fetchpriority="low" rounded="rounded-3xl" shadow="extra_large" src="https://example.com/1.jpg"/>
  ```
  """
  @doc type: :component
  attr :id, :string,
    default: nil,
    doc: "A unique identifier is used to manage state and interaction"

  attr :src, :string, required: true, doc: "Media link"
  attr :alt, :string, default: nil, doc: "Media link description"
  attr :srcset, :string, default: nil, doc: "Allows you to specify a list of different images"

  attr :loading, :any,
    values: ["eager", "lazy", nil],
    default: nil,
    doc: "eager: is default, lazy"

  attr :referrerpolicy, :string, default: nil, doc: ""

  attr :fetchpriority, :any,
    values: ["high", "low", "auto", nil],
    default: nil,
    doc: "high, low, auto is default"

  attr :width, :integer, default: nil, doc: "Determines width style"
  attr :height, :integer, default: nil, doc: "Determines height style"

  attr :sizes, :string,
    default: nil,
    doc:
      "Specifies the intended display size of the image in the layout for different viewport conditions"

  attr :ismap, :string, default: nil, doc: "Make the image act as a server-side image map"

  attr :filter, :string, default: "", doc: "Utilities for applying filters"
  attr :filter_size, :string, default: "", doc: "Utilities for applying filters sizes"

  attr :decoding, :string,
    default: nil,
    doc:
      "Refers to the process of converting encoded or encrypted data back into its original format"

  attr :rounded, :string, default: "", doc: "Determines the border radius"
  attr :shadow, :string, default: "", doc: "Determines shadow style"
  attr :class, :any, default: nil, doc: "Custom CSS class for additional styling"

  attr :rest, :global,
    doc:
      "Global attributes can define defaults which are merged with attributes provided by the caller"

  def image(assigns) do
    ~H"""
    <img
      id={@id}
      src={@src}
      alt={@alt}
      width={@width}
      height={@height}
      srcset={@srcset}
      sizes={@sizes}
      loading={@loading}
      ismap={@ismap}
      decoding={@decoding}
      fetchpriority={@fetchpriority}
      referrerpolicy={@referrerpolicy}
      class={[
        "max-w-full",
        rounded_size(@rounded),
        shadow_size(@shadow),
        filter_class(@filter, @filter_size),
        @class
      ]}
      {@rest}
    />
    """
  end

  defp rounded_size("extra_small"), do: "rounded-sm"

  defp rounded_size("small"), do: "rounded"

  defp rounded_size("medium"), do: "rounded-md"

  defp rounded_size("large"), do: "rounded-lg"

  defp rounded_size("extra_large"), do: "rounded-xl"

  defp rounded_size("full"), do: "rounded-full"

  defp rounded_size(params) when is_binary(params), do: params

  defp shadow_size("extra_small"), do: "shadow-sm"
  defp shadow_size("small"), do: "shadow"
  defp shadow_size("medium"), do: "shadow-md"
  defp shadow_size("large"), do: "shadow-lg"
  defp shadow_size("extra_large"), do: "shadow-xl"
  defp shadow_size(params) when is_binary(params), do: params

  defp filter_class("blur", "extra_small"), do: "blur-sm"
  defp filter_class("blur", "small"), do: "blur"
  defp filter_class("blur", "medium"), do: "blur-md"
  defp filter_class("blur", "large"), do: "blur-lg"
  defp filter_class("blur", "extra_large"), do: "blur-xl"

  defp filter_class("brightness", "extra_small"), do: "brightness-50"
  defp filter_class("brightness", "small"), do: "brightness-75"
  defp filter_class("brightness", "medium"), do: "brightness-90"
  defp filter_class("brightness", "large"), do: "brightness-95"
  defp filter_class("brightness", "extra_large"), do: "brightness-100"

  defp filter_class("contrast", "extra_small"), do: "contrast-50"
  defp filter_class("contrast", "small"), do: "contrast-75"
  defp filter_class("contrast", "medium"), do: "contrast-100"
  defp filter_class("contrast", "large"), do: "contrast-125"
  defp filter_class("contrast", "extra_large"), do: "contrast-150"

  defp filter_class("hue", "extra_small"), do: "hue-rotate-15"
  defp filter_class("hue", "small"), do: "hue-rotate-30"
  defp filter_class("hue", "medium"), do: "hue-rotate-60"
  defp filter_class("hue", "large"), do: "hue-rotate-90"
  defp filter_class("hue", "extra_large"), do: "hue-rotate-180"

  defp filter_class("saturation", "extra_small"), do: "saturate-50"
  defp filter_class("saturation", "small"), do: "saturate-[0.75]"
  defp filter_class("saturation", "medium"), do: "saturate-100"
  defp filter_class("saturation", "large"), do: "saturate-150"
  defp filter_class("saturation", "extra_large"), do: "saturate-200"

  defp filter_class("grayscale", _), do: "grayscale"
  defp filter_class("invert", _), do: "invert"
  defp filter_class("sepia", _), do: "sepia"

  defp filter_class(params, _) when is_binary(params), do: params
end
