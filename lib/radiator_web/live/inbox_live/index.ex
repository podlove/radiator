defmodule RadiatorWeb.InboxLive.Index do
  use RadiatorWeb, :live_view

  alias Radiator.Podcast

  @impl true
  def mount(%{"show" => show_id} = _params, _session, socket) do
    show =
      Podcast.get_show!(show_id, preload: [episodes: Podcast.list_available_episodes_query()])

    socket
    |> assign(:page_title, show.title)
    |> assign(:page_description, show.description)
    |> assign(:show, show)
    |> assign(:episodes, show.episodes)
    |> reply(:ok)
  end

  @impl true
  def handle_event("select_all", _params, socket) do
    socket
    |> push_event("select_all", %{})
    |> reply(:noreply)
  end

  def handle_event("move_selected_to_next_episode", _params, socket) do
    episode = get_selected_episode(%{"show" => socket.assigns.show.id})

    socket
    |> push_event("move_selected_to_episode", %{episode_id: episode.id})
    |> reply(:noreply)
  end

  defp get_selected_episode(%{"show" => show_id}) do
    Podcast.get_current_episode_for_show(show_id)
  end
end
