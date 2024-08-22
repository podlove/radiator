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

  # alias Radiator.Outline.Node

  @impl true
  def update(%{event: %NodeInsertedEvent{node: node, next_id: next_id}}, socket) do
    payload = %{node: node, next_id: next_id}

    socket
    |> push_event("insert", payload)
    # |> stream_insert(:nodes, to_change_form(node, %{}))
    |> reply(:ok)
  end

  def update(%{event: %NodeContentChangedEvent{node_id: id, content: content}}, socket) do
    payload = %{node: %{uuid: id, content: content}}

    socket
    |> push_event("change_content", payload)
    # |> stream_insert(:nodes, to_change_form(node, %{}))
    |> reply(:ok)
  end

  def update(
        %{event: %NodeMovedEvent{node_id: id, parent_id: parent_id, prev_id: prev_id}},
        socket
      ) do
    payload = %{node: %{uuid: id, parent_id: parent_id, prev_id: prev_id}}

    socket
    |> push_event("move", payload)
    # |> stream_insert(:nodes, to_change_form(node, %{}), at: node.position)
    |> reply(:ok)
  end

  def update(%{event: %NodeDeletedEvent{node_id: id}}, socket) do
    payload = %{node: %{uuid: id}}

    socket
    |> push_event("delete", payload)
    # |> stream_delete(:nodes, to_change_form(node, %{}))
    |> reply(:ok)
  end

  def update(%{episode_id: id} = assigns, socket) do
    nodes = get_nodes(id)
    # node_forms = Enum.map(nodes, &to_change_form(&1, %{}))

    socket
    |> assign(assigns)
    |> stream_configure(:nodes, dom_id: &"outline-node-#{&1.uuid}")
    |> stream(:nodes, nodes)
    # |> stream_configure(:nodes_new, dom_id: &"outline-node-#{&1.uuid}")
    # |> stream(:nodes_new, node_forms)
    |> reply(:ok)
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

  def handle_event("set_collapsed", _node_id, socket) do
    socket
    |> reply(:noreply)
  end

  def handle_event("set_expanded", _node_id, socket) do
    socket
    |> reply(:noreply)
  end

  def handle_event("create_node", params, socket) do
    user_id = socket.assigns.user_id
    episode_id = socket.assigns.episode_id
    attrs = Map.merge(params, %{"creator_id" => user_id, "episode_id" => episode_id})

    Dispatch.insert_node(attrs, user_id, generate_event_id(socket.id))

    socket
    |> reply(:noreply)
  end

  def handle_event("update_node_content", %{"uuid" => uuid, "content" => content}, socket) do
    user_id = socket.assigns.user_id

    Dispatch.change_node_content(uuid, content, user_id, generate_event_id(socket.id))

    socket
    |> reply(:noreply)
  end

  def handle_event("move_node", %{"uuid" => uuid} = node, socket) do
    user_id = socket.assigns.user_id

    Dispatch.move_node(
      uuid,
      node["parent_id"],
      node["prev_id"],
      user_id,
      generate_event_id(socket.id)
    )

    socket
    |> reply(:noreply)
  end

  def handle_event("delete_node", %{"uuid" => uuid}, socket) do
    user_id = socket.assigns.user_id

    Dispatch.delete_node(uuid, user_id, generate_event_id(socket.id))

    socket
    |> reply(:noreply)
  end

  defp get_nodes(id), do: Outline.list_nodes_by_episode_sorted(id)

  # defp to_change_form(node_or_changeset, params, action \\ nil) do
  #   changeset =
  #     node_or_changeset
  #     |> Node.insert_changeset(params)
  #     |> Map.put(:action, action)

  #   to_form(changeset, as: "node", id: "form-#{changeset.data.uuid}")
  # end

  defp generate_event_id(id), do: Ecto.UUID.generate() <> ":" <> id
end
