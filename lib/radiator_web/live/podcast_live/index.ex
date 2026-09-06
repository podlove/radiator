defmodule RadiatorWeb.PodcastLive.Index do
  use RadiatorWeb, :live_view

  alias Radiator.Podcasts.Podcast

  @impl true
  def mount(_params, _session, socket) do
    load = [:display_title]
    podcasts = Ash.read!(Podcast, load: load, actor: socket.assigns.current_user)

    socket
    |> assign(:page_title, "Listing Podcasts")
    |> stream(:podcasts, podcasts)
    |> ok()
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    podcast = Ash.get!(Podcast, id, actor: socket.assigns.current_user)
    Ash.destroy!(podcast, actor: socket.assigns.current_user)

    socket
    |> stream_delete(:podcasts, podcast)
    |> noreply()
  end
end
