defmodule RadiatorWeb.Admin.Podcasts.ShowLive do
  use RadiatorWeb, :live_view

  require Logger

  @impl Phoenix.LiveView
  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  @impl Phoenix.LiveView
  def handle_params(%{"id" => id}, _uri, socket) do
    podcast = Radiator.Podcasts.get_podcast_by_id!(id)

    socket =
      socket
      |> assign(:podcast, podcast)

    {:noreply, socket}
  end

  @impl Phoenix.LiveView
  def render(assigns) do
    ~H"""
    <Layouts.app {assigns}>
      <h1>{@podcast.title}</h1>
      <h2 :if={@podcast.subtitle}>{@podcast.subtitle}</h2>
      <.button
        variant="danger"
        data-confirm={gettext("Are you sure you want to delete %{title}?", title: @podcast.title)}
        phx-value-id={@podcast.id}
        phx-click="destroy-podcast"
      >
        {gettext("Delete Podcast")}
      </.button>
      <.button_link navigate={~p"/admin/podcasts/#{@podcast}/edit"} variant="primary">
        {gettext("Edit Podcast")}
      </.button_link>
      <.button_link navigate={~p"/admin/podcasts/#{@podcast}/episodes/schedule"} variant="primary">
        {gettext("Schedule New Episode")}
      </.button_link>
      <.button_link navigate={~p"/admin/podcasts/#{@podcast}/episodes"} variant="primary">
        {gettext("Episodes")}
      </.button_link>
    </Layouts.app>
    """
  end

  def handle_event("destroy-podcast", %{"id" => podcast_id}, socket) do
    case Radiator.Podcasts.destroy_podcast(podcast_id) do
      :ok ->
        socket =
          socket
          |> put_flash(:info, gettext("Podcast deleted"))
          |> push_navigate(to: ~p"/admin/podcasts")

        {:noreply, socket}

      {:error, error} ->
        Logger.info("Could not delete podcast #{podcast_id}: #{inspect(error)}")

        socket =
          socket
          |> put_flash(:error, gettext("Could not delete podcast"))

        {:noreply, socket}
    end
  end
end
