defmodule RadiatorWeb.OutlineLive.Index do
  use RadiatorWeb, :live_view

  alias Radiator.Accounts
  alias Radiator.Outline
  alias RadiatorWeb.Endpoint

  @topic "outline"

  @impl true
  def mount(_params, _session, socket) do
    if connected?(socket) do
      Endpoint.subscribe(@topic)
    end

    node = %Outline.Node{}
    changeset = Outline.change_node(node)

    socket
    |> assign(:page_title, "Outline")
    |> assign(:bookmarklet, get_bookmarklet(Endpoint.url() <> "/api/v1/outline", socket))
    |> assign(:node, node)
    |> assign(:form, to_form(changeset))
    |> push_event("insert", %{nodes: Outline.list_nodes()})
    |> reply(:ok)
  end

  @impl true
  def handle_event("next", %{"node" => params}, socket) do
    user = socket.assigns.current_user
    {:ok, node} = Outline.create_node(params, user)

    socket
    |> push_event("insert", %{nodes: [node]})
    |> reply(:noreply)
  end

  def handle_event("set_focus", _node_id, socket) do
    socket
    |> reply(:noreply)
  end

  def handle_event("remove_focus", _node_id, socket) do
    socket
    |> reply(:noreply)
  end

  def handle_event("create_node", _params, socket) do
    socket
    |> reply(:noreply)
  end

  # def handle_event("delete", %{"uuid" => uuid}, socket) do
  #   node = Outline.get_node!(uuid)
  #   Outline.delete_node(node)

  #   socket
  #   |> reply(:noreply)
  # end

  @impl true
  def handle_info({:insert, node}, socket) do
    socket
    |> push_event("insert", %{nodes: [node]})
    |> reply(:noreply)
  end

  def handle_info({:delete, node}, socket) do
    socket
    |> push_event("delete", %{nodes: [node]})
    |> reply(:noreply)
  end

  defp get_bookmarklet(api_uri, socket) do
    token =
      socket.assigns.current_user
      |> Accounts.generate_user_api_token()
      |> Base.url_encode64(padding: false)

    """
    javascript:(function(){
      s=window.getSelection().toString();
      c=s!=""?s:window.location.href;
      xhr=new XMLHttpRequest();
      xhr.open('POST','#{api_uri}',true);
      xhr.setRequestHeader('Content-Type','application/x-www-form-urlencoded');
      xhr.send('content='+encodeURIComponent(c)+'&token=#{token}');
    })()
    """
    |> String.replace(["\n", "  "], "")
  end
end
