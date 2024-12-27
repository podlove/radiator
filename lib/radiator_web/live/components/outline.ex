defmodule RadiatorWeb.Components.Outline do
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

  alias RadiatorWeb.Endpoint
  alias RadiatorWeb.OutlineComponents

  @impl true
  def update(%{event: %NodeInsertedEvent{event_id: event_id, node: node}}, socket) do
    socket
    |> stream_insert(:nodes, to_change_form(node, %{}))
    |> focus_self(node.uuid, event_id)
    |> reply(:ok)
  end

  def update(
        %{event: %NodeContentChangedEvent{event_id: <<_::binary-size(36)>> <> ":" <> id}},
        %{id: id} = socket
      ),
      do: socket |> reply(:ok)

  def update(%{event: %NodeContentChangedEvent{node_id: node_id, content: content}}, socket) do
    socket
    |> push_event("set_content", %{uuid: node_id, content: content})
    |> reply(:ok)
  end

  def update(
        %{
          event: %NodeMovedEvent{
            event_id: event_id,
            node: node,
            next: next,
            old_prev: old_prev,
            old_next: old_next,
            children: nil
          }
        },
        socket
      ) do
    nodes = [node, next, old_prev, old_next] |> Enum.reject(&is_nil/1)

    socket
    |> push_event("move_nodes", %{nodes: nodes})
    |> focus_self(node.uuid, event_id)
    |> reply(:ok)
  end

  def update(
        %{
          event: %NodeMovedEvent{
            event_id: event_id,
            node: node,
            next: next,
            old_prev: old_prev,
            old_next: old_next,
            children: children
          }
        },
        socket
      ) do
    nodes = ([node, next, old_prev, old_next] ++ children) |> Enum.reject(&is_nil/1)

    socket
    |> push_event("move_nodes", %{nodes: nodes})
    |> focus_self(node.uuid, event_id)
    |> reply(:ok)
  end

  def update(%{event: %NodeDeletedEvent{node: %{uuid: uuid}, next: nil}}, socket) do
    socket
    |> stream_delete_by_dom_id(:nodes, "nodes-form-#{uuid}")
    |> reply(:ok)
  end

  def update(%{event: %NodeDeletedEvent{node: %{uuid: uuid}, next: next}}, socket) do
    socket
    |> push_event("move_nodes", %{nodes: [next]})
    |> stream_delete_by_dom_id(:nodes, "nodes-form-#{uuid}")
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
  def handle_event("noop", _params, socket) do
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

  def handle_event("save", %{"uuid" => uuid, "content" => content}, socket) do
    user_id = socket.assigns.user_id
    Dispatch.change_node_content(uuid, content, user_id, generate_event_id(socket.id))

    socket
    |> reply(:noreply)
  end

  def handle_event("split", %{"uuid" => uuid, "start" => start, "stop" => stop}, socket) do
    user_id = socket.assigns.user_id
    Dispatch.split_node(uuid, {start, stop}, user_id, generate_event_id(socket.id))

    socket
    |> reply(:noreply)
  end

  def handle_event("merge_prev", %{"uuid" => uuid, "content" => content}, socket) do
    prev_node = Outline.get_node_above(uuid)

    if prev_node do
      user_id = socket.assigns.user_id

      Dispatch.change_node_content(
        prev_node.uuid,
        "#{prev_node.content}#{content}",
        user_id,
        generate_event_id(socket.id)
      )

      Dispatch.delete_node(uuid, user_id, generate_event_id(socket.id))
    end

    socket
    |> reply(:noreply)
  end

  def handle_event("merge_next", %{"uuid" => uuid, "content" => content}, socket) do
    next_node = Outline.get_node_below(uuid)

    if next_node do
      user_id = socket.assigns.user_id

      Dispatch.change_node_content(
        uuid,
        "#{content}#{next_node.content}",
        user_id,
        generate_event_id(socket.id)
      )

      Dispatch.delete_node(next_node.uuid, user_id, generate_event_id(socket.id))
    end

    socket
    |> reply(:noreply)
  end

  def handle_event("move_up", %{"uuid" => uuid}, socket) do
    user_id = socket.assigns.user_id
    Dispatch.move_up(uuid, user_id, generate_event_id(socket.id))

    socket
    |> reply(:noreply)
  end

  def handle_event("move_down", %{"uuid" => uuid}, socket) do
    user_id = socket.assigns.user_id
    Dispatch.move_down(uuid, user_id, generate_event_id(socket.id))

    socket
    |> reply(:noreply)
  end

  def handle_event("move", %{"uuid" => uuid} = params, socket) do
    user_id = socket.assigns.user_id

    Dispatch.move_node(uuid, user_id, generate_event_id(socket.id),
      parent_id: params["parent_id"],
      prev_id: params["prev_id"]
    )

    socket
    |> reply(:noreply)
  end

  def handle_event("delete", %{"uuid" => uuid}, socket) do
    user_id = socket.assigns.user_id
    Dispatch.delete_node(uuid, user_id, generate_event_id(socket.id))

    socket
    |> reply(:noreply)
  end

  def handle_event("indent", %{"uuid" => uuid}, socket) do
    user_id = socket.assigns.user_id
    Dispatch.indent_node(uuid, user_id, generate_event_id(socket.id))

    socket
    |> reply(:noreply)
  end

  def handle_event("outdent", %{"uuid" => uuid}, socket) do
    user_id = socket.assigns.user_id
    Dispatch.outdent_node(uuid, user_id, generate_event_id(socket.id))

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

  defp focus_self(%{id: id} = socket, uuid, <<_::binary-size(36)>> <> ":" <> id) do
    socket
    |> push_event("focus_node", %{uuid: uuid})
  end

  defp focus_self(socket, _uuid, _event_id), do: socket

  defp generate_event_id(id), do: Ecto.UUID.generate() <> ":" <> id
end
