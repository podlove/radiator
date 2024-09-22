defmodule RadiatorWeb.OutlineComponent do
  @moduledoc false
  use RadiatorWeb, :live_component

  alias Radiator.Outline
  alias Radiator.Outline.Dispatch

  alias Radiator.Outline.Event.{
    NodeContentChangedEvent,
    NodeDeletedEvent,
    NodeInsertedEvent,
    NodeMovedEvent
  }

  alias Radiator.Outline.Node
  alias Radiator.Outline.NodeRepository

  alias RadiatorWeb.Endpoint
  alias RadiatorWeb.OutlineComponents

  @impl true
  def update(%{event: %NodeInsertedEvent{node: node, next: nil}}, socket) do
    socket
    |> stream_insert(:nodes, to_change_form(node, %{}))
    |> reply(:ok)
  end

  def update(%{event: %NodeInsertedEvent{node: node, next: next_node}}, socket) do
    node_forms = Enum.map([node, next_node], &to_change_form(&1, %{}))

    socket
    |> stream(:nodes, node_forms)
    |> reply(:ok)
  end

  def update(%{event: %NodeContentChangedEvent{node_id: node_id, content: _content}}, socket) do
    node = NodeRepository.get_node!(node_id)

    socket
    |> stream_insert(:nodes, to_change_form(node, %{}))
    # |> push_event("set_content", %{uuid: node_id, content: content})
    |> reply(:ok)
  end

  def update(%{event: %NodeMovedEvent{}}, socket) do
    # nodes = [node, old_next_node, new_next_node] |> Enum.reject(&is_nil/1)
    # node_forms = Enum.map(nodes, &to_change_form(&1, %{}))

    socket
    # |> stream(:nodes, node_forms)
    # |> push_event("move_node", %{})
    |> reply(:ok)
  end

  def update(%{event: %NodeDeletedEvent{node: %{uuid: uuid}, next: nil}}, socket) do
    socket
    |> stream_delete_by_dom_id(:nodes, "nodes-form-#{uuid}")
    |> reply(:ok)
  end

  def update(%{event: %NodeDeletedEvent{node: %{uuid: uuid}, next: next}}, socket) do
    socket
    |> stream_delete_by_dom_id(:nodes, "nodes-form-#{uuid}")
    |> stream_insert(:nodes, to_change_form(next, %{}))
    |> reply(:ok)
  end

  def update(%{event: %Phoenix.Socket.Broadcast{event: event, payload: payload}}, socket)
      when event in ["focus", "blur"] do
    socket
    |> push_event(event, payload)
    |> reply(:ok)
  end

  def update(%{episode_id: id} = assigns, socket) do
    nodes = Outline.list_nodes_by_episode_sorted(id)
    node_forms = Enum.map(nodes, &to_change_form(&1, %{}))

    socket
    |> assign(assigns)
    # |> stream_configure(:nodes, dom_id: &"outline-node-#{&1.data.uuid}")
    |> stream(:nodes, node_forms)
    |> reply(:ok)
  end

  @impl true
  def handle_event("save", %{"node" => %{"uuid" => uuid, "content" => content}}, socket) do
    user_id = socket.assigns.user_id
    Dispatch.change_node_content(uuid, content, user_id, generate_event_id(socket.id))

    socket
    |> reply(:noreply)
  end

  def handle_event("new", %{"node" => %{"uuid" => uuid}}, socket) do
    new_uuid = Ecto.UUID.generate()
    user_id = socket.assigns.user_id
    episode_id = socket.assigns.episode_id

    params = %{"uuid" => new_uuid, "prev_id" => uuid, "episode_id" => episode_id}

    Dispatch.insert_node(params, user_id, generate_event_id(socket.id))

    socket
    |> reply(:noreply)
  end

  def handle_event("focus", %{"uuid" => uuid}, socket) do
    id = socket.assigns.user_id
    [name | _] = String.split(socket.assigns.user.email, "@")

    Endpoint.broadcast("outline", "focus", %{uuid: uuid, user_id: id, user_name: name})

    socket
    |> reply(:noreply)
  end

  def handle_event("blur", %{"uuid" => uuid}, socket) do
    id = socket.assigns.user_id
    [name | _] = String.split(socket.assigns.user.email, "@")

    Endpoint.broadcast("outline", "blur", %{uuid: uuid, user_id: id, user_name: name})

    socket
    |> reply(:noreply)
  end

  def handle_event("keydown", %{"key" => key, "uuid" => uuid, "value" => ""}, socket)
      when key in ["Backspace", "Delete"] do
    user_id = socket.assigns.user_id
    Dispatch.delete_node(uuid, user_id, generate_event_id(socket.id))

    socket
    |> stream_delete_by_dom_id(:nodes, "nodes-form-#{uuid}")
    |> reply(:noreply)
  end

  def handle_event(
        "keydown",
        %{"key" => "ArrowUp", "altKey" => true, "uuid" => uuid, "prev" => _},
        socket
      ) do
    socket
    |> move_up(uuid)
    |> reply(:noreply)
  end

  def handle_event(
        "keydown",
        %{"key" => "ArrowDown", "altKey" => true, "uuid" => uuid},
        socket
      ) do
    socket
    |> move_down(uuid)
    |> reply(:noreply)
  end

  def handle_event(
        "keydown",
        %{"key" => "Tab", "shiftKey" => false, "uuid" => uuid, "prev" => _},
        socket
      ) do
    socket
    |> indent(uuid)
    |> reply(:noreply)
  end

  def handle_event(
        "keydown",
        %{"key" => "Tab", "shiftKey" => true, "uuid" => uuid, "parent" => _},
        socket
      ) do
    socket
    |> outdent(uuid)
    |> reply(:noreply)
  end

  def handle_event("keydown", _params, socket) do
    socket
    |> reply(:noreply)
  end

  defp to_change_form(node_or_changeset, params, action \\ nil) do
    changeset =
      node_or_changeset
      |> Node.insert_changeset(params)
      |> Map.put(:action, action)

    to_form(changeset, as: "node", id: "form-#{changeset.data.uuid}")
  end

  defp generate_event_id(id), do: Ecto.UUID.generate() <> ":" <> id

  defp move_up(socket, uuid) do
    user_id = socket.assigns.user_id

    Dispatch.move_up(uuid, user_id, generate_event_id(socket.id))
    socket
  end

  defp move_down(socket, uuid) do
    user_id = socket.assigns.user_id

    Dispatch.move_down(uuid, user_id, generate_event_id(socket.id))
    socket
  end

  defp indent(socket, uuid) do
    user_id = socket.assigns.user_id
    Dispatch.indent_node(uuid, user_id, generate_event_id(socket.id))

    socket
  end

  defp outdent(socket, uuid) do
    user_id = socket.assigns.user_id
    Dispatch.outdent_node(uuid, user_id, generate_event_id(socket.id))

    socket
  end
end
