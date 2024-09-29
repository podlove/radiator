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

  alias RadiatorWeb.Endpoint
  alias RadiatorWeb.OutlineComponents

  @impl true
  def update(%{event: %NodeInsertedEvent{event_id: event_id, node: node, next: nil}}, socket) do
    action = get_action(socket.id, event_id)

    socket
    |> stream_insert(:nodes, to_change_form(node, %{}, action))
    |> reply(:ok)
  end

  def update(%{event: %NodeInsertedEvent{event_id: event_id, node: node, next: next}}, socket) do
    action = get_action(socket.id, event_id)

    socket
    |> stream_insert(:nodes, to_change_form(node, %{}, action))
    |> push_event("move_nodes", %{nodes: [next]})
    |> reply(:ok)
  end

  def update(%{event: %NodeContentChangedEvent{node_id: node_id, content: content}}, socket) do
    socket
    |> push_event("set_content", %{uuid: node_id, content: content})
    |> reply(:ok)
  end

  def update(
        %{
          event: %NodeMovedEvent{
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
    |> push_event("focus_node", %{uuid: node.uuid})
    |> reply(:ok)
  end

  def update(
        %{
          event: %NodeMovedEvent{
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

  def update(%{event: %Phoenix.Socket.Broadcast{event: event, payload: _payload}}, socket)
      when event in ["focus", "blur"] do
    socket
    # |> push_event(event, payload)
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

  def handle_event("new", _params, socket) do
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

  def handle_event(
        "keydown",
        %{"key" => "Enter", "uuid" => uuid, "value" => value, "selection" => selection},
        socket
      ) do
    {first, _} = String.split_at(value, selection["start"])
    {_, last} = String.split_at(value, selection["end"])

    user_id = socket.assigns.user_id
    Dispatch.change_node_content(uuid, first, user_id, generate_event_id(socket.id))

    episode_id = socket.assigns.episode_id

    params = %{
      "prev_id" => uuid,
      "content" => last,
      "episode_id" => episode_id
    }

    Dispatch.insert_node(params, user_id, generate_event_id(socket.id))

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
    user_id = socket.assigns.user_id
    Dispatch.move_up(uuid, user_id, generate_event_id(socket.id))

    socket
    |> reply(:noreply)
  end

  def handle_event(
        "keydown",
        %{"key" => "ArrowDown", "altKey" => true, "uuid" => uuid},
        socket
      ) do
    user_id = socket.assigns.user_id
    Dispatch.move_down(uuid, user_id, generate_event_id(socket.id))

    socket
    |> reply(:noreply)
  end

  def handle_event(
        "keydown",
        %{"key" => "Tab", "shiftKey" => false, "uuid" => uuid},
        socket
      ) do
    user_id = socket.assigns.user_id
    Dispatch.indent_node(uuid, user_id, generate_event_id(socket.id))

    socket
    |> reply(:noreply)
  end

  def handle_event(
        "keydown",
        %{"key" => "Tab", "shiftKey" => true, "uuid" => uuid},
        socket
      ) do
    user_id = socket.assigns.user_id
    Dispatch.outdent_node(uuid, user_id, generate_event_id(socket.id))

    socket
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

  defp get_action(id, <<_::binary-size(36)>> <> ":" <> id), do: :self
  defp get_action(_id, _event_id), do: nil

  defp generate_event_id(id), do: Ecto.UUID.generate() <> ":" <> id
end
