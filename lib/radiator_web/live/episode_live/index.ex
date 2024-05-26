defmodule RadiatorWeb.EpisodeLive.Index do
  use RadiatorWeb, :live_view

  alias Radiator.Outline.{Dispatch, NodeRepository}

  alias Radiator.Outline.Event.{
    NodeContentChangedEvent,
    NodeDeletedEvent,
    NodeInsertedEvent,
    NodeMovedEvent
  }

  alias Radiator.Podcast
  alias Radiator.Podcast.Episode

  @impl true
  def mount(%{"show" => show_id}, _session, socket) do
    show = Podcast.get_show!(show_id, preload: :episodes)

    socket
    |> assign(:page_title, show.title)
    # |> assign(:page_description, "")
    |> assign(:show, show)
    |> assign(:episodes, show.episodes)
    |> assign(action: nil, episode: nil, form: nil)
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

  def handle_event("update_node_content", %{"uuid" => uuid, "content" => content}, socket) do
    user = socket.assigns.current_user

    Dispatch.change_node_content(uuid, content, user.id, generate_event_id(socket.id))

    socket
    |> reply(:noreply)
  end

  def handle_event("move_node", %{"uuid" => uuid} = node, socket) do
    user = socket.assigns.current_user

    Dispatch.move_node(
      uuid,
      node["parent_id"],
      node["prev_id"],
      user.id,
      generate_event_id(socket.id)
    )

    socket
    |> reply(:noreply)
  end

  def handle_event("delete_node", %{"uuid" => uuid}, socket) do
    user = socket.assigns.current_user

    Dispatch.delete_node(uuid, user.id, generate_event_id(socket.id))

    socket
    |> reply(:noreply)
  end

  def handle_event("new_episode", _params, socket) do
    show = socket.assigns.show
    number = Podcast.get_next_episode_number(show.id)

    episode = %Podcast.Episode{}
    changeset = Episode.changeset(episode, %{number: number})

    socket
    |> assign(:action, :new_episode)
    |> assign(:episode, episode)
    |> assign(:form, to_form(changeset))
    |> reply(:noreply)
  end

  def handle_event("validate", %{"episode" => params}, socket) do
    changeset = socket.assigns.episode |> Episode.changeset(params) |> Map.put(:action, :validate)

    socket
    |> assign(:form, to_form(changeset))
    |> reply(:noreply)
  end

  def handle_event("save", %{"episode" => params}, socket) do
    show_id = socket.assigns.show.id

    params = Map.put(params, "show_id", show_id)

    case Podcast.create_episode(params) do
      {:ok, episode} ->
        show = Podcast.get_show!(show_id, preload: :episodes)

        socket
        |> assign(:action, nil)
        |> assign(:episodes, show.episodes)
        |> put_flash(:info, "Episode created successfully")
        |> push_patch(to: ~p"/admin/podcast/#{show}/#{episode}")
        |> reply(:noreply)

      {:error, %Ecto.Changeset{} = changeset} ->
        socket
        |> assign(:form, to_form(changeset))
        |> put_flash(:info, "Episode could not be created")
        |> reply(:noreply)
    end
  end

  @impl true
  def handle_info(%{event_id: <<_::binary-size(36)>> <> ":" <> id} = payload, %{id: id} = socket) do
    id =
      case payload do
        %{node: %{uuid: id}} -> id
        %{node_id: id} -> id
      end

    socket
    |> push_event("clean", %{node: %{uuid: id}})
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
    |> push_event("change_content", %{node: %{uuid: id, content: content}})
    |> reply(:noreply)
  end

  def handle_info(
        %NodeMovedEvent{node_id: id, parent_id: parent_id, prev_id: prev_id},
        socket
      ) do
    socket
    |> push_event("move", %{node: %{uuid: id, parent_id: parent_id, prev_id: prev_id}})
    |> reply(:noreply)
  end

  def handle_info(%NodeDeletedEvent{node_id: id}, socket) do
    socket
    |> push_event("delete", %{node: %{uuid: id}})
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
