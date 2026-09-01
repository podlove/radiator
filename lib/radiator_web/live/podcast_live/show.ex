defmodule RadiatorWeb.PodcastLive.Show do
  use RadiatorWeb, :live_view

  alias Radiator.Podcasts.Podcast
  @impl true
  def mount(%{"id" => id}, _session, socket) do
    load = [:display_title]
    podcast = Ash.get!(Podcast, id, load: load, actor: socket.assigns.current_user)

    socket
    |> assign(:page_title, "Show Podcast")
    |> assign(:podcast, podcast)
    |> ok()
  end
end
