defmodule RadiatorWeb.EpisodeLive.Index do
  use RadiatorWeb, :live_view

  alias Radiator.Outline.{Dispatch, NodeRepository}
  alias Radiator.Outline.Event.{NodeContentChangedEvent, NodeInsertedEvent}
  alias Radiator.Podcast

  @impl true
  def mount(%{"show" => show_id}, _session, socket) do
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

    # would need to unsucbscribe from previous episode,
    # better: load new liveview
    if connected?(socket) and episode do
      Dispatch.subscribe(episode.id)
    end

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

  def handle_event("create_node", params, socket) do
    user = socket.assigns.current_user
    episode = socket.assigns.selected_episode
    attrs = Map.merge(params, %{"creator_id" => user.id, "episode_id" => episode.id})

    Dispatch.insert_node(attrs, user.id, generate_event_id(socket.id))

    socket
    |> reply(:noreply)
  end

  # seperate update content & move node in frontent/js
  def handle_event("update_node", %{"uuid" => uuid, "content" => content}, socket) do
    user = socket.assigns.current_user

    Dispatch.change_node_content(uuid, content, user.id, generate_event_id(socket.id))

    socket
    |> reply(:noreply)
  end

  def handle_event("delete_node", %{"uuid" => _uuid}, socket) do
    _event_id = generate_event_id(socket.id)

    # case NodeRepository.get_node(uuid) do
    #   nil -> nil
    #   node -> Outline.remove_node(node, socket.id)
    # end

    socket
    |> reply(:noreply)
  end

  @impl true
  def handle_info(
        %{node: node, event_id: <<_::binary-size(36)>> <> ":" <> id},
        %{id: id} = socket
      ) do
    socket
    |> push_event("clean", %{node: node})
    |> reply(:noreply)
  end

  def handle_info(%NodeInsertedEvent{node: node}, socket) do
    socket
    |> push_event("insert", %{node: node})
    |> reply(:noreply)
  end

  def handle_info(
        %NodeContentChangedEvent{node_id: id, content: content},
        socket
      ) do
    socket
    |> push_event("update", %{node: %{id: id, content: content}})
    |> reply(:noreply)
  end

  def handle_info({:update, node}, socket) do
    socket
    |> push_event("update", %{node: node})
    |> reply(:noreply)
  end

  def handle_info({:delete, node}, socket) do
    socket
    |> push_event("delete", %{node: node})
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

  defp generate_event_id(id), do: Ecto.UUID.generate() <> ":" <> id
end
