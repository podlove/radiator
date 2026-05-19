defmodule RadiatorWeb.FormComponents do
  @moduledoc """
  Application-specific form components.
  """
  use Phoenix.Component
  use Gettext, backend: RadiatorWeb.Gettext

  import DaisyUIComponents.Button

  @doc """
  Renders a pair of form action buttons: a cancel link and a primary submit
  button, placed next to each other on the right.

  ## Examples

      <:actions>
        <.form_actions cancel_to={~p"/admin/podcasts"} />
      </:actions>

      <:actions>
        <.form_actions cancel_to={~p"/admin/podcasts"} submit_label={gettext("Create")} />
      </:actions>
  """
  attr :cancel_to, :string, required: true, doc: "the path to navigate to on cancel"
  attr :submit_label, :string, doc: "label for the submit button"

  def form_actions(assigns) do
    assigns = assign_new(assigns, :submit_label, fn -> gettext("Save") end)

    ~H"""
    <.button navigate={@cancel_to} ghost type="button">{gettext("Cancel")}</.button>
    <.button variant="primary" type="submit">{@submit_label}</.button>
    """
  end

  @doc """
  Renders a labeled detail entry for use inside a `<dl>` grid. Empty values
  (`nil`, `""`, `[]`) are shown as an em-dash.

  ## Examples

      <dl class="grid grid-cols-1 sm:grid-cols-2 gap-x-8 gap-y-3">
        <.detail label={gettext("Author")} value={@podcast.author} />
      </dl>
  """
  attr :label, :string, required: true
  attr :value, :any, required: true

  def detail(assigns) do
    ~H"""
    <div>
      <dt class="text-xs font-semibold uppercase opacity-60">{@label}</dt>
      <dd>{if @value in [nil, "", []], do: "—", else: @value}</dd>
    </div>
    """
  end
end
