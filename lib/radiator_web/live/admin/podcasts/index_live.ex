defmodule RadiatorWeb.Admin.Podcasts.IndexLive do
  use RadiatorWeb, :live_view

  @impl Phoenix.LiveView
  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  @impl Phoenix.LiveView
  def handle_params(params, _uri, socket) do
    page_params = AshPhoenix.LiveView.page_from_params(params, 10)
    page = Radiator.Podcasts.read_podcasts!(nil, page: page_params)

    socket =
      socket
      |> assign(:page, page)

    {:noreply, socket}
  end

  @impl Phoenix.LiveView
  def render(assigns) do
    ~H"""
    <Layouts.app {assigns}>
      <h1>{gettext("Podcasts")}</h1>
      <.button_link navigate={~p"/admin/podcasts/new"} variant="primary">
        {gettext("New")}
      </.button_link>
      <.table id="podcasts" rows={@page.results}>
        <:col :let={podcast} label={gettext("Title")}>{podcast.title}</:col>
        <:col :let={podcast} label={gettext("Subtitle")}>{podcast.subtitle}</:col>
        <:col :let={podcast} label={gettext("Summary")}>{podcast.summary}</:col>
        <:col :let={podcast} label={gettext("Actions")}>
          <.button_link navigate={~p"/admin/podcasts/#{podcast.id}"}>{gettext("Show")}</.button_link>
          <.button_link navigate={~p"/admin/podcasts/#{podcast.id}/edit"}>
            {gettext("Edit")}
          </.button_link>
          <.button_link navigate={~p"/admin/podcasts/#{podcast}/episodes"}>
            {gettext("Episodes")}
          </.button_link>
        </:col>
      </.table>
    </Layouts.app>
    """
  end
end
