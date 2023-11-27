defmodule RadiatorWeb.OutlineLive.Index do
  use RadiatorWeb, :live_view

  alias Radiator.Outline
  alias Radiator.Outline.Node

  alias RadiatorWeb.Endpoint

  @topic "outline"

  @impl true
  def mount(_params, _session, socket) do
    if connected?(socket) do
      Endpoint.subscribe(@topic)
    end

    node = %Node{}
    changeset = Outline.change_node(node)

    socket
    |> assign(:page_title, "Outline")
    |> assign(:node, node)
    |> assign(:form, to_form(changeset))
    |> stream_configure(:nodes, dom_id: &"node-#{&1.uuid}")
    |> stream(:nodes, Outline.list_nodes())
    |> reply(:ok)
  end

  @impl true
  def handle_event("update", %{"node" => _params}, socket) do
    socket
    |> reply(:noreply)
  end

  @impl true
  def handle_event("next", %{"node" => params}, socket) do
    user = socket.assigns.current_user
    {:ok, node} = Outline.create_node(params, user)

    Endpoint.broadcast(@topic, "inserted", node)

    socket
    |> stream_insert(:nodes, node, at: 0)
    |> reply(:noreply)
  end

  @impl true
  def handle_event("delete", %{"uuid" => uuid}, socket) do
    node = Outline.get_node!(uuid)
    {:ok, _} = Outline.delete_node(node)

    Endpoint.broadcast(@topic, "deleted", node)

    socket
    |> stream_delete(:nodes, node)
    |> reply(:noreply)
  end

  @impl true
  def handle_info(%{topic: @topic, event: "inserted", payload: node}, socket) do
    socket
    |> stream_insert(:nodes, node, at: 0)
    |> reply(:noreply)
  end

  def handle_info(%{topic: @topic, event: "deleted", payload: node}, socket) do
    socket
    |> stream_delete(:nodes, node)
    |> reply(:noreply)
  end
end
