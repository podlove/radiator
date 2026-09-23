defmodule RadiatorWeb.PodcastLive.Show do
  use RadiatorWeb, :live_view

  # alias Phoenix.Socket.Broadcast
  alias Radiator.Podcasts

  @impl true
  def mount(%{"podcast" => podcast_id}, _session, socket) do
    load = [:episodes]
    podcast = Podcasts.public_get_podcast_by_id!(podcast_id, load: load)

    socket
    |> assign(:page_title, podcast.title)
    |> assign(:podcast, podcast)
    |> ok()
  end
end
