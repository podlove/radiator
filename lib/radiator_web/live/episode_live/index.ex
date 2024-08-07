defmodule RadiatorWeb.EpisodeLive.Index do
  use RadiatorWeb, :live_view

  alias Radiator.Outline
  alias Radiator.Outline.Dispatch

  alias Radiator.Outline.Event.{
    NodeContentChangedEvent,
    NodeDeletedEvent,
    NodeInsertedEvent,
    NodeMovedEvent
  }

  alias Radiator.Outline.NodeRepository
  # alias Radiator.EventStore
  alias Radiator.Podcast
  alias Radiator.Podcast.Episode

  alias RadiatorWeb.OutlineComponents

  @impl true
  def mount(%{"show" => show_id} = params, _session, socket) do
    show = Podcast.get_show!(show_id, preload: :episodes)
    episode = get_selected_episode(params)

    socket
    |> assign(:page_title, show.title)
    # |> assign(:page_description, "")
    |> assign(:show, show)
    |> assign(:episodes, show.episodes)
    |> assign(action: nil, episode: nil, form: nil)
    |> stream_configure(:event_logs, dom_id: & &1.uuid)
    |> stream(:event_logs, get_event_logs(episode))
    |> reply(:ok)
  end

  @impl true
  def handle_params(params, _uri, socket) do
    episode = get_selected_episode(params)
    nodes = get_nodes(episode)

    # would need to unsubscribe from previous episode,
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
    changeset = Episode.changeset(socket.assigns.episode, params)

    socket
    |> assign(:form, to_form(changeset, action: :validate))
    |> reply(:noreply)
  end

  def handle_event("save", %{"episode" => params}, socket) do
    params
    |> Map.put("show_id", socket.assigns.show.id)
    |> Podcast.create_episode()
    |> process_create_episode(socket)
  end

  @impl true
  def handle_info(%{uuid: <<_::binary-size(36)>> <> ":" <> id} = event, %{id: id} = socket) do
    id =
      case event do
        %{node: %{uuid: id}} -> id
        %{node_id: id} -> id
      end

    payload = %{node: %{uuid: id}}

    socket
    |> push_event("clean", payload)
    |> stream_event(event)
    |> reply(:noreply)
  end

  def handle_info(
        %NodeInsertedEvent{node: node, next_id: next_id} = event,
        socket
      ) do
    payload = %{node: node, next_id: next_id}

    socket
    |> push_event("insert", payload)
    |> stream_event(event)
    |> reply(:noreply)
  end

  def handle_info(
        %NodeContentChangedEvent{node_id: id, content: content} = event,
        socket
      ) do
    payload = %{node: %{uuid: id, content: content}}

    socket
    |> push_event("change_content", payload)
    |> stream_event(event)
    |> reply(:noreply)
  end

  def handle_info(
        %NodeMovedEvent{node_id: id, parent_id: parent_id, prev_id: prev_id} =
          event,
        socket
      ) do
    payload = %{node: %{uuid: id, parent_id: parent_id, prev_id: prev_id}}

    socket
    |> push_event("move", payload)
    |> stream_event(event)
    |> reply(:noreply)
  end

  def handle_info(%NodeDeletedEvent{node_id: id} = event, socket) do
    payload = %{node: %{uuid: id}}

    socket
    |> push_event("delete", payload)
    |> stream_event(event)
    |> reply(:noreply)
  end

  defp get_selected_episode(%{"episode" => episode_id}) do
    Podcast.get_episode!(episode_id)
  end

  defp get_selected_episode(%{"show" => show_id}) do
    Podcast.get_current_episode_for_show(show_id)
  end

  def get_event_logs(nil), do: []

  def get_event_logs(_episode) do
    # EventStore.list_event_data_by_episode(episode.id)
    []
  end

  defp get_nodes(%{id: id}), do: Outline.list_nodes_by_episode_sorted(id)
  defp get_nodes(_), do: []

  defp generate_event_id(id), do: Ecto.UUID.generate() <> ":" <> id

  defp stream_event(socket, event) do
    socket
    |> stream_insert(:event_logs, event, at: 0)
  end

  defp process_create_episode({:ok, episode}, socket) do
    show = Podcast.get_show!(socket.assigns.show.id, preload: :episodes)

    NodeRepository.create_node(%{
      "uuid" => Ecto.UUID.generate(),
      "creator_id" => socket.assigns.current_user.id,
      "episode_id" => episode.id
    })

    socket
    |> assign(:action, nil)
    |> assign(:episodes, show.episodes)
    |> put_flash(:info, "Episode created successfully")
    |> push_navigate(to: ~p"/admin/podcast/#{show}/#{episode}")
    |> reply(:noreply)
  end

  defp process_create_episode({:error, %Ecto.Changeset{} = changeset}, socket) do
    socket
    |> assign(:form, to_form(changeset))
    |> put_flash(:info, "Episode could not be created")
    |> reply(:noreply)
  end
end
