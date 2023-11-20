defmodule RadiatorWeb.OutlineLive.Index do
  use RadiatorWeb, :live_view

  alias Radiator.Outline
  alias Radiator.Outline.Node

  @impl true
  def mount(_params, _session, socket) do
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
    {:ok, node} = Outline.create_node(params)

    socket
    |> stream_insert(:nodes, node, at: 0)
    |> reply(:noreply)
  end

  @impl true
  def handle_event("delete", %{"uuid" => uuid}, socket) do
    node = Outline.get_node!(uuid)
    {:ok, _} = Outline.delete_node(node)

    {:noreply, stream_delete(socket, :nodes, node)}
  end
end
