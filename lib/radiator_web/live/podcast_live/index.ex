defmodule RadiatorWeb.PodcastLive.Index do
  use RadiatorWeb, :live_view

  alias Radiator.Podcasts

  @impl true
  def mount(_params, _session, socket) do
    # Podcasts with the latest episode first; ties and podcasts without episodes
    # fall back to the last edit.
    podcasts =
      Podcasts.public_read_podcasts!(
        load: [:episode_count, :latest_episode_at],
        query: [sort: [latest_episode_at: :desc_nils_last, updated_at: :desc]]
      )

    socket
    |> assign(:page_title, "Podcasts")
    |> stream(:podcasts, podcasts)
    |> ok()
  end
end
