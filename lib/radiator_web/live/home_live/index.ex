defmodule RadiatorWeb.HomeLive.Index do
  use RadiatorWeb, :live_view

  require Ash.Query

  alias Radiator.Podcasts.Podcast

  @impl true
  def mount(_params, _session, socket) do
    query = Podcast |> Ash.Query.filter(not is_nil(title))
    podcasts = Ash.read!(query)

    socket
    |> assign(:page_title, "Podcasts")
    |> assign(podcasts: podcasts)
    |> ok()
  end
end
