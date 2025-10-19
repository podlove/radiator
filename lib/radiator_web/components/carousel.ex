defmodule RadiatorWeb.Components.Carousel do
  @moduledoc """
  Provides a versatile and customizable carousel component for the `RadiatorWeb.Components.Carousel`
  project.

  This component enables the creation of image carousels with various features such as
  slide indicators, navigation controls, and dynamic slide content.

  ## Features

  - **Slides**: Define multiple slides, each with custom images, titles, descriptions, and links.
  - **Navigation Controls**: Include previous and next buttons to manually navigate through the slides.
  - **Indicators**: Optional indicators show the current slide and allow direct navigation to any slide.
  - **Overlay Options**: Customize the appearance of the overlay for a more distinct visual style.
  - **Responsive Design**: Supports various sizes and padding options to adapt to different screen sizes.
  - **Image Loading**: Shows loading state while images are being loaded.

  This module offers an easy-to-use interface for building carousels with consistent
  styling and behavior across your application, while providing the flexibility to
  meet various design requirements.

  **Documentation:** https://mishka.tools/chelekom/docs/carousel
  """

  use Phoenix.Component
  import RadiatorWeb.Components.Image, only: [image: 1]
  import Phoenix.LiveView.Utils, only: [random_id: 0]
  import RadiatorWeb.Components.Icon, only: [icon: 1]
  use Gettext, backend: RadiatorWeb.Gettext

  @doc """
  The `carousel` component is used to create interactive image carousels with customizable attributes
  such as `size`, `padding`, and `overlay`. It supports adding multiple slides with different content,
  and includes options for navigation controls and indicators.

  ## Examples

  ```elixir
  <.carousel id="carousel-test-one" indicator={true}>
    <:slide
      content_position="end"
      title="This is a dummy title 1"
      description="This is a description for our carousel and this is a dummy text"
      image="https://example.com/slides/1.webp"
      navigate="/examples/navbar"
    />
    <:slide
      content_position="center"
      title="This is a dummy title 2"
      image="https://example.com/slides/2.webp"
    />
    <:slide
      content_position="start"
      title="This is a dummy title 3"
      image="https://example.com/slides/3.webp"
    />
  </.carousel>
  ```
  """
  @doc type: :component
  attr :id, :string, doc: "A unique identifier is used to manage state and interaction"

  attr :class, :string, default: nil, doc: "Custom CSS class for additional styling"
  attr :overlay, :string, default: "base", doc: "Determines an overlay"

  attr :size, :string,
    default: "large",
    doc:
      "Determines the overall size of the elements, including padding, font size, and other items"

  attr :padding, :string, default: "medium", doc: "Determines padding for items"
  attr :text_position, :string, default: "center", doc: "Determines the element's text position"

  attr :rest, :global,
    doc:
      "Global attributes can define defaults which are merged with attributes provided by the caller"

  attr :indicator, :boolean, default: false, doc: "Specifies whether to show element indicators"
  attr :control, :boolean, default: true, doc: "Determines whether to show navigation controls"
  attr :active_index, :integer, default: 0, doc: "Index of the active slide (starts at 0)"
  attr :autoplay, :boolean, default: false, doc: "Enable or disable autoplay functionality"

  attr :autoplay_interval, :integer,
    default: 5000,
    doc: "Time between slides in ms (if autoplay is enabled)"

  attr :active_slide_class, :string,
    default: "active-slide z-10",
    doc: "CSS class for active slide"

  attr :hidden_slide_class, :string,
    default: "opacity-0",
    doc: "CSS class for hidden (inactive) slides"

  attr :active_indicator_class, :string,
    default: "active-indicator",
    doc: "CSS class for active indicator"

  slot :inner_block, required: false, doc: "Inner block that renders HEEx content"

  slot :slide, required: true do
    attr :image, :string, doc: "Image displayed alongside of an item"
    attr :image_class, :string, doc: "Determines custom class for the image"

    attr :navigate, :string,
      doc: "Defines the path for navigation within the application using a `navigate` attribute."

    attr :patch, :string, doc: "Specifies the path for navigation using a LiveView patch."
    attr :href, :string, doc: "Sets the URL for an external link."
    attr :title, :string, doc: "Specifies the title of the element"
    attr :description, :string, doc: "Determines a short description"
    attr :title_class, :string, doc: "Determines custom class for the title"
    attr :description_class, :string, doc: "Determines custom class for the description"
    attr :wrapper_class, :string, doc: "Determines custom class for the wrapper"
    attr :content_position, :string, doc: "Determines the alignment of the element's content"
    attr :class, :string, doc: "Custom CSS class for additional styling"
    attr :active, :boolean, doc: "Indicates whether the element is currently active and visible"
  end

  def carousel(assigns) do
    assigns =
      assigns
      |> assign_new(:id, fn -> "carousel-#{random_id()}" end)
      |> assign_new(:activated_carousel, fn ->
        Enum.find_index(assigns.slide, &(Map.get(&1, :active) == true)) || 0
      end)

    ~H"""
    <div
      id={@id}
      phx-hook="Carousel"
      phx-update="ignore"
      data-active-index={@active_index + 1}
      data-autoplay={to_string(@autoplay)}
      data-autoplay-interval={@autoplay_interval}
      data-active-slide-class={@active_slide_class}
      data-hidden-slide-class={@hidden_slide_class}
      data-active-indicator-class={@active_indicator_class}
      class={[
        "relative w-full overflow-hidden",
        "[&_.slide:not(.active-slide)]:absolute [&_.slide]:inset-0 [&_.slide]:opacity-0 [&_.slide.active-slide]:opacity-100 [&_.slide:not(.active-slide)]:pointer-events-none [&_.slide:not(.active-slide)]:z-0",
        "[&_.slide.active-slide]:z-10",
        "[&_.slide]:transition-opacity [&_.slide]:delay-[50ms] [&_.slide]:duration-[700ms] [&_.slide]:ease-in-out",
        text_position(@text_position),
        padding_size(@padding),
        color_class(@overlay),
        size_class(@size),
        @class
      ]}
    >
      <button
        :if={@control}
        id={"#{@id}-carousel-prev"}
        class="absolute left-0 inset-y-0 z-20 p-4 bg-black/10 hover:bg-black/30 transition focus:outline-none"
      >
        <.icon name="hero-chevron-left" class="size-7 text-white" />
      </button>

      <button
        :if={@control}
        id={"#{@id}-carousel-next"}
        class="absolute right-0 inset-y-0 z-20 p-4 bg-black/10 hover:bg-black/30 transition focus:outline-none"
      >
        <.icon name="hero-chevron-right" class="size-7 text-white" />
      </button>

      <div
        :for={{slide, index} <- Enum.with_index(@slide, 1)}
        id={"#{@id}-carousel-slide-#{index}"}
        class={["slide h-full", slide[:class]]}
        aria-hidden={@activated_carousel + 1 != index}
      >
        <div class="relative w-full h-full">
          <.slide_image id={@id} index={index} {slide}>
            <.slide_content id={@id} index={index} {slide} />
          </.slide_image>
        </div>
      </div>

      <.slide_indicators :if={@indicator} id={@id} count={length(@slide)} />
    </div>
    """
  end

  @doc type: :component
  attr :id, :string,
    required: true,
    doc: "A unique identifier is used to manage state and interaction"

  attr :navigate, :string,
    default: nil,
    doc: "Defines the path for navigation within the application using a `navigate` attribute."

  attr :patch, :string,
    default: nil,
    doc: "Specifies the path for navigation using a LiveView patch."

  attr :href, :string, default: nil, doc: "Sets the URL for an external link."
  attr :image, :string, required: true, doc: "Image displayed alongside of an item"
  attr :image_class, :string, default: nil, doc: "Sets classes for images"
  attr :index, :integer, required: true, doc: "Determines item index"
  slot :inner_block, required: false, doc: "Inner block that renders HEEx content"

  defp slide_image(%{navigate: nav, patch: pat, href: hrf} = assigns)
       when is_binary(nav) or is_binary(pat) or is_binary(hrf) do
    ~H"""
    <.link navigate={@navigate} patch={@patch} href={@href}>
      <div class="relative">
        <.image
          class={["max-w-full", @image_class]}
          src={@image}
          id={"#{@id}-carousel-slide-image-#{@index}"}
        />
      </div>
      {render_slot(@inner_block)}
    </.link>
    """
  end

  defp slide_image(assigns) do
    ~H"""
    <div class="relative">
      <.image
        class={["max-w-full", @image_class]}
        src={@image}
        id={"#{@id}-carousel-slide-image-#{@index}"}
      />
    </div>
    {render_slot(@inner_block)}
    """
  end

  @doc type: :component
  attr :id, :string,
    required: true,
    doc: "A unique identifier is used to manage state and interaction"

  attr :title, :string, default: nil, doc: "Specifies the title of the element"
  attr :description, :string, default: nil, doc: "Determines a short description"
  attr :title_class, :string, default: "text-white", doc: "Determines custom class for the title"

  attr :description_class, :string,
    default: nil,
    doc: "Determines custom class for the description"

  attr :wrapper_class, :string, default: nil, doc: "Determines custom class for the wrapper"

  attr :content_position, :string,
    default: "",
    doc: "Determines the alignment of the element's content"

  attr :index, :integer, required: true, doc: "Determines item index"

  defp slide_content(assigns) do
    ~H"""
    <div
      :if={!is_nil(@title) || !is_nil(@description)}
      class="carousel-overlay absolute inset-0"
      id={"#{@id}-carousel-slide-content-#{@index}"}
    >
      <div
        class={[
          "description-wrapper h-full mx-auto flex flex-col gap-5",
          content_position(@content_position),
          @wrapper_class
        ]}
        id={"#{@id}-carousel-slide-content-position-#{@index}"}
      >
        <div
          :if={!is_nil(@title)}
          id={"#{@id}-carousel-slide-content-title-#{@index}"}
          class={["carousel-title", @title_class]}
        >
          {@title}
        </div>
        <p
          :if={!is_nil(@description)}
          id={"#{@id}-carousel-slide-content-description-#{@index}"}
          class={["carousel-description", @description_class]}
        >
          {@description}
        </p>
      </div>
    </div>
    """
  end

  @doc type: :component
  attr :id, :string,
    required: true,
    doc: "A unique identifier is used to manage state and interaction"

  attr :count, :integer, required: true, doc: "Count of items"

  defp slide_indicators(assigns) do
    ~H"""
    <div
      id={"#{@id}-carousel-slide-indicator"}
      class={[
        "absolute inset-x-0 bottom-0 z-10 flex justify-center gap-3 py-2.5",
        "[&>.carousel-indicator]:h-1 [&>.carousel-indicator]:w-6 [&>.carousel-indicator]:bg-white",
        "[&>.carousel-indicator.active-indicator]:opacity-100",
        "[&>.carousel-indicator]:opacity-40 [&>.carousel-indicator]:transition-all",
        "[&>.carousel-indicator]:duration-500 [&>.carousel-indicator]:ease-in-out shadow"
      ]}
    >
      <button
        :for={indicator_item <- 1..@count}
        id={"#{@id}-carousel-indicator-#{indicator_item}"}
        data-indicator-index={"#{indicator_item}"}
        class="carousel-indicator"
        aria-label={gettext("Go to slide %{index}", index: indicator_item)}
      />
    </div>
    """
  end

  defp size_class("extra_small") do
    "text-xs [&_.description-wrapper]:max-w-80 [&_.carousel-title]:md:text-xl [&_.carousel-title]:md:text-3xl"
  end

  defp size_class("small") do
    "text-sm [&_.description-wrapper]:max-w-96 [&_.carousel-title]:md:text-xl [&_.carousel-title]:md:text-4xl"
  end

  defp size_class("medium") do
    "text-base [&_.description-wrapper]:max-w-xl [&_.carousel-title]:md:text-2xl [&_.carousel-title]:md:text-5xl"
  end

  defp size_class("large") do
    "text-lg [&_.description-wrapper]:max-w-2xl [&_.carousel-title]:md:text-3xl [&_.carousel-title]:md:text-6xl"
  end

  defp size_class("extra_large") do
    "text-xl [&_.description-wrapper]:max-w-3xl [&_.carousel-title]:md:text-3xl [&_.carousel-title]:md:text-7xl"
  end

  defp size_class(params) when is_binary(params), do: params

  defp padding_size("extra_small"),
    do: "[&_.description-wrapper]:p-2.5 md:[&_.description-wrapper]:p-6"

  defp padding_size("small"), do: "[&_.description-wrapper]:p-3 md:[&_.description-wrapper]:p-7"

  defp padding_size("medium"),
    do: "[&_.description-wrapper]:p-3.5 md:[&_.description-wrapper]:p-8"

  defp padding_size("large"), do: "[&_.description-wrapper]:p-4 md:[&_.description-wrapper]:p-9"

  defp padding_size("extra_large"),
    do: "[&_.description-wrapper]:p-5 md:[&_.description-wrapper]:p-10"

  defp padding_size(params) when is_binary(params), do: params

  defp content_position("start") do
    "justify-start"
  end

  defp content_position("end") do
    "justify-end"
  end

  defp content_position("center") do
    "justify-center"
  end

  defp content_position("between") do
    "justify-between"
  end

  defp content_position("around") do
    "justify-around"
  end

  defp content_position(params) when is_binary(params), do: params

  defp text_position("start") do
    "[&_.description-wrapper]:text-start"
  end

  defp text_position("end") do
    "[&_.description-wrapper]:text-end"
  end

  defp text_position("center") do
    "[&_.description-wrapper]:text-center"
  end

  defp text_position(params) when is_binary(params), do: params

  defp color_class("base") do
    [
      "[&_.carousel-overlay]:bg-white/30 text-base-text-light [&_.carousel-controls]:hover:bg-base-border-light/5",
      "dark:[&_.carousel-overlay]:bg-base-bg-dark/30 dark:text-base-text-dark dark:[&_.carousel-controls]:hover:bg-base-border-dark/5"
    ]
  end

  defp color_class("natural") do
    [
      "[&_.carousel-overlay]:bg-natural-light/30 text-white [&_.carousel-controls]:hover:bg-natural-light/5",
      "dark:[&_.carousel-overlay]:bg-natural-dark/30 text-black dark:[&_.carousel-controls]:hover:bg-natural-dark/5"
    ]
  end

  defp color_class("white") do
    "[&_.carousel-overlay]:bg-white/30 text-form-white-text [&_.carousel-controls]:hover:bg-white/5"
  end

  defp color_class("primary") do
    [
      "[&_.carousel-overlay]:bg-primary-light/30 text-white [&_.carousel-controls]:hover:bg-primary-light/5",
      "dark:[&_.carousel-overlay]:bg-primary-dark/30 text-black dark:[&_.carousel-controls]:hover:bg-primary-dark/5"
    ]
  end

  defp color_class("secondary") do
    [
      "[&_.carousel-overlay]:bg-secondary-light/30 text-white [&_.carousel-controls]:hover:bg-secondary-light/5",
      "dark:[&_.carousel-overlay]:bg-secondary-dark/30 text-black dark:[&_.carousel-controls]:hover:bg-secondary-dark/5"
    ]
  end

  defp color_class("success") do
    [
      "[&_.carousel-overlay]:bg-success-light/30 text-white [&_.carousel-controls]:hover:bg-success-light/5",
      "dark:[&_.carousel-overlay]:bg-success-dark/30 text-black dark:[&_.carousel-controls]:hover:bg-success-dark/5"
    ]
  end

  defp color_class("warning") do
    [
      "[&_.carousel-overlay]:bg-warning-light/30 text-white [&_.carousel-controls]:hover:bg-warning-light/5",
      "dark:[&_.carousel-overlay]:bg-warning-dark/30 text-black dark:[&_.carousel-controls]:hover:bg-warning-dark/5"
    ]
  end

  defp color_class("danger") do
    [
      "[&_.carousel-overlay]:bg-danger-light/30 text-white [&_.carousel-controls]:hover:bg-danger-light/5",
      "dark:[&_.carousel-overlay]:bg-danger-dark/30 text-black dark:[&_.carousel-controls]:hover:bg-danger-dark/5"
    ]
  end

  defp color_class("info") do
    [
      "[&_.carousel-overlay]:bg-info-light/30 text-white [&_.carousel-controls]:hover:bg-info-light/5",
      "dark:[&_.carousel-overlay]:bg-info-dark/30 text-black dark:[&_.carousel-controls]:hover:bg-info-dark/5"
    ]
  end

  defp color_class("misc") do
    [
      "[&_.carousel-overlay]:bg-misc-light/30 text-white [&_.carousel-controls]:hover:bg-misc-light/5",
      "dark:[&_.carousel-overlay]:bg-misc-dark/30 text-black dark:[&_.carousel-controls]:hover:bg-misc-dark/5"
    ]
  end

  defp color_class("dawn") do
    [
      "[&_.carousel-overlay]:bg-dawn-light/30 text-white [&_.carousel-controls]:hover:bg-dawn-light/5",
      "dark:[&_.carousel-overlay]:bg-dawn-dark/30 text-black dark:[&_.carousel-controls]:hover:bg-dawn-dark/5"
    ]
  end

  defp color_class("silver") do
    [
      "[&_.carousel-overlay]:bg-silver-light/30 text-white [&_.carousel-controls]:hover:bg-silver-light/5",
      "dark:[&_.carousel-overlay]:bg-silver-dark/30 text-black dark:[&_.carousel-controls]:hover:bg-silver-dark/5"
    ]
  end

  defp color_class("dark") do
    "[&_.carousel-overlay]:bg-default-dark-bg/30 text-white [&_.carousel-controls]:hover:bg-default-dark-bg/5"
  end

  defp color_class(params) when is_binary(params), do: params
end
