defmodule RadiatorWeb.Admin.Episodes.IndexLive do
  use RadiatorWeb, :live_view

  @impl Phoenix.LiveView
  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  @impl Phoenix.LiveView
  def handle_params(%{"podcast_id" => podcast_id} = params, _uri, socket) do
    podcast = Radiator.Podcasts.get_podcast_by_id!(podcast_id)
    page_params = AshPhoenix.LiveView.page_from_params(params, 10)

    page =
      Radiator.Podcasts.read_episodes!(nil,
        query: [filter: [podcast_id: podcast_id], sort: [number: :desc]],
        page: page_params
      )

    socket =
      socket
      |> assign(:podcast, podcast)
      |> assign(:page, page)

    {:noreply, socket}
  end

  @impl Phoenix.LiveView
  def render(assigns) do
    ~H"""
    <Layouts.app {assigns}>
      <h1>{gettext("Episodes for %{title}", title: @podcast.title)}</h1>
      <.button_link navigate={~p"/admin/podcasts/#{@podcast}/episodes/new"} variant="primary">
        {gettext("New")}
      </.button_link>
      <.table id="episodes" rows={@page.results}>
        <:col :let={episode} label={gettext("Number")}>{episode.number}</:col>
        <:col :let={episode} label={gettext("Title")}>{episode.title}</:col>
        <:col :let={episode} label={gettext("Actions")}>
          <.button_link navigate={~p"/admin/podcasts/#{@podcast}/episodes/#{episode}"}>
            {gettext("Podcast")}
          </.button_link>
          <.button_link navigate={~p"/admin/podcasts/#{@podcast}/episodes/#{episode}/edit"}>
            {gettext("Edit")}
          </.button_link>
        </:col>
      </.table>
    </Layouts.app>
    """
  end
end
