defmodule RadiatorWeb.Components.Gallery do
  @moduledoc """
  The `RadiatorWeb.Components.Gallery` module provides a customizable gallery component for displaying
  media content in a structured and visually appealing layout.

  It supports various styles, including default, masonry, and featured galleries,
  with options to control the number of columns, gaps, and additional styling.

  ### Features:

  - **Gallery Types:** Choose between "default", "masonry", and "featured" gallery layouts.
  - **Customizable Columns and Gaps:** Configure the number of columns and spacing between gallery items.
  - **Flexible Media Display:** Includes a `gallery_media` component for displaying individual
  media items with options for styling, shadow, and border radius.

  This component is ideal for showcasing images, videos, or other media content in a grid
  or masonry layout, offering a clean and flexible way to present visual elements on a web page.

  **Documentation:** https://mishka.tools/chelekom/docs/gallery
  """

  use Phoenix.Component
  use Gettext, backend: RadiatorWeb.Gettext

  import Phoenix.LiveView.Utils, only: [random_id: 0]

  @doc """
  Renders a `gallery` component that supports various layout types including default grid,
  masonry, and featured styles.

  You can customize the number of columns and gaps between items to achieve the desired layout.

  ## Examples

  ```elixir
  <.gallery type="masonry" cols="four" gap="large">
    <.gallery_media src="https://example.com/gallery/masonry/image.jpg" />
    <.gallery_media src="https://example.com/gallery/masonry/image-2.jpg" />
    <.gallery_media src="https://example.com/gallery/masonry/image-3.jpg" />
    <.gallery_media src="https://example.com/gallery/masonry/image-4.jpg" />
    <.gallery_media src="https://example.com/gallery/masonry/image-5.jpg" />
    <.gallery_media src="https://example.com/gallery/masonry/image-6.jpg" />
    <.gallery_media src="https://example.com/gallery/masonry/image-7.jpg" />
    <.gallery_media src="https://example.com/gallery/masonry/image-8.jpg" />
    <.gallery_media src="https://example.com/gallery/masonry/image-1.jpg" />
  </.gallery>
  ```
  """
  @doc type: :component
  attr :id, :string,
    default: nil,
    doc: "A unique identifier is used to manage state and interaction"

  attr :type, :string, values: ["default", "masonry", "featured"], default: "default", doc: ""
  attr :class, :string, default: nil, doc: "Custom CSS class for additional styling"
  attr :cols, :string, default: "", doc: "Determines cols of elements"
  attr :gap, :string, default: "", doc: "Determines animation type for gallery items"
  attr :animation, :string, default: "", doc: "Determines animation intensity/size"
  attr :animation_size, :string, default: "extra_small", doc: "Determines gap between elements"

  attr :rest, :global,
    doc:
      "Global attributes can define defaults which are merged with attributes provided by the caller"

  slot :inner_block, required: false, doc: "Inner block that renders HEEx content"

  def gallery(assigns) do
    ~H"""
    <div
      id={@id}
      role="region"
      class={[
        (@type == "masonry" && "gallery-masonry") || "grid",
        grid_gap(@gap),
        @type == "masonry" && column_class(@cols),
        grid_cols(@cols) != "masonry" && grid_cols(@cols),
        animation(@animation, @animation_size),
        @class
      ]}
      {@rest}
    >
      {render_slot(@inner_block)}
    </div>
    """
  end

  @doc """
  Renders a `gallery_media` component within a gallery, which typically includes images.
  You can customize the border radius and shadow style of the media element.

  ## Examples

  ```elixir
  <.gallery_media src="https://example.com/gallery/masonry/image.jpg" />
  <.gallery_media src="https://example.com/gallery/masonry/image-2.jpg" rounded="large" shadow="shadow-lg" />
  ```
  """
  @doc type: :component
  attr :id, :string,
    default: nil,
    doc: "A unique identifier is used to manage state and interaction"

  attr :class, :string, default: nil, doc: "Custom CSS class for additional styling"
  attr :wrapper_class, :string, default: nil, doc: "Custom CSS class for additional styling"
  attr :src, :string, default: nil, doc: "Media link"
  attr :alt, :string, default: nil, doc: "Media link description"
  attr :rounded, :string, default: "none", doc: "Determines the border radius"
  attr :shadow, :string, default: "shadow-none", doc: "Determines shadow style"

  attr :rest, :global,
    doc:
      "Global attributes can define defaults which are merged with attributes provided by the caller"

  slot :inner_block, required: false, doc: "Inner block that renders HEEx content"

  def gallery_media(assigns) do
    ~H"""
    <div
      id={@id}
      class={["relative gallery-media overflow-hidden transition-all duration-300", @wrapper_class]}
      {@rest}
    >
      <img
        :if={@src}
        class={[
          "gallery-media-img h-auto max-w-full transition-all duration-300",
          rounded_size(@rounded),
          shadow_class(@shadow),
          @class
        ]}
        src={@src}
        alt={@alt}
        {@rest}
      />
      {render_slot(@inner_block)}
    </div>
    """
  end

  @doc """
  Renders a filterable gallery.

  ## Attributes:
  - `:id` - A unique DOM ID for the root element.
  - `:filters` - A list of category names (e.g., ["all", "nature"]).
  - `:media` - A list of media items (each should have `:src`, `:alt`, and `:category` keys).

  ## Slots:
  - `:filter` - Optional slot for rendering custom filter buttons. You will receive the current filter value with `let={filter}`.
  """
  @doc type: :component
  attr :id, :string, doc: "Unique DOM ID"
  attr :filters, :list, default: [], doc: "List of filter categories"
  attr :media, :list, default: [], doc: "List of media items with :src, :alt, and :category"
  attr :cols, :string, default: "three", doc: "Determines cols of elements"
  attr :gap, :string, default: "small", doc: "Determines gap between elements"
  attr :class, :string, default: nil, doc: "Add custom class"
  attr :default_filter, :string, default: "All", doc: "Default Button to show all images"
  slot :filter, required: false, doc: "Slot for rendering each filter button with let={filter}"
  attr :animation, :string, default: "", doc: "Determines animation type for gallery items"

  attr :animation_size, :string,
    default: "extra_small",
    doc: "Determines animation intensity/size"

  attr :content_class, :string, default: nil, doc: "Add custom classe to content wrapper"

  attr :filters_wrapper_class, :string,
    default: nil,
    doc: "Add custom classe to filter button wrapper"

  slot :media_block,
    required: false,
    doc: "Optional slot for rendering each media item with let={media}"

  attr :rest, :global,
    doc:
      "Global attributes can define defaults which are merged with attributes provided by the caller"

  def filterable_gallery(assigns) do
    assigns = assign_new(assigns, :id, fn -> random_id() end)

    ~H"""
    <div
      id={@id}
      phx-hook="GalleryFilter"
      phx-update="ignore"
      role="region"
      data-default-filter={@default_filter}
      class={["filterable-gallery", animation(@animation, @animation_size), @class]}
      {@rest}
    >
      <div
        class={["filter-buttons mb-4 flex flex-wrap gap-2", @filters_wrapper_class]}
        role="group"
        aria-label={gettext("Filter options")}
      >
        <div :if={not Enum.member?(@filters, @default_filter)}>
          <div :if={@filter != []}>
            {render_slot(@filter, @default_filter)}
          </div>
          <button
            :if={@filter == []}
            data-gallery-filter
            data-category={@default_filter}
            class="filter-btn bg-white border rounded py-1.5 px-3 leading-5 text-base-text-light border-base-border-light hover:bg-base-hover-light dark:bg-base-bg-dark dark:text-base-text-dark dark:border-base-border-dark dark:hover:bg-base-hover-dark disabled:bg-base-disabled-bg-light disabled:text-base-disabled-text-light dark:disabled:bg-base-disabled-bg-dark dark:disabled:text-base-disabled-text-dark disabled:border-base-disabled-border-light dark:disabled:border-base-disabled-border-dark shadow-sm"
          >
            {@default_filter}
          </button>
        </div>

        <div :for={filter <- @filters}>
          <div :for={entry <- @filter}>
            {render_slot(entry, filter)}
          </div>

          <button
            :if={@filter == []}
            data-gallery-filter
            data-category={filter}
            class="filter-btn bg-white border rounded py-1.5 px-3 leading-5 text-base-text-light border-base-border-light hover:bg-base-hover-light dark:bg-base-bg-dark dark:text-base-text-dark dark:border-base-border-dark dark:hover:bg-base-hover-dark disabled:bg-base-disabled-bg-light disabled:text-base-disabled-text-light dark:disabled:bg-base-disabled-bg-dark dark:disabled:text-base-disabled-text-dark disabled:border-base-disabled-border-light dark:disabled:border-base-disabled-border-dark shadow-sm"
          >
            {filter}
          </button>
        </div>
      </div>
      <div class={["grid", grid_gap(@gap), grid_cols(@cols), @content_class]}>
        <div
          :for={media <- @media}
          data-gallery-item
          data-category={
            if is_list(media.category), do: Enum.join(media.category, ","), else: media.category
          }
          class="transition-all duration-300 ease-in-out transform opacity-100 scale-100"
        >
          <div :if={@media_block != []}>
            {render_slot(@media_block, media)}
          </div>

          <.gallery_media :if={@media_block == []} src={media.src} alt={media.alt} />
        </div>
      </div>
    </div>
    """
  end

  defp rounded_size("extra_small"), do: "rounded-sm"

  defp rounded_size("small"), do: "rounded"

  defp rounded_size("medium"), do: "rounded-md"

  defp rounded_size("large"), do: "rounded-lg"

  defp rounded_size("extra_large"), do: "rounded-xl"

  defp rounded_size("full"), do: "rounded-full"

  defp rounded_size(params) when is_binary(params), do: params

  defp shadow_class("extra_small"), do: "shadow-sm"
  defp shadow_class("small"), do: "shadow"
  defp shadow_class("medium"), do: "shadow-md"
  defp shadow_class("large"), do: "shadow-lg"
  defp shadow_class("extra_large"), do: "shadow-xl"
  defp shadow_class("none"), do: "shadow-none"
  defp shadow_class(params) when is_binary(params), do: params

  defp animation("scale-down", "extra_small"), do: "[&_.gallery-media-img]:hover:scale-[0.99]"
  defp animation("scale-down", "small"), do: "[&_.gallery-media-img]:hover:scale-[0.97]"
  defp animation("scale-down", "medium"), do: "[&_.gallery-media-img]:hover:scale-[0.95]"
  defp animation("scale-down", "large"), do: "[&_.gallery-media-img]:hover:scale-[0.93]"
  defp animation("scale-down", "extra_large"), do: "[&_.gallery-media-img]:hover:scale-[0.91]"

  defp animation("scale-up", "extra_small"), do: "[&_.gallery-media-img]:hover:scale-[1.02]"
  defp animation("scale-up", "small"), do: "[&_.gallery-media-img]:hover:scale-[1.04]"
  defp animation("scale-up", "medium"), do: "[&_.gallery-media-img]:hover:scale-[1.06]"
  defp animation("scale-up", "large"), do: "[&_.gallery-media-img]:hover:scale-[1.08]"
  defp animation("scale-up", "extra_large"), do: "[&_.gallery-media-img]:hover:scale-[1.1]"

  defp animation("blur", "extra_small"), do: "[&_.gallery-media-img]:hover:blur-[0.05rem]"
  defp animation("blur", "small"), do: "[&_.gallery-media-img]:hover:blur-[0.07rem]"
  defp animation("blur", "medium"), do: "[&_.gallery-media-img]:hover:blur-[0.09rem]"
  defp animation("blur", "large"), do: "[&_.gallery-media-img]:hover:blur-[0.1rem]"
  defp animation("blur", "extra_large"), do: "[&_.gallery-media-img]:hover:blur-[0.12rem]"

  defp animation("backdrop", "extra_small") do
    [
      "[&_.gallery-media]:hover:after:bg-natural-light/30 dark:[&_.gallery-media]:hover:after:bg-natural-dark/30",
      "[&_.gallery-media]:after:absolute [&_.gallery-media]:after:inset-0 [&_.gallery-media]:hover:after:backdrop-blur-[0.02rem]"
    ]
  end

  defp animation("backdrop", "small") do
    [
      "[&_.gallery-media]:hover:after:bg-natural-light/30 dark:[&_.gallery-media]:hover:after:bg-natural-dark/30",
      "[&_.gallery-media]:after:absolute [&_.gallery-media]:after:inset-0 [&_.gallery-media]:hover:after:backdrop-blur-[0.04rem]"
    ]
  end

  defp animation("backdrop", "medium") do
    [
      "[&_.gallery-media]:hover:after:bg-natural-light/30 dark:[&_.gallery-media]:hover:after:bg-natural-dark/30",
      "[&_.gallery-media]:after:absolute [&_.gallery-media]:after:inset-0 [&_.gallery-media]:hover:after:backdrop-blur-[0.06rem]"
    ]
  end

  defp animation("backdrop", "large") do
    [
      "[&_.gallery-media]:hover:after:bg-natural-light/30 dark:[&_.gallery-media]:hover:after:bg-natural-dark/30",
      "[&_.gallery-media]:after:absolute [&_.gallery-media]:after:inset-0 [&_.gallery-media]:hover:after:backdrop-blur-[0.08rem]"
    ]
  end

  defp animation("backdrop", "extra_large") do
    [
      "[&_.gallery-media]:hover:after:bg-natural-light/30 dark:[&_.gallery-media]:hover:after:bg-natural-dark/30",
      "[&_.gallery-media]:after:absolute [&_.gallery-media]:after:inset-0 [&_.gallery-media]:hover:after:backdrop-blur-[0.1rem]"
    ]
  end

  defp animation(params, _) when is_binary(params), do: params

  defp grid_cols("one"), do: "grid-cols-1"
  defp grid_cols("two"), do: "grid-cols-2"
  defp grid_cols("three"), do: "grid-cols-2 md:grid-cols-3"
  defp grid_cols("four"), do: "grid-cols-2 md:grid-cols-4"
  defp grid_cols("five"), do: "grid-cols-2 md:grid-cols-5"
  defp grid_cols("six"), do: "grid-cols-2 md:grid-cols-6"
  defp grid_cols("seven"), do: "grid-cols-2 md:grid-cols-7"
  defp grid_cols("eight"), do: "grid-cols-2 md:grid-cols-8"
  defp grid_cols("nine"), do: "grid-cols-2 md:grid-cols-9"
  defp grid_cols("ten"), do: "grid-cols-2 md:grid-cols-10"
  defp grid_cols("eleven"), do: "grid-cols-2 md:grid-cols-11"
  defp grid_cols("twelve"), do: "grid-cols-2 md:grid-cols-12"
  defp grid_cols(params) when is_binary(params), do: params

  defp column_class("one"), do: "columns-1"
  defp column_class("two"), do: "columns-2"
  defp column_class("three"), do: "columns-2 md:columns-3"
  defp column_class("four"), do: "columns-2 md:columns-4"
  defp column_class("five"), do: "columns-2 md:columns-5"
  defp column_class("six"), do: "columns-2 md:columns-6"
  defp column_class("seven"), do: "columns-2 md:columns-7"
  defp column_class("eight"), do: "columns-2 md:columns-8"
  defp column_class("nine"), do: "columns-2 md:columns-9"
  defp column_class("ten"), do: "columns-2 md:columns-10"
  defp column_class("eleven"), do: "columns-2 md:columns-11"
  defp column_class("twelve"), do: "columns-2 md:columns-12"
  defp column_class(params) when is_binary(params), do: params

  defp grid_gap("extra_small"), do: "gap-1 [&.gallery-masonry_.gallery-media]:mb-1"
  defp grid_gap("small"), do: "gap-2 [&.gallery-masonry_.gallery-media]:mb-2"
  defp grid_gap("medium"), do: "gap-3 [&.gallery-masonry_.gallery-media]:mb-3"
  defp grid_gap("large"), do: "gap-4 [&.gallery-masonry_.gallery-media]:mb-4"
  defp grid_gap("extra_large"), do: "gap-5 [&.gallery-masonry_.gallery-media]:mb-5"
  defp grid_gap("double_large"), do: "gap-6 [&.gallery-masonry_.gallery-media]:mb-6"
  defp grid_gap("triple_large"), do: "gap-7 [&.gallery-masonry_.gallery-media]:mb-7"
  defp grid_gap("quadruple_large"), do: "gap-8 [&.gallery-masonry_.gallery-media]:mb-8"
  defp grid_gap(params) when is_binary(params), do: params
end
