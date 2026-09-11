defmodule RadiatorWeb.AdminLive.Index do
  use RadiatorWeb, :live_view

  alias Radiator.Podcasts.Podcast

  @impl true
  def mount(_params, _session, socket) do
    load = [:display_title]
    podcasts = Ash.read!(Podcast, load: load, actor: socket.assigns.current_user)

    socket
    |> assign(:page_title, "Admin")
    |> assign(:podcasts, podcasts)
    |> ok()
  end
end
