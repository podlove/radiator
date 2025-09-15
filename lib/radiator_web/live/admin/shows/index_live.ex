defmodule RadiatorWeb.Admin.Shows.IndexLive do
  use RadiatorWeb, :live_view

  @impl Phoenix.LiveView
  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  @impl Phoenix.LiveView
  def handle_params(params, _uri, socket) do
    page_params = AshPhoenix.LiveView.page_from_params(params, 10)
    page = Radiator.Podcasts.read_shows!(nil, page: page_params)

    socket =
      socket
      |> assign(:page, page)

    {:noreply, socket}
  end

  @impl Phoenix.LiveView
  def render(assigns) do
    ~H"""
    <Layouts.app {assigns}>
      <h1>{gettext("Shows")}</h1>
      <.button navigate={~p"/admin/shows/new"} variant="primary">{gettext("New")}</.button>
      <table>
        <thead>
          <tr>
            <th>{gettext("Title")}</th>
            <th>{gettext("Subtitle")}</th>
            <th>{gettext("Summary")}</th>
            <th>{gettext("Actions")}</th>
          </tr>
        </thead>
        <tbody>
          <.show_table_row :for={show <- @page.results} show={show} />
        </tbody>
      </table>
    </Layouts.app>
    """
  end

  @doc """
  Renders a table row for a show.
  """
  attr :show, Radiator.Podcasts.Show, required: true

  def show_table_row(assigns) do
    ~H"""
    <tr>
      <td>{@show.title}</td>
      <td>{@show.subtitle}</td>
      <td>{@show.summary}</td>
      <td>
        <.button navigate={~p"/admin/shows/#{@show.id}"}>{gettext("Show")}</.button>
        <.button navigate={~p"/admin/shows/#{@show.id}/edit"}>{gettext("Edit")}</.button>
      </td>
    </tr>
    """
  end
end
