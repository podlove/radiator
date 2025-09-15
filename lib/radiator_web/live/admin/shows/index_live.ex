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
      <.table id="shows" rows={@page.results}>
        <:col :let={show} label={gettext("Title")}>{show.title}</:col>
        <:col :let={show} label={gettext("Subtitle")}>{show.subtitle}</:col>
        <:col :let={show} label={gettext("Summary")}>{show.summary}</:col>
        <:col :let={show} label={gettext("Actions")}>
          <.button navigate={~p"/admin/shows/#{show.id}"}>{gettext("Show")}</.button>
          <.button navigate={~p"/admin/shows/#{show.id}/edit"}>{gettext("Edit")}</.button>
          <.button navigate={~p"/admin/shows/#{show}/episodes"}>{gettext("Episodes")}</.button>
        </:col>
      </.table>
    </Layouts.app>
    """
  end
end
