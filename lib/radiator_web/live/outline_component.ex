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

  alias RadiatorWeb.OutlineComponents

  @impl true
  def update(%{event: %NodeInsertedEvent{node: node, next_id: next_id}}, socket) do
    nodes =
      case NodeRepository.get_node_if(next_id) do
        nil -> [node]
        next_node -> [node, next_node]
      end

    node_forms = Enum.map(nodes, &to_change_form(&1, %{}))

    socket
    |> stream(:nodes, node_forms)
    |> reply(:ok)
  end

  def update(%{event: %NodeContentChangedEvent{node_id: node_id, content: content}}, socket) do
    node = NodeRepository.get_node!(node_id)

    socket
    |> stream_insert(:nodes, to_change_form(node, %{content: content}))
    |> reply(:ok)
  end

  def update(
        %{event: %NodeMovedEvent{node_id: node_id, old_next_id: old_next_id, next_id: next_id}},
        socket
      ) do
    node = NodeRepository.get_node!(node_id)
    old_next_node = NodeRepository.get_node_if(old_next_id)
    next_node = NodeRepository.get_node_if(next_id)

    nodes = [node, old_next_node, next_node] |> Enum.reject(&is_nil/1)
    node_forms = Enum.map(nodes, &to_change_form(&1, %{}))

    # what about your children ????

    socket
    |> stream(:nodes, node_forms)
    |> reply(:ok)
  end

  def update(
        %{event: %NodeDeletedEvent{node_id: node_id, next_id: next_id, children: children}},
        socket
      ) do
    nodes =
      case NodeRepository.get_node_if(next_id) do
        nil -> children
        next_node -> [next_node | children]
      end

    node_forms = Enum.map(nodes, &to_change_form(&1, %{}))

    socket
    |> stream_delete_by_dom_id(:nodes, "nodes-form-#{node_id}")
    |> stream(:nodes, node_forms)
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
  def handle_event("focus", %{"uuid" => uuid}, socket) do
    id = socket.assigns.user_id
    name = socket.assigns.user.email |> String.split("@") |> List.first()

    socket
    |> push_event("focus", %{uuid: uuid, user_id: id, user_name: name})
    |> reply(:noreply)
  end

  def handle_event("blur", %{"uuid" => uuid}, socket) do
    id = socket.assigns.user_id
    name = socket.assigns.user.email |> String.split("@") |> List.first()

    socket
    |> push_event("blur", %{uuid: uuid, user_id: id, user_name: name})
    |> reply(:noreply)
  end

  def handle_event("keydown", %{"key" => key, "uuid" => uuid, "value" => ""}, socket)
      when key in ["Backspace", "Delete", "Meta"] do
    user_id = socket.assigns.user_id
    Dispatch.delete_node(uuid, user_id, generate_event_id(socket.id))

    socket
    |> stream_delete_by_dom_id(:nodes, "nodes-form-#{uuid}")
    |> reply(:noreply)
  end

  def handle_event(
        "keydown",
        %{
          "key" => "Tab",
          "shiftKey" => false,
          "uuid" => uuid,
          "prev" => prev_id,
          "value" => content
        },
        socket
      ) do
    socket
    |> indent(uuid, prev_id, content)
    |> reply(:noreply)
  end

  def handle_event("keydown", %{"key" => "Tab", "shiftKey" => false}, socket) do
    socket
    |> reply(:noreply)
  end

  def handle_event(
        "keydown",
        %{
          "key" => "Tab",
          "shiftKey" => true,
          "uuid" => uuid,
          "parent" => parent_id,
          "value" => content
        },
        socket
      ) do
    socket
    |> outdent(uuid, parent_id, content)
    |> reply(:noreply)
  end

  def handle_event("keydown", %{"key" => "Tab", "shiftKey" => true}, socket) do
    socket
    |> reply(:noreply)
  end

  def handle_event("keydown", _params, socket) do
    socket
    |> reply(:noreply)
  end

  def handle_event("save", %{"uuid" => uuid, "node" => params}, socket) do
    user_id = socket.assigns.user_id
    Dispatch.change_node_content(uuid, params["content"], user_id, generate_event_id(socket.id))

    socket
    |> reply(:noreply)
  end

  def handle_event("new", %{"uuid" => uuid, "node" => _params}, socket) do
    new_uuid = Ecto.UUID.generate()
    user_id = socket.assigns.user_id
    episode_id = socket.assigns.episode_id

    params = %{
      "uuid" => new_uuid,
      "parent_id" => nil,
      "prev_id" => uuid,
      "creator_id" => user_id,
      "episode_id" => episode_id
    }

    new_node = %Node{
      uuid: new_uuid,
      parent_id: nil,
      prev_id: uuid
    }

    Dispatch.insert_node(params, user_id, generate_event_id(socket.id))

    socket
    |> stream_insert(:nodes, to_change_form(new_node, %{}))
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

  defp indent(socket, uuid, prev_id, content) do
    node = %Node{
      uuid: uuid,
      parent_id: prev_id,
      prev_id: nil,
      content: content
    }

    user_id = socket.assigns.user_id
    Dispatch.move_node(uuid, user_id, generate_event_id(socket.id), prev_node_id: prev_id)

    socket
    |> stream_insert(:nodes, to_change_form(node, %{}))
  end

  defp outdent(socket, uuid, parent_id, content) do
    node = %Node{
      uuid: uuid,
      parent_id: nil,
      prev_id: parent_id,
      content: content
    }

    user_id = socket.assigns.user_id
    Dispatch.move_node(uuid, user_id, generate_event_id(socket.id), parent_node_id: parent_id)

    socket
    |> stream_insert(:nodes, to_change_form(node, %{}))
  end
end
