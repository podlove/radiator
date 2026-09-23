defmodule RadiatorWeb.PodcastLive.Index do
  use RadiatorWeb, :live_view

  @impl true
  def mount(_params, _session, socket) do
    socket
    |> assign(:page_title, "Podcasts")
    |> ok()
  end
end
