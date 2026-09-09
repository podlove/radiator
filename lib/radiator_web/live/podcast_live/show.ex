defmodule RadiatorWeb.PodcastLive.Show do
  use RadiatorWeb, :live_view

  alias Radiator.Podcasts
  alias Radiator.Podcasts.Podcast
  alias Radiator.Podcasts.SyncStatus
  alias Radiator.Podcasts.SyncStrategy
  alias RadiatorWeb.Formatting

  @load [:display_title, episodes: [:missing_from_feed?]]

  @impl true
  def mount(%{"id" => id}, _session, socket) do
    if connected?(socket), do: RadiatorWeb.Endpoint.subscribe("podcast:updated:#{id}")

    socket
    |> assign(:page_title, "Show Podcast")
    |> assign_podcast(id)
    |> ok()
  end

  @impl true
  def handle_event("request_sync", _params, socket) do
    Podcasts.request_sync!(socket.assigns.podcast, %{}, actor: socket.assigns.current_user)

    socket
    |> put_flash(:info, gettext("Sync angefordert."))
    |> assign_podcast(socket.assigns.podcast.id)
    |> noreply()
  end

  # A sync touches the podcast, its episodes and their contributors at once,
  # so re-read rather than patch assigns.
  @impl true
  def handle_info(%Phoenix.Socket.Broadcast{}, socket) do
    socket |> assign_podcast(socket.assigns.podcast.id) |> noreply()
  end

  defp assign_podcast(socket, id) do
    assign(
      socket,
      :podcast,
      Ash.get!(Podcast, id, load: @load, actor: socket.assigns.current_user)
    )
  end

  # The coloured rail of the sync strip encodes the status.
  defp rail_class(:idle), do: "border-base-300"
  defp rail_class(:pending), do: "border-info"
  defp rail_class(:succeeded), do: "border-success"
  defp rail_class(:failed), do: "border-error"
end
