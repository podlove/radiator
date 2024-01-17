defmodule RadiatorWeb.EpisodeLive.Index do
  use RadiatorWeb, :live_view

  alias Radiator.Outline
  alias Radiator.Podcast
  alias RadiatorWeb.Endpoint

  @topic "outline"

  @impl true
  def mount(%{"show" => show_id}, _session, socket) do
    if connected?(socket) do
      Endpoint.subscribe(@topic)
    end

    show = Podcast.get_show!(show_id, preload: :episodes)

    socket
    |> assign(:page_title, show.title)
    # |> assign(:page_description, "")
    |> assign(:show, show)
    |> assign(:episodes, show.episodes)
    |> reply(:ok)
  end

  @impl true
  def handle_params(params, _uri, socket) do
    episode = get_selected_episode(params)

    socket
    |> assign(:selected_episode, episode)
    |> push_event("list", %{nodes: Outline.list_nodes()})
    |> reply(:noreply)
  end

  @impl true
  def handle_event("set_focus", _node_id, socket) do
    socket
    |> reply(:noreply)
  end

  def handle_event("remove_focus", _node_id, socket) do
    socket
    |> reply(:noreply)
  end

  def handle_event("create_node", %{"temp_id" => temp_id} = params, socket) do
    user = socket.assigns.current_user
    episode_id = socket.assigns.selected_episode.id
    attrs = Map.put(params, "episode_id", episode_id)

    socket =
      case Outline.create_node(attrs, user) do
        {:ok, node} -> socket |> push_event("update", Map.put(node, :temp_id, temp_id))
        _ -> socket
      end

    socket
    |> reply(:noreply)
  end

  def handle_event("update_node", %{"uuid" => uuid} = params, socket) do
    attrs = Map.merge(%{"parent_id" => nil, "prev_id" => nil}, params)

    case Outline.get_node(uuid) do
      nil -> nil
      node -> Outline.update_node(node, attrs)
    end

    socket
    |> reply(:noreply)
  end

  def handle_event("delete_node", node_id, socket) do
    node_id
    |> Outline.get_node!()
    |> Outline.delete_node()

    socket
    |> reply(:noreply)
  end

  @impl true
  def handle_info({:insert, _node}, socket) do
    socket
    # |> push_event("insert", node)
    |> reply(:noreply)
  end

  def handle_info({:update, _node}, socket) do
    socket
    # |> push_event("update", node)
    |> reply(:noreply)
  end

  def handle_info({:delete, _node}, socket) do
    socket
    # |> push_event("delete", node)
    |> reply(:noreply)
  end

  defp get_selected_episode(%{"episode" => episode_id}) do
    Podcast.get_episode!(episode_id)
  end

  defp get_selected_episode(%{"show" => show_id}) do
    Podcast.get_current_episode_for_show(show_id)
  end
end
