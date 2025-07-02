defmodule RadiatorWeb.OutlineLive.Index do
  use RadiatorWeb, :live_view

  alias Phoenix.Socket.Broadcast

  alias Radiator.Accounts
  alias Radiator.Outline
  alias Radiator.Outline.Dispatch
  alias Radiator.Outline.NodeRepository

  alias Radiator.Outline.Event.{
    NodeContentChangedEvent,
    NodeDeletedEvent,
    NodeInsertedEvent,
    NodeMovedEvent,
    NodeMovedToNewContainer
  }

  alias Radiator.Outline.Node

  alias RadiatorWeb.Endpoint
  alias RadiatorWeb.OutlineComponents

  @impl true
  def mount(_params, %{"container_id" => container_id, "user_id" => user_id} = session, socket) do
    Dispatch.subscribe(container_id)
    RadiatorWeb.Endpoint.subscribe("outline")

    nodes = Outline.list_nodes_by_container_sorted(container_id)
    node_forms = Enum.map(nodes, &to_change_form(&1, %{}))

    socket
    |> assign(:id, "outline-#{container_id}")
    |> assign(:container_id, container_id)
    |> assign(:user_id, user_id)
    |> assign(:readonly, Map.get(session, "readonly", false))
    |> assign(:group, "outline")
    # |> stream_configure(:nodes, dom_id: &"outline-node-#{&1.data.uuid}")
    |> stream(:nodes, node_forms)
    |> reply(:ok)
  end

  def mount(%{"container" => container_id} = params, session, socket) do
    email = "#{socket.id}@radiator.metaebene.net"

    {:ok, %{id: user_id}} =
      case Accounts.get_user_by_email(email) do
        nil -> Accounts.register_user(%{email: email, password: :crypto.strong_rand_bytes(32)})
        user -> {:ok, user}
      end

    new_session = Map.merge(session, %{"container_id" => container_id, "user_id" => user_id})
    mount(params, new_session, socket)
  end

  def mount(_params, _session, socket) do
    {:ok, container} = Radiator.Outline.create_node_container()

    {:ok, node1} =
      NodeRepository.create_node(%{
        "content" => "Node 1",
        "container_id" => container.id
      })

    {:ok, _node11} =
      NodeRepository.create_node(%{
        "content" => "Node 1.1",
        "container_id" => container.id,
        "parent_id" => node1.uuid
      })

    {:ok, _node2} =
      NodeRepository.create_node(%{
        "content" => "Node 2",
        "container_id" => container.id,
        "prev_id" => node1.uuid
      })

    socket
    |> redirect(to: ~p"/outline/#{container}")
    |> reply(:ok)
  end

  @impl true
  def handle_event("noop", _params, socket) do
    socket
    |> reply(:noreply)
  end

  def handle_event("focus", %{"uuid" => uuid}, socket) do
    id = socket.assigns.user_id
    # [name | _] = String.split(socket.assigns.user.email, "@")

    Endpoint.broadcast("outline", "focus", %{uuid: uuid, user_id: id, user_name: id})

    socket
    |> reply(:noreply)
  end

  def handle_event("blur", %{"uuid" => uuid}, socket) do
    id = socket.assigns.user_id
    # [name | _] = String.split(socket.assigns.user.email, "@")

    Endpoint.broadcast("outline", "blur", %{uuid: uuid, user_id: id, user_name: id})

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

  def handle_event("merge_prev", %{"uuid" => uuid}, socket) do
    user_id = socket.assigns.user_id
    Dispatch.merge_prev(uuid, user_id, generate_event_id(socket.id))

    socket
    |> reply(:noreply)
  end

  def handle_event("merge_next", %{"uuid" => uuid}, socket) do
    user_id = socket.assigns.user_id
    Dispatch.merge_next(uuid, user_id, generate_event_id(socket.id))

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

  def handle_event(
        "move_node_to_container",
        %{"container_id" => container_id, "uuid" => uuid} = params,
        socket
      ) do
    user_id = socket.assigns.user_id

    Dispatch.move_node_to_container(container_id, uuid, user_id, generate_event_id(socket.id),
      parent_id: params["parent_id"],
      prev_id: params["prev_id"]
    )

    socket
    |> reply(:noreply)
  end

  @impl true
  def handle_info(%NodeInsertedEvent{event_id: event_id, node: node, next: next}, socket) do
    socket
    |> stream_insert(:nodes, to_change_form(node, %{}))
    |> push_event("move_nodes", %{nodes: [next]})
    |> focus_self(node.uuid, event_id)
    |> reply(:noreply)
  end

  def handle_info(
        %NodeContentChangedEvent{event_id: <<_::binary-size(36)>> <> ":" <> id},
        %{id: id} = socket
      ),
      do: socket |> reply(:noreply)

  def handle_info(%NodeContentChangedEvent{node_id: node_id, content: content}, socket) do
    socket
    |> push_event("set_content", %{uuid: node_id, content: content})
    |> reply(:noreply)
  end

  def handle_info(
        %NodeMovedEvent{
          event_id: event_id,
          node: node,
          next: next,
          old_prev: old_prev,
          old_next: old_next,
          children: nil
        },
        socket
      ) do
    nodes = [node, next, old_prev, old_next] |> Enum.reject(&is_nil/1)

    socket
    |> push_event("move_nodes", %{nodes: nodes})
    |> focus_self(node.uuid, event_id)
    |> reply(:noreply)
  end

  def handle_info(
        %NodeMovedEvent{
          event_id: event_id,
          node: node,
          next: next,
          old_prev: old_prev,
          old_next: old_next,
          children: children
        },
        socket
      ) do
    nodes = ([node, next, old_prev, old_next] ++ children) |> Enum.reject(&is_nil/1)

    socket
    |> push_event("move_nodes", %{nodes: nodes})
    |> focus_self(node.uuid, event_id)
    |> reply(:noreply)
  end

  def handle_info(%NodeDeletedEvent{node: %{uuid: uuid}, next: nil}, socket) do
    socket
    |> stream_delete_by_dom_id(:nodes, "nodes-form-#{uuid}")
    |> reply(:noreply)
  end

  def handle_info(%NodeDeletedEvent{node: %{uuid: uuid}, next: next}, socket) do
    socket
    |> push_event("move_nodes", %{nodes: [next]})
    |> stream_delete_by_dom_id(:nodes, "nodes-form-#{uuid}")
    |> reply(:noreply)
  end

  def handle_info(%NodeMovedToNewContainer{node: node, next: next}, socket) do
    socket
    # |> stream_delete_by_dom_id(:nodes, "nodes-form-#{node.uuid}")
    |> stream_insert(:nodes, to_change_form(node, %{}))
    |> push_event("move_nodes", %{nodes: [next]})
    |> reply(:noreply)
  end

  def handle_info(%Broadcast{topic: "outline", event: event, payload: payload}, socket)
      when event in ["focus", "blur"] do
    socket
    |> push_event(event, payload)
    |> reply(:noreply)
  end

  # |> stream_event(event)

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
