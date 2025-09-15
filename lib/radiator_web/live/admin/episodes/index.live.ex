defmodule RadiatorWeb.Admin.Episodes.IndexLive do
  use RadiatorWeb, :live_view

  @impl Phoenix.LiveView
  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  @impl Phoenix.LiveView
  def handle_params(%{"show_id" => show_id} = params, _uri, socket) do
    show = Radiator.Podcasts.get_show_by_id!(show_id)
    page_params = AshPhoenix.LiveView.page_from_params(params, 10)

    page =
      Radiator.Podcasts.read_episodes!(nil,
        query: [filter: [show_id: show_id]],
        page: page_params
      )

    socket =
      socket
      |> assign(:show, show)
      |> assign(:page, page)

    {:noreply, socket}
  end

  @impl Phoenix.LiveView
  def render(assigns) do
    ~H"""
    <Layouts.app {assigns}>
      <h1>{gettext("Episodes for %{title}", title: @show.title)}</h1>
      <.button navigate={~p"/admin/shows/#{@show}/episodes/new"} variant="primary">
        {gettext("New")}
      </.button>
      <.table id="episodes" rows={@page.results}>
        <:col :let={episode} label={gettext("Number")}>{episode.number}</:col>
        <:col :let={episode} label={gettext("Title")}>{episode.title}</:col>
        <:col :let={episode} label={gettext("Actions")}>
          <.button navigate={~p"/admin/shows/#{@show}/episodes/#{episode}"}>
            {gettext("Show")}
          </.button>
          <.button navigate={~p"/admin/shows/#{@show}/episodes/#{episode}/edit"}>
            {gettext("Edit")}
          </.button>
        </:col>
      </.table>
    </Layouts.app>
    """
  end
end
