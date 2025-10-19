defmodule RadiatorWeb.Components.Clipboard do
  @moduledoc """
  The `RadiatorWeb.Components.Clipboard` is a Phoenix LiveView component module for creating customizable clipboard functionality.

  This module provides components to facilitate copying text to the clipboard, with customizable options for feedback, styling, and accessibility. The main component, `clipboard/1`, can copy provided text or content from a specified DOM element.

  The clipboard component supports features such as:
  - Single-click copy functionality
  - Dynamic feedback messages for success or error states
  - Customizable styling for visual indicators
  - Accessibility enhancements through ARIA attributes
  - Flexible content rendering through slots

  **Documentation:** https://mishka.tools/chelekom/docs/clipboard
  """
  use Phoenix.Component
  use Gettext, backend: RadiatorWeb.Gettext
  import Phoenix.LiveView.Utils, only: [random_id: 0]

  @doc """
  The `clipboard` component provides interactive, accessible copy-to-clipboard functionality with dynamic feedback and customization options.

  This component allows users to copy provided text or text content from a targeted DOM element, with visual and ARIA-enhanced feedback for success or error states. It supports flexible usage patterns with slots for custom triggers and content.

  ## Features include:
  - One-click clipboard interaction
  - Dynamic success/error messages
  - Visual feedback via customizable CSS classes
  - Support for static or target-based copying
  - Accessible attributes and screen reader descriptions
  - Customizable trigger button with ARIA labels
  - Optional status display with animation or transitions
  - Slot support for flexible rendering of content and triggers

  ## Example usage:

  ### Basic copy button with static text
      <.clipboard text="Some text to copy">
        <:trigger>
          <button class="btn">Copy</button>
        </:trigger>
      </.clipboard>

  ### Copy from an existing element
      <div id="my-text">Copy this text</div>

      <.clipboard target_selector="#my-text">
        <:trigger>
          <button class="btn">Copy from element</button>
        </:trigger>
      </.clipboard>

  ### Clipboard with success and error messages
      <.clipboard
        text="Clipboard content"
        copy_success_text="Copied successfully!"
        copy_error_text="Copy failed. Try again!"
      >
        <:trigger>
          <button class="btn">Copy now</button>
        </:trigger>
      </.clipboard>

  ### Dynamic label change after copy
      <.clipboard text="Secret code" dynamic_label={true}>
        <:trigger>
          <span class="clipboard-label">Click to copy</span>
        </:trigger>
      </.clipboard>

  ### With screen reader description and custom styling
      <.clipboard
        text="Accessible text"
        text_description="Copies the accessible text to your clipboard"
        class="rounded border p-2"
        success_class="bg-green-200"
        error_class="bg-red-200"
      >
        <:trigger>
          <button class="btn">📋 Copy</button>
        </:trigger>
      </.clipboard>
  """

  @doc type: :component
  attr :id, :string, doc: "The unique identifier for the clipboard component element."

  attr :class, :string,
    default: nil,
    doc: "CSS classes to apply to the clipboard component container."

  attr :text, :string,
    default: nil,
    doc:
      "The text to copy to the clipboard. If not provided, it will look for the text content or target selector."

  attr :target_selector, :string,
    default: nil,
    doc: "The CSS selector for the target element to copy from, if no text is provided."

  attr :timeout, :integer,
    default: 2000,
    doc:
      "The timeout duration (in milliseconds) before the clipboard operation is considered failed."

  attr :success_class, :string,
    default: "clipboard-success",
    doc: "CSS class applied to the component when the clipboard copy is successful."

  attr :error_class, :string,
    default: "clipboard-error",
    doc: "CSS class applied to the component when the clipboard copy fails."

  attr :copy_success_text, :string,
    doc: "The success message to display after a successful copy operation."

  attr :copy_error_text, :string,
    doc: "The error message to display after a failed copy operation."

  attr :copy_button_label, :string,
    default: nil,
    doc: "Label for the button used to trigger the copy operation."

  attr :text_description, :string,
    default: nil,
    doc:
      "Optional description text for screen readers, providing more context about the clipboard functionality."

  attr :status_class, :string,
    default: "block mt-2",
    doc: "CSS class for styling the status message shown after a copy operation."

  attr :content_class, :string,
    default: "block mb-2",
    doc: "CSS class for styling the content shown in the clipboard container."

  attr :trigger_class, :string,
    default: nil,
    doc: "CSS class for styling the trigger wrapper."

  attr :show_status_text, :boolean,
    default: true,
    doc: "If true, displays the visual clipboard status text (e.g., 'Copied!'). Default: true."

  attr :dynamic_label, :boolean,
    default: false,
    doc:
      "If true, replaces text inside `.clipboard-label` on copy success/failure. Default: false."

  slot :content, doc: "Slot for custom content to display inside the clipboard container."

  slot :trigger,
    required: true,
    doc:
      "The slot for the button or trigger element that initiates the copy operation. This is a required slot."

  slot :inner_block,
    doc:
      "Slot for additional content or inner components that should be rendered inside the clipboard container."

  attr :rest, :global,
    doc:
      "Global attributes can define defaults which are merged with attributes provided by the caller"

  def clipboard(assigns) do
    assigns =
      assigns
      |> assign_new(:id, fn -> "clipboard-#{random_id()}" end)
      |> assign_new(:copy_success_text, fn -> gettext("Copied!") end)
      |> assign_new(:copy_error_text, fn -> gettext("Copy failed") end)
      |> assign_new(:copy_button_label, fn -> gettext("Copy to clipboard") end)
      |> then(fn new_assigns ->
        new_assigns
        |> assign(:status_id, "#{new_assigns.id}-status")
        |> assign(:content_id, "#{new_assigns.id}-content")
      end)

    ~H"""
    <span
      id={@id}
      class={["clipboard-container", @class]}
      phx-hook="Clipboard"
      phx-track-static
      phx-update="ignore"
      data-timeout={@timeout}
      data-success-class={@success_class}
      data-error-class={@error_class}
      data-clipboard-text={@text}
      data-target-selector={@target_selector}
      data-copy-success-text={@copy_success_text}
      data-copy-error-text={@copy_error_text}
      data-dynamic-label={to_string(@dynamic_label)}
      aria-describedby={@text_description && "#{@id}-description"}
    >
      <span :if={@text_description} id={"#{@id}-description"} class="sr-only">
        {@text_description}
      </span>

      <span
        :if={@text == nil && @target_selector == nil && Enum.count(@content) > 0}
        id={@content_id}
        class={["clipboard-content", @content_class]}
      >
        {render_slot(@content)}
      </span>

      <span
        class={["clipboard-trigger", @trigger_class]}
        role="button"
        tabindex="0"
        aria-describedby={@status_id}
        aria-pressed="false"
      >
        {render_slot(@trigger)}
      </span>

      <span
        :if={@show_status_text}
        id={@status_id}
        class={["clipboard-status", @status_class]}
        aria-live="polite"
        aria-hidden="true"
        aria-atomic="true"
      >
      </span>

      {render_slot(@inner_block)}
    </span>
    """
  end
end
