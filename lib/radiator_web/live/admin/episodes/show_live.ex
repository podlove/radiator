defmodule RadiatorWeb.Admin.Episodes.ShowLive do
  use RadiatorWeb, :live_view

  require Logger

  @impl Phoenix.LiveView
  def mount(%{"id" => id}, _session, socket) do
    episode = Radiator.Podcasts.get_episode_by_id!(id, load: [:podcast, :participants])

    socket =
      socket
      |> assign(:episode, episode)

    {:ok, socket}
  end
end
