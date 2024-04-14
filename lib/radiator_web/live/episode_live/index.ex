defmodule RadiatorWeb.EpisodeLive.Index do
  use RadiatorWeb, :live_view

  alias Radiator.Outline
  alias Radiator.Outline.NodeRepository
  alias Radiator.Podcast
  alias RadiatorWeb.Endpoint

  @topic "outline-node"

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
    nodes = get_nodes(episode)

    socket
    |> assign(:selected_episode, episode)
    |> push_event("list", %{nodes: nodes})
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
    episode = socket.assigns.selected_episode
    attrs = Map.merge(params, %{"creator_id" => user.id, "episode_id" => episode.id})

    case Outline.insert_node(attrs) do
      {:ok, node} -> socket |> reply(:reply, Map.put(node, :temp_id, temp_id))
      _ -> socket |> reply(:noreply)
    end
  end

  def handle_event("update_node", %{"uuid" => uuid} = params, socket) do
    attrs = Map.merge(%{"parent_id" => nil, "prev_id" => nil}, params)

    case NodeRepository.get_node(uuid) do
      nil -> nil
      node -> Outline.update_node_content(node, attrs, socket.id)
    end

    socket
    |> reply(:noreply)
  end

  def handle_event("delete_node", %{"uuid" => uuid}, socket) do
    case NodeRepository.get_node(uuid) do
      nil -> nil
      node -> Outline.remove_node(node, socket.id)
    end

    socket
    |> reply(:noreply)
  end

  @impl true
  def handle_info({_, _node, socket_id}, socket) when socket_id == socket.id do
    socket
    |> reply(:noreply)
  end

  def handle_info({:insert, node, _socket_id}, socket) do
    socket
    |> push_event("insert", node)
    |> reply(:noreply)
  end

  def handle_info({:update, node, _socket_id}, socket) do
    socket
    |> push_event("update", node)
    |> reply(:noreply)
  end

  def handle_info({:delete, node, _socket_id}, socket) do
    socket
    |> push_event("delete", node)
    |> reply(:noreply)
  end

  defp get_selected_episode(%{"episode" => episode_id}) do
    Podcast.get_episode!(episode_id)
  end

  defp get_selected_episode(%{"show" => show_id}) do
    Podcast.get_current_episode_for_show(show_id)
  end

  defp get_nodes(%{id: id}), do: NodeRepository.list_nodes_by_episode(id)
  defp get_nodes(_), do: []
end
