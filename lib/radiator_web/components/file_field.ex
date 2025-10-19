defmodule RadiatorWeb.Components.FileField do
  @moduledoc """
  The `RadiatorWeb.Components.FileField` module provides a versatile and customizable component
  for handling file uploads in Phoenix LiveView applications.

  This module supports various configurations, allowing users to upload files or
  images through traditional file inputs or interactive dropzones.

  ### Key Features:
  - **Custom Styling Options:** Allows for customized styles, including colors, borders, and rounded corners.
  - **Flexible Input Types:** Supports both live uploads and standard file inputs.
  - **Dropzone Functionality:** Provides an interactive drag-and-drop area for file
  uploads with customizable icons and descriptions.
  - **Error Handling:** Displays error messages for issues like file size, file type,
  and maximum number of files.
  - **Upload Progress:** Shows real-time upload progress for each file.

  This component is designed to simplify file handling in forms and offers a visually
  appealing and user-friendly experience for uploading files in LiveView applications.

  **Documentation:** https://mishka.tools/chelekom/docs/forms/file-field
  """

  use Phoenix.Component
  import RadiatorWeb.Components.Progress, only: [progress: 1]
  import RadiatorWeb.Components.Spinner, only: [spinner: 1]
  import RadiatorWeb.Components.Icon, only: [icon: 1]
  use Gettext, backend: RadiatorWeb.Gettext

  @doc """
  Renders a `file_input` field with customizable styles, labels, and live upload capabilities.

  It can be used as a simple file input or as a dropzone with drag-and-drop support for files and images.

  ## Examples

  ```elixir
  <.file_field color="danger" />
  <.file_field target={:avatar} uploads={@uploads} dropzone/>
  ```
  """
  @doc type: :component
  attr :id, :string,
    default: nil,
    doc: "A unique identifier is used to manage state and interaction"

  attr :class, :string, default: nil, doc: "Custom CSS class for additional styling"
  attr :label_class, :string, default: nil, doc: "Custom CSS class for the label styling"
  attr :color, :string, default: "base", doc: "Determines color theme"
  attr :variant, :string, default: "base", doc: "Determines the style"
  attr :border, :string, default: "extra_small", doc: "Determines border style"
  attr :rounded, :string, default: "small", doc: "Determines the border radius"
  attr :live, :boolean, default: false, doc: "Specifies whether this upload is live or input file"
  attr :space, :string, default: "medium", doc: "Space between items"

  attr :size, :string,
    default: "extra_small",
    doc:
      "Determines the overall size of the elements, including padding, font size, and other items"

  attr :label, :string, default: nil, doc: "Specifies text for the label"
  attr :dashed, :boolean, default: true, doc: "Determines dashed border"
  attr :error_icon, :string, default: nil, doc: "Icon to be displayed alongside error messages"
  attr :errors, :list, default: [], doc: "List of error messages to be displayed"
  attr :uploads, :any, doc: "LiveView upload map"
  attr :name, :any, doc: "Name of input"
  attr :value, :any, doc: "Value of input"

  attr :dropzone, :boolean, default: false, doc: ""
  attr :dropzone_type, :string, default: "file", doc: "file, image"
  attr :target, :atom, doc: "Name of upload input when is used as Live Upload"
  attr :dropzone_icon, :string, default: "hero-cloud-arrow-up", doc: ""
  attr :dropzone_title, :string, default: "Click to upload, or drag and drop a file", doc: ""
  attr :dropzone_description, :string, default: nil, doc: "Specifies description for dropzone"

  attr :field, Phoenix.HTML.FormField, doc: "a form field struct retrieved from the form"

  attr :rest, :global,
    include:
      ~w(autocomplete disabled form checked multiple readonly min max step required title autofocus),
    doc:
      "Global attributes can define defaults which are merged with attributes provided by the caller"

  @spec file_field(map()) :: Phoenix.LiveView.Rendered.t()
  def file_field(%{field: %Phoenix.HTML.FormField{} = field} = assigns) do
    errors = if Phoenix.Component.used_input?(field), do: field.errors, else: []

    assigns
    |> assign(field: nil, id: assigns.id || field.id)
    |> assign(:errors, Enum.map(errors, &translate_error(&1)))
    |> assign_new(:name, fn ->
      if assigns.rest[:multiple], do: field.name <> "[]", else: field.name
    end)
    |> assign_new(:value, fn -> field.value end)
    |> file_field()
  end

  def file_field(%{dropzone: true, dropzone_type: "file"} = assigns) do
    targeted_upload = assigns.uploads[assigns.target]

    assigns =
      assigns
      |> assign_new(:entries, fn -> targeted_upload.entries end)
      |> assign_new(:upload_error, fn -> targeted_upload end)
      |> assign_new(:upload, fn -> targeted_upload end)

    ~H"""
    <div class={[
      color_variant(@variant, @color),
      border_class(@border, @variant),
      rounded_size(@rounded),
      size_class(@size),
      @dashed && "[&_.dropzone-wrapper]:border-dashed",
      @class
    ]}>
      <label
        class={[
          "dropzone-wrapper group flex flex-col items-center justify-center w-full cursor-pointer"
        ]}
        phx-drop-target={@upload.ref}
        for={@id}
        {@rest}
      >
        <div class="flex flex-col gap-3 items-center justify-center pt-5 pb-6">
          <.icon name={@dropzone_icon} class="size-14" />
          <div class="mb-2 font-semibold">
            {@dropzone_title}
          </div>

          <div>
            {@dropzone_description}
          </div>
        </div>
        <.live_file_input id={@id} upload={@upload} class="hidden" />
      </label>

      <.error :for={msg <- @errors} icon={@error_icon}>{msg}</.error>

      <div aria-live="polite" class="mt-5 space-y-4">
        <%= for entry <- @entries do %>
          <div
            class="upload-item border rounded relative p-3"
            role="group"
            aria-label={gettext("Uploading %{file}", file: entry.client_name)}
          >
            <div class="flex justify-around gap-3">
              <.icon name="hero-document-arrow-up" class="size-8" />
              <div class="w-full space-y-3">
                <div class="text-ellipsis overflow-hidden w-44 whitespace-nowrap">
                  {entry.client_name}
                </div>

                <div>
                  {convert_to_mb(entry.client_size)} <span>MB</span>
                </div>

                <.progress value={entry.progress} color={@color} size="extra_small" />
                <span class="sr-only">
                  {gettext("Uploading %{file}: %{progress} percent",
                    file: entry.client_name,
                    progress: entry.progress
                  )}
                </span>
              </div>
            </div>

            <button
              type="button"
              phx-click="cancel-upload"
              phx-value-ref={entry.ref}
              aria-label={gettext("Cancel upload for %{file}", file: entry.client_name)}
              class="absolute top-2 right-2 text-custom-black-100/60 hover:text-custome-black-100"
            >
              <.icon name="hero-x-mark" class="size-4" />
            </button>

            <%= for err <- upload_errors(@upload_error, entry) do %>
              <p class="text-rose-600 font-medium text-xs mt-3">Error: {error_to_string(err)}</p>
            <% end %>
          </div>
        <% end %>
      </div>

      <%= for err <- upload_errors(@upload_error) do %>
        <p class="text-rose-600 font-medium text-xs">{error_to_string(err)}</p>
      <% end %>
    </div>
    """
  end

  def file_field(%{dropzone: true, dropzone_type: "image"} = assigns) do
    targeted_upload = assigns.uploads[assigns.target]

    assigns =
      assigns
      |> assign_new(:entries, fn -> targeted_upload.entries end)
      |> assign_new(:upload_error, fn -> targeted_upload end)
      |> assign_new(:upload, fn -> targeted_upload end)

    ~H"""
    <div class={[
      color_variant(@variant, @color),
      border_class(@border, @variant),
      rounded_size(@rounded),
      size_class(@size),
      @dashed && "[&_.dropzone-wrapper]:border-dashed",
      @class
    ]}>
      <label
        class={[
          "dropzone-wrapper group flex flex-col items-center justify-center w-full cursor-pointer"
        ]}
        phx-drop-target={@upload.ref}
        for={@id}
        {@rest}
      >
        <div class="flex flex-col gap-3 items-center justify-center pt-5 pb-6">
          <.icon name={@dropzone_icon} class="size-14" />
          <div class="mb-2 font-semibold">
            {@dropzone_title}
          </div>

          <div>
            {@dropzone_description}
          </div>
        </div>
        <.live_file_input id={@id} upload={@upload} class="hidden" />
      </label>

      <.error :for={msg <- @errors} icon={@error_icon}>{msg}</.error>

      <%= for err <- upload_errors(@upload_error) do %>
        <p class="text-rose-600 font-semibold text-sm my-5">{error_to_string(err)}</p>
      <% end %>

      <div class="flex flex-wrap gap-3 my-3">
        <%= for entry <- @entries do %>
          <div>
            <div
              role="group"
              aria-label={gettext("Uploading %{file}", file: entry.client_name)}
              class="relative"
            >
              <div class="rounded w-24 h-24 overflow-hidden">
                <figure class="w-full h-full object-cover">
                  <.live_img_preview entry={entry} class="w-full h-full object-cover rounded" />
                </figure>
              </div>

              <button
                type="button"
                phx-click="cancel-upload"
                phx-value-ref={entry.ref}
                aria-label={gettext("Cancel upload for %{file}", file: entry.client_name)}
                class="bg-black/30 rounded p-px text-white flex justify-center items-center absolute top-2 right-2 z-10"
              >
                <.icon name="hero-x-mark" class="size-4" />
              </button>

              <div
                :if={!entry.done?}
                role="status"
                class="absolute inset-0 bg-black/25 flex justify-center items-center"
              >
                <.spinner color="base" />
                <span class="sr-only">{gettext("Uploading %{file}", file: entry.client_name)}</span>
              </div>
            </div>
            <%= for err <- upload_errors(@upload_error, entry) do %>
              <p class="text-rose-600 font-medium text-xs mt-3">Error: {error_to_string(err)}</p>
            <% end %>
          </div>
        <% end %>
      </div>
    </div>
    """
  end

  def file_field(assigns) do
    ~H"""
    <div class={[
      rounded_size(@rounded),
      color_class(@color),
      space_class(@space),
      @class
    ]}>
      <.label for={@id}>{@label}</.label>

      <%= if @live do %>
        <.live_file_input
          upload={@upload}
          id={@id}
          class={[
            "file-field block w-full cursor-pointer focus:outline-none file:border-0 file:cursor-pointer",
            "file:py-3 file:px-8 file:font-bold file:-ms-4 file:me-4"
          ]}
          {@rest}
        />
      <% else %>
        <input
          name={@name}
          id={@id}
          class={[
            "file-field block w-full cursor-pointer focus:outline-none file:border-0 file:cursor-pointer",
            "file:py-3 file:px-8 file:font-bold file:-ms-4 file:me-4"
          ]}
          type="file"
          {@rest}
        />
      <% end %>

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

  def convert_to_mb(size_in_bytes) when is_integer(size_in_bytes) do
    Float.round(size_in_bytes / (1024 * 1024), 2)
  end

  defp error_to_string(:too_large), do: "Too large"
  defp error_to_string(:not_accepted), do: "You have selected an unacceptable file type"
  defp error_to_string(:too_many_files), do: "You have selected too many files"

  defp border_class(_, variant) when variant in ["default", "shadow", "transparent", "gradient"],
    do: nil

  defp border_class("none", _), do: nil
  defp border_class("extra_small", _), do: "[&_.dropzone-wrapper]:border"
  defp border_class("small", _), do: "[&_.dropzone-wrapper]:border-2"
  defp border_class("medium", _), do: "[&_.dropzone-wrapper]:border-[3px]"
  defp border_class("large", _), do: "[&_.dropzone-wrapper]:border-4"
  defp border_class("extra_large", _), do: "[&_.dropzone-wrapper]:border-[5px]"
  defp border_class(params, _) when is_binary(params), do: params

  defp size_class("extra_small"), do: "[&_.dropzone-wrapper]:h-52"

  defp size_class("small"), do: "[&_.dropzone-wrapper]:h-56"

  defp size_class("medium"), do: "[&_.dropzone-wrapper]:h-60"

  defp size_class("large"), do: "[&_.dropzone-wrapper]:h-64"

  defp size_class("extra_large"), do: "[&_.dropzone-wrapper]:h-72"

  defp size_class(params) when is_binary(params), do: params

  defp rounded_size("none"), do: nil

  defp rounded_size("extra_small"),
    do: "[&_.file-field]:rounded-sm [&_.dropzone-wrapper]:rounded-sm"

  defp rounded_size("small"), do: "[&_.file-field]:rounded [&_.dropzone-wrapper]:rounded"

  defp rounded_size("medium"), do: "[&_.file-field]:rounded-md [&_.dropzone-wrapper]:rounded-md"

  defp rounded_size("large"), do: "[&_.file-field]:rounded-lg [&_.dropzone-wrapper]:rounded-lg"

  defp rounded_size("extra_large"),
    do: "[&_.file-field]:rounded-xl [&_.dropzone-wrapper]:rounded-xl"

  defp rounded_size(params) when is_binary(params), do: params

  defp space_class("none"), do: nil

  defp space_class("extra_small"), do: "space-y-1"

  defp space_class("small"), do: "space-y-1.5"

  defp space_class("medium"), do: "space-y-2"

  defp space_class("large"), do: "space-y-2.5"

  defp space_class("extra_large"), do: "space-y-3"

  defp space_class(params) when is_binary(params), do: params

  defp color_class("base") do
    [
      "[&_.file-field]:bg-white [&_.file-field]:file:text-base-text-light [&_.file-field]:text-base-text-light [&_.file-field]:file:bg-base-border-light",
      "dark:[&_.file-field]:bg-base-border-dark dark:[&_.file-field]:file:bg-base-bg-dark",
      "dark:[&_.file-field]:file:text-base-text-dark dark:[&_.file-field]:text-base-text-dark"
    ]
  end

  defp color_class("natural") do
    [
      "[&_.file-field]:bg-natural-light [&_.file-field]:file:text-white [&_.file-field]:text-white [&_.file-field]:file:bg-natural-bordered-text-light",
      "dark:[&_.file-field]:bg-natural-hover-dark dark:[&_.file-field]:file:bg-natural-dark",
      "dark:[&_.file-field]:file:text-black dark:[&_.file-field]:text-black"
    ]
  end

  defp color_class("primary") do
    [
      "[&_.file-field]:bg-primary-light [&_.file-field]:file:text-white [&_.file-field]:text-white [&_.file-field]:file:bg-primary-hover-light",
      "dark:[&_.file-field]:bg-primary-hover-dark dark:[&_.file-field]:file:bg-primary-dark",
      "dark:[&_.file-field]:file:text-black dark:[&_.file-field]:text-black"
    ]
  end

  defp color_class("secondary") do
    [
      "[&_.file-field]:bg-secondary-light [&_.file-field]:file:text-white [&_.file-field]:text-white [&_.file-field]:file:bg-secondary-hover-light",
      "dark:[&_.file-field]:bg-secondary-hover-dark dark:[&_.file-field]:file:bg-secondary-dark",
      "dark:[&_.file-field]:file:text-black dark:[&_.file-field]:text-black"
    ]
  end

  defp color_class("success") do
    [
      "[&_.file-field]:bg-success-light [&_.file-field]:file:text-white [&_.file-field]:text-white [&_.file-field]:file:bg-success-hover-light",
      "dark:[&_.file-field]:bg-success-hover-dark dark:[&_.file-field]:file:bg-success-dark",
      "dark:[&_.file-field]:file:text-black dark:[&_.file-field]:text-black"
    ]
  end

  defp color_class("warning") do
    [
      "[&_.file-field]:bg-warning-light [&_.file-field]:file:text-white [&_.file-field]:text-white [&_.file-field]:file:bg-warning-hover-light",
      "dark:[&_.file-field]:bg-warning-hover-dark dark:[&_.file-field]:file:bg-warning-dark",
      "dark:[&_.file-field]:file:text-black dark:[&_.file-field]:text-black"
    ]
  end

  defp color_class("danger") do
    [
      "[&_.file-field]:bg-danger-light [&_.file-field]:file:text-white [&_.file-field]:text-white [&_.file-field]:file:bg-danger-hover-light",
      "dark:[&_.file-field]:bg-danger-hover-dark dark:[&_.file-field]:file:bg-danger-dark",
      "dark:[&_.file-field]:file:text-black dark:[&_.file-field]:text-black"
    ]
  end

  defp color_class("info") do
    [
      "[&_.file-field]:bg-info-light [&_.file-field]:file:text-white [&_.file-field]:text-white [&_.file-field]:file:bg-info-hover-light",
      "dark:[&_.file-field]:bg-info-hover-dark dark:[&_.file-field]:file:bg-info-dark",
      "dark:[&_.file-field]:file:text-black dark:[&_.file-field]:text-black"
    ]
  end

  defp color_class("misc") do
    [
      "[&_.file-field]:bg-misc-light [&_.file-field]:file:text-white [&_.file-field]:text-white [&_.file-field]:file:bg-misc-hover-light",
      "dark:[&_.file-field]:bg-misc-hover-dark dark:[&_.file-field]:file:bg-misc-dark",
      "dark:[&_.file-field]:file:text-black dark:[&_.file-field]:text-black"
    ]
  end

  defp color_class("dawn") do
    [
      "[&_.file-field]:bg-dawn-light [&_.file-field]:file:text-white [&_.file-field]:text-white [&_.file-field]:file:bg-dawn-hover-light",
      "dark:[&_.file-field]:bg-dawn-hover-dark dark:[&_.file-field]:file:bg-dawn-dark",
      "dark:[&_.file-field]:file:text-black dark:[&_.file-field]:text-black"
    ]
  end

  defp color_class("silver") do
    [
      "[&_.file-field]:bg-silver-light [&_.file-field]:file:text-white [&_.file-field]:text-white [&_.file-field]:file:bg-silver-hover-light",
      "dark:[&_.file-field]:bg-silver-hover-dark dark:[&_.file-field]:file:bg-silver-dark",
      "dark:[&_.file-field]:file:text-black dark:[&_.file-field]:text-black"
    ]
  end

  defp color_class(params) when is_binary(params), do: params

  defp color_variant("base", _) do
    [
      "text-base-text-light [&_.dropzone-wrapper]:border-base-border-light [&_.dropzone-wrapper]:bg-white shadow-sm",
      "dark:text-base-text-dark dark:[&_.dropzone-wrapper]:border-base-border-dark dark:[&_.dropzone-wrapper]:bg-base-bg-dark"
    ]
  end

  defp color_variant("default", "white") do
    [
      "[&_.dropzone-wrapper]:bg-white text-black"
    ]
  end

  defp color_variant("default", "dark") do
    [
      "[&_.dropzone-wrapper]:bg-default-dark-bg text-white"
    ]
  end

  defp color_variant("default", "natural") do
    [
      "[&_.dropzone-wrapper]:bg-natural-light text-white dark:[&_.dropzone-wrapper]:bg-natural-dark dark:text-black"
    ]
  end

  defp color_variant("default", "primary") do
    [
      "[&_.dropzone-wrapper]:bg-primary-light text-white dark:[&_.dropzone-wrapper]:bg-primary-dark dark:text-black"
    ]
  end

  defp color_variant("default", "secondary") do
    [
      "[&_.dropzone-wrapper]:bg-secondary-light text-white dark:[&_.dropzone-wrapper]:bg-secondary-dark dark:text-black"
    ]
  end

  defp color_variant("default", "success") do
    [
      "[&_.dropzone-wrapper]:bg-success-light text-white dark:[&_.dropzone-wrapper]:bg-success-dark dark:text-black"
    ]
  end

  defp color_variant("default", "warning") do
    [
      "[&_.dropzone-wrapper]:bg-warning-light text-white dark:[&_.dropzone-wrapper]:bg-warning-dark dark:text-black"
    ]
  end

  defp color_variant("default", "danger") do
    [
      "[&_.dropzone-wrapper]:bg-danger-light text-white dark:[&_.dropzone-wrapper]:bg-danger-dark dark:text-black"
    ]
  end

  defp color_variant("default", "info") do
    [
      "[&_.dropzone-wrapper]:bg-info-light text-white dark:[&_.dropzone-wrapper]:bg-info-dark dark:text-black"
    ]
  end

  defp color_variant("default", "misc") do
    [
      "[&_.dropzone-wrapper]:bg-misc-light text-white dark:[&_.dropzone-wrapper]:bg-misc-dark dark:text-black"
    ]
  end

  defp color_variant("default", "dawn") do
    [
      "[&_.dropzone-wrapper]:bg-dawn-light text-white dark:[&_.dropzone-wrapper]:bg-dawn-dark dark:text-black"
    ]
  end

  defp color_variant("default", "silver") do
    [
      "[&_.dropzone-wrapper]:bg-silver-light text-white dark:[&_.dropzone-wrapper]:bg-silver-dark dark:text-black"
    ]
  end

  defp color_variant("outline", "natural") do
    [
      "text-natural-light [&_.dropzone-wrapper]:border-natural-light dark:text-natural-dark dark:[&_.dropzone-wrapper]:border-natural-dark"
    ]
  end

  defp color_variant("outline", "primary") do
    [
      "text-primary-light [&_.dropzone-wrapper]:border-primary-light dark:text-primary-dark dark:[&_.dropzone-wrapper]:border-primary-dark"
    ]
  end

  defp color_variant("outline", "secondary") do
    [
      "text-secondary-light [&_.dropzone-wrapper]:border-secondary-light dark:text-secondary-dark dark:[&_.dropzone-wrapper]:border-secondary-dark"
    ]
  end

  defp color_variant("outline", "success") do
    [
      "text-success-light [&_.dropzone-wrapper]:border-success-light dark:text-success-dark dark:[&_.dropzone-wrapper]:border-success-dark"
    ]
  end

  defp color_variant("outline", "warning") do
    [
      "text-warning-light [&_.dropzone-wrapper]:border-warning-light dark:text-warning-dark dark:[&_.dropzone-wrapper]:border-warning-dark"
    ]
  end

  defp color_variant("outline", "danger") do
    [
      "text-danger-light [&_.dropzone-wrapper]:border-danger-light dark:text-danger-dark dark:[&_.dropzone-wrapper]:border-danger-dark"
    ]
  end

  defp color_variant("outline", "info") do
    [
      "text-info-light [&_.dropzone-wrapper]:border-info-light dark:text-info-dark dark:[&_.dropzone-wrapper]:border-info-dark"
    ]
  end

  defp color_variant("outline", "misc") do
    [
      "text-misc-light [&_.dropzone-wrapper]:border-misc-light dark:text-misc-dark dark:[&_.dropzone-wrapper]:border-misc-dark"
    ]
  end

  defp color_variant("outline", "dawn") do
    [
      "text-dawn-light [&_.dropzone-wrapper]:border-dawn-light dark:text-dawn-dark dark:[&_.dropzone-wrapper]:border-dawn-dark"
    ]
  end

  defp color_variant("outline", "silver") do
    [
      "text-silver-light [&_.dropzone-wrapper]:border-silver-light dark:text-silver-dark dark:[&_.dropzone-wrapper]:border-silver-dark"
    ]
  end

  defp color_variant("shadow", "natural") do
    [
      "[&_.dropzone-wrapper]:bg-natural-light text-white dark:[&_.dropzone-wrapper]:bg-natural-dark dark:text-black",
      "[&_.dropzone-wrapper]:shadow-[0px_4px_6px_-4px_var(--color-shadow-natural)] [&_.dropzone-wrapper]:shadow-[0px_10px_15px_-3px_var(--color-shadow-natural)]",
      "dark:[&_.dropzone-wrapper]:shadow-none"
    ]
  end

  defp color_variant("shadow", "primary") do
    [
      "[&_.dropzone-wrapper]:bg-primary-light text-white dark:[&_.dropzone-wrapper]:bg-primary-dark dark:text-black",
      "[&_.dropzone-wrapper]:shadow-[0px_4px_6px_-4px_var(--color-shadow-primary)] [&_.dropzone-wrapper]:shadow-[0px_10px_15px_-3px_var(--color-shadow-primary)]",
      "dark:[&_.dropzone-wrapper]:shadow-none"
    ]
  end

  defp color_variant("shadow", "secondary") do
    [
      "[&_.dropzone-wrapper]:bg-secondary-light text-white dark:[&_.dropzone-wrapper]:bg-secondary-dark dark:text-black",
      "[&_.dropzone-wrapper]:shadow-[0px_4px_6px_-4px_var(--color-shadow-secondary)] [&_.dropzone-wrapper]:shadow-[0px_10px_15px_-3px_var(--color-shadow-secondary)]",
      "dark:[&_.dropzone-wrapper]:shadow-none"
    ]
  end

  defp color_variant("shadow", "success") do
    [
      "[&_.dropzone-wrapper]:bg-success-light text-white dark:[&_.dropzone-wrapper]:bg-success-dark dark:text-black",
      "[&_.dropzone-wrapper]:shadow-[0px_4px_6px_-4px_var(--color-shadow-success)] [&_.dropzone-wrapper]:shadow-[0px_10px_15px_-3px_var(--color-shadow-success)]",
      "dark:[&_.dropzone-wrapper]:shadow-none"
    ]
  end

  defp color_variant("shadow", "warning") do
    [
      "[&_.dropzone-wrapper]:bg-warning-light text-white dark:[&_.dropzone-wrapper]:bg-warning-dark dark:text-black",
      "[&_.dropzone-wrapper]:shadow-[0px_4px_6px_-4px_var(--color-shadow-warning)] [&_.dropzone-wrapper]:shadow-[0px_10px_15px_-3px_var(--color-shadow-warning)]",
      "dark:[&_.dropzone-wrapper]:shadow-none"
    ]
  end

  defp color_variant("shadow", "danger") do
    [
      "[&_.dropzone-wrapper]:bg-danger-light text-white dark:[&_.dropzone-wrapper]:bg-danger-dark dark:text-black",
      "[&_.dropzone-wrapper]:shadow-[0px_4px_6px_-4px_var(--color-shadow-danger)] [&_.dropzone-wrapper]:shadow-[0px_10px_15px_-3px_var(--color-shadow-danger)]",
      "dark:[&_.dropzone-wrapper]:shadow-none"
    ]
  end

  defp color_variant("shadow", "info") do
    [
      "[&_.dropzone-wrapper]:bg-info-light text-white dark:[&_.dropzone-wrapper]:bg-info-dark dark:text-black",
      "[&_.dropzone-wrapper]:shadow-[0px_4px_6px_-4px_var(--color-shadow-info)] [&_.dropzone-wrapper]:shadow-[0px_10px_15px_-3px_var(--color-shadow-info)]",
      "dark:[&_.dropzone-wrapper]:shadow-none"
    ]
  end

  defp color_variant("shadow", "misc") do
    [
      "[&_.dropzone-wrapper]:bg-misc-light text-white dark:[&_.dropzone-wrapper]:bg-misc-dark dark:text-black",
      "[&_.dropzone-wrapper]:shadow-[0px_4px_6px_-4px_var(--color-shadow-misc)] [&_.dropzone-wrapper]:shadow-[0px_10px_15px_-3px_var(--color-shadow-misc)]",
      "dark:[&_.dropzone-wrapper]:shadow-none"
    ]
  end

  defp color_variant("shadow", "dawn") do
    [
      "[&_.dropzone-wrapper]:bg-dawn-light text-white dark:[&_.dropzone-wrapper]:bg-dawn-dark dark:text-black",
      "[&_.dropzone-wrapper]:shadow-[0px_4px_6px_-4px_var(--color-shadow-dawn)] [&_.dropzone-wrapper]:shadow-[0px_10px_15px_-3px_var(--color-shadow-dawn)]",
      "dark:[&_.dropzone-wrapper]:shadow-none"
    ]
  end

  defp color_variant("shadow", "silver") do
    [
      "[&_.dropzone-wrapper]:bg-silver-light text-white dark:[&_.dropzone-wrapper]:bg-silver-dark dark:text-black",
      "[&_.dropzone-wrapper]:shadow-[0px_4px_6px_-4px_var(--color-shadow-silver)] [&_.dropzone-wrapper]:shadow-[0px_10px_15px_-3px_var(--color-shadow-silver)]",
      "dark:[&_.dropzone-wrapper]:shadow-none"
    ]
  end

  defp color_variant("bordered", "white") do
    [
      "[&_.dropzone-wrapper]:bg-white text-black [&_.dropzone-wrapper]:border-bordered-white-border"
    ]
  end

  defp color_variant("bordered", "dark") do
    [
      "[&_.dropzone-wrapper]:bg-default-dark-bg text-white [&_.dropzone-wrapper]:border-silver-hover-light"
    ]
  end

  defp color_variant("bordered", "natural") do
    [
      "text-natural-bordered-text-light [&_.dropzone-wrapper]:border-natural-bordered-text-light [&_.dropzone-wrapper]:bg-natural-bordered-bg-light",
      "dark:text-natural-hover-dark dark:[&_.dropzone-wrapper]:border-natural-hover-dark dark:[&_.dropzone-wrapper]:bg-natural-bordered-bg-dark"
    ]
  end

  defp color_variant("bordered", "primary") do
    [
      "text-primary-bordered-text-light [&_.dropzone-wrapper]:border-primary-bordered-text-light [&_.dropzone-wrapper]:bg-primary-bordered-bg-light",
      "dark:text-primary-hover-dark dark:[&_.dropzone-wrapper]:border-primary-hover-dark dark:[&_.dropzone-wrapper]:bg-primary-bordered-bg-dark"
    ]
  end

  defp color_variant("bordered", "secondary") do
    [
      "text-secondary-bordered-text-light [&_.dropzone-wrapper]:border-secondary-bordered-text-light [&_.dropzone-wrapper]:bg-secondary-bordered-bg-light",
      "dark:text-secondary-hover-dark dark:[&_.dropzone-wrapper]:border-secondary-hover-dark dark:[&_.dropzone-wrapper]:bg-secondary-bordered-bg-dark"
    ]
  end

  defp color_variant("bordered", "success") do
    [
      "text-success-bordered-text-light [&_.dropzone-wrapper]:border-success-bordered-text-light [&_.dropzone-wrapper]:bg-success-bordered-bg-light",
      "dark:text-success-hover-dark dark:[&_.dropzone-wrapper]:border-success-hover-dark dark:[&_.dropzone-wrapper]:bg-success-bordered-bg-dark"
    ]
  end

  defp color_variant("bordered", "warning") do
    [
      "text-warning-bordered-text-light [&_.dropzone-wrapper]:border-warning-bordered-text-light [&_.dropzone-wrapper]:bg-warning-bordered-bg-light",
      "dark:text-warning-hover-dark dark:[&_.dropzone-wrapper]:border-warning-hover-dark dark:[&_.dropzone-wrapper]:bg-warning-bordered-bg-dark"
    ]
  end

  defp color_variant("bordered", "danger") do
    [
      "text-danger-bordered-text-light [&_.dropzone-wrapper]:border-danger-bordered-text-light [&_.dropzone-wrapper]:bg-danger-bordered-bg-light",
      "dark:text-danger-hover-dark dark:[&_.dropzone-wrapper]:border-danger-hover-dark dark:[&_.dropzone-wrapper]:bg-danger-bordered-bg-dark"
    ]
  end

  defp color_variant("bordered", "info") do
    [
      "text-info-bordered-text-light [&_.dropzone-wrapper]:border-info-bordered-text-light [&_.dropzone-wrapper]:bg-info-bordered-bg-light",
      "dark:text-info-hover-dark dark:[&_.dropzone-wrapper]:border-info-hover-dark dark:[&_.dropzone-wrapper]:bg-info-bordered-bg-dark"
    ]
  end

  defp color_variant("bordered", "misc") do
    [
      "text-misc-bordered-text-light [&_.dropzone-wrapper]:border-misc-bordered-text-light [&_.dropzone-wrapper]:bg-misc-bordered-bg-light",
      "dark:text-misc-hover-dark dark:[&_.dropzone-wrapper]:border-misc-hover-dark dark:[&_.dropzone-wrapper]:bg-misc-bordered-bg-dark"
    ]
  end

  defp color_variant("bordered", "dawn") do
    [
      "text-dawn-bordered-text-light [&_.dropzone-wrapper]:border-dawn-bordered-text-light [&_.dropzone-wrapper]:bg-dawn-bordered-bg-light",
      "dark:text-dawn-hover-dark dark:[&_.dropzone-wrapper]:border-dawn-hover-dark dark:[&_.dropzone-wrapper]:bg-dawn-bordered-bg-dark"
    ]
  end

  defp color_variant("bordered", "silver") do
    [
      "text-silver-hover-light [&_.dropzone-wrapper]:border-silver-hover-light [&_.dropzone-wrapper]:bg-silver-bordered-bg-light",
      "dark:text-silver-hover-dark dark:[&_.dropzone-wrapper]:border-silver-hover-dark dark:[&_.dropzone-wrapper]:bg-silver-bordered-bg-dark"
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
      "[&_.dropzone-wrapper]:bg-gradient-to-br from-gradient-natural-from-light to-gradient-natural-to-light text-white",
      "dark:from-gradient-natural-from-dark dark:to-white dark:text-black"
    ]
  end

  defp color_variant("gradient", "primary") do
    [
      "[&_.dropzone-wrapper]:bg-gradient-to-br from-gradient-primary-from-light to-gradient-primary-to-light text-white",
      "dark:from-gradient-primary-from-dark dark:to-gradient-primary-to-dark dark:text-black"
    ]
  end

  defp color_variant("gradient", "secondary") do
    [
      "[&_.dropzone-wrapper]:bg-gradient-to-br from-gradient-secondary-from-light to-gradient-secondary-to-light text-white",
      "dark:from-gradient-secondary-from-dark dark:to-gradient-secondary-to-dark dark:text-black"
    ]
  end

  defp color_variant("gradient", "success") do
    [
      "[&_.dropzone-wrapper]:bg-gradient-to-br from-gradient-success-from-light to-gradient-success-to-light text-white",
      "dark:from-gradient-success-from-dark dark:to-gradient-success-to-dark dark:text-black"
    ]
  end

  defp color_variant("gradient", "warning") do
    [
      "[&_.dropzone-wrapper]:bg-gradient-to-br from-gradient-warning-from-light to-gradient-warning-to-light text-white",
      "dark:from-gradient-warning-from-dark dark:to-gradient-warning-to-dark dark:text-black"
    ]
  end

  defp color_variant("gradient", "danger") do
    [
      "[&_.dropzone-wrapper]:bg-gradient-to-br from-gradient-danger-from-light to-gradient-danger-to-light text-white",
      "dark:from-gradient-danger-from-dark dark:to-gradient-danger-to-dark dark:text-black"
    ]
  end

  defp color_variant("gradient", "info") do
    [
      "[&_.dropzone-wrapper]:bg-gradient-to-br from-gradient-info-from-light to-gradient-info-to-light text-white",
      "dark:from-gradient-info-from-dark dark:to-gradient-info-to-dark dark:text-black"
    ]
  end

  defp color_variant("gradient", "misc") do
    [
      "[&_.dropzone-wrapper]:bg-gradient-to-br from-gradient-misc-from-light to-gradient-misc-to-light text-white",
      "dark:from-gradient-misc-from-dark dark:to-gradient-misc-to-dark dark:text-black"
    ]
  end

  defp color_variant("gradient", "dawn") do
    [
      "[&_.dropzone-wrapper]:bg-gradient-to-br from-gradient-dawn-from-light to-gradient-dawn-to-light text-white",
      "dark:from-gradient-dawn-from-dark dark:to-gradient-dawn-to-dark dark:text-black"
    ]
  end

  defp color_variant("gradient", "silver") do
    [
      "[&_.dropzone-wrapper]:bg-gradient-to-br from-gradient-silver-from-light to-gradient-silver-to-light text-white",
      "dark:from-gradient-silver-from-dark dark:to-gradient-silver-to-dark dark:text-black"
    ]
  end

  defp color_variant(params, _) when is_binary(params), do: params

  defp translate_error({msg, opts}) do
    # When using gettext, we typically pass the strings we want
    # to translate as a static argument:
    #
    #     # Translate the number of files with plural rules
    #     dngettext("errors", "1 file", "%{count} files", count)
    #
    # However the error messages in our forms and APIs are generated
    # dynamically, so we need to translate them by calling Gettext
    # with our gettext backend as first argument. Translations are
    # available in the errors.po file (as we use the "errors" domain).
    if count = opts[:count] do
      Gettext.dngettext(RadiatorWeb.Gettext, "errors", msg, msg, count, opts)
    else
      Gettext.dgettext(RadiatorWeb.Gettext, "errors", msg, opts)
    end
  end
end
