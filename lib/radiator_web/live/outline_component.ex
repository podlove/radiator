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
  def update(%{event: %NodeInsertedEvent{node: %{uuid: uuid}}} = _event, socket) do
    node = NodeRepository.get_node!(uuid)

    socket
    |> stream_insert(:nodes, to_change_form(node, %{}))
    |> reply(:ok)
  end

  def update(%{event: %NodeContentChangedEvent{node_id: uuid}} = _event, socket) do
    node = NodeRepository.get_node!(uuid)

    socket
    |> stream_insert(:nodes, to_change_form(node, %{}))
    |> reply(:ok)
  end

  def update(%{event: %NodeMovedEvent{node_id: uuid}} = _event, socket) do
    node = NodeRepository.get_node!(uuid)

    socket
    |> stream_insert(:nodes, to_change_form(node, %{}))
    |> reply(:ok)
  end

  def update(%{event: %NodeDeletedEvent{node_id: uuid}}, socket) do
    node = %Node{uuid: uuid}

    socket
    |> stream_delete(:nodes, to_change_form(node, %{}))
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
  def handle_event("focus", %{"uuid" => _uuid}, socket) do
    socket
    |> reply(:noreply)
  end

  def handle_event("blur", %{"uuid" => _uuid}, socket) do
    socket
    |> reply(:noreply)
  end

  def handle_event("toggle_collapse", %{"uuid" => _uuid}, socket) do
    socket
    |> reply(:noreply)
  end

  def handle_event("keydown", %{"key" => key, "uuid" => uuid, "value" => ""}, socket)
      when key in ["Backspace", "Delete", "Meta"] do
    node = NodeRepository.get_node!(uuid)

    user_id = socket.assigns.user_id
    Dispatch.delete_node(uuid, user_id, generate_event_id(socket.id))

    socket
    |> stream_delete(:nodes, to_change_form(node, %{}))
    |> reply(:noreply)
  end

  def handle_event("keydown", _params, socket) do
    socket
    |> reply(:noreply)
  end

  def handle_event("save", %{"uuid" => uuid, "node" => params}, socket) do
    node = NodeRepository.get_node!(uuid)

    user_id = socket.assigns.user_id
    Dispatch.change_node_content(uuid, params["content"], user_id, generate_event_id(socket.id))

    socket
    |> stream_insert(:nodes, to_change_form(node, params, :validate))
    |> reply(:noreply)
  end

  def handle_event("new", %{"uuid" => uuid, "node" => _params}, socket) do
    node = NodeRepository.get_node!(uuid)

    new_uuid = Ecto.UUID.generate()
    user_id = socket.assigns.user_id
    episode_id = socket.assigns.episode_id

    params = %{
      "uuid" => new_uuid,
      "parent_id" => node.parent_id,
      "prev_id" => node.uuid,
      "creator_id" => user_id,
      "episode_id" => episode_id
    }

    new_node = %Node{uuid: new_uuid}

    Dispatch.insert_node(params, user_id, generate_event_id(socket.id))

    socket
    |> stream_insert(:nodes, to_change_form(new_node, params))
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
end
