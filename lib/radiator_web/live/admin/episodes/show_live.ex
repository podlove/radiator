defmodule RadiatorWeb.Admin.Episodes.ShowLive do
  use RadiatorWeb, :live_view

  require Logger

  @impl Phoenix.LiveView
  def mount(%{"id" => id}, _session, socket) do
    episode = Radiator.Podcasts.get_episode_by_id!(id, load: [:show])

    socket =
      socket
      |> assign(:episode, episode)

    {:ok, socket}
  end

  @impl Phoenix.LiveView
  def render(assigns) do
    ~H"""
    <Layouts.app {assigns}>
      <h1>{@episode.title}</h1>
      <dl>
        <dt>{gettext("Number")}</dt>
        <dd>{@episode.number}</dd>
        <dt>{gettext("Title")}</dt>
        <dd>{@episode.title}</dd>
        <dt>{gettext("Subtitle")}</dt>
        <dd>{@episode.subtitle}</dd>
        <dt>{gettext("Summary")}</dt>
        <dd>{@episode.summary}</dd>
        <dt>{gettext("iTunes Type")}</dt>
        <dd>{@episode.itunes_type}</dd>
        <dt>{gettext("Publication Date")}</dt>
        <dd>{@episode.publication_date}</dd>
        <dt>{gettext("Duration Seconds")}</dt>
        <dd>{@episode.duration_seconds}</dd>
      </dl>
      <.button
        variant="danger"
        data-confirm={gettext("Are you sure you want to delete %{title}?", title: @episode.title)}
        phx-value-id={@episode.id}
        phx-click="destroy-episode"
      >
        {gettext("Delete Episode")}
      </.button>
      <.button
        navigate={~p"/admin/shows/#{@episode.show}/episodes/#{@episode}/edit"}
        variant="primary"
      >
        {gettext("Edit Episode")}
      </.button>
    </Layouts.app>
    """
  end
end
