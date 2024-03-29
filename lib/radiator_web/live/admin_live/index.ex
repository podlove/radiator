defmodule RadiatorWeb.AdminLive.Index do
  use RadiatorWeb, :live_view

  alias Radiator.Accounts
  alias Radiator.Podcast
  alias RadiatorWeb.Endpoint

  @impl true
  def mount(_params, _session, socket) do
    socket
    |> assign(:action, nil)
    |> assign(:page_title, "Admin Dashboard")
    |> assign(:page_description, "Tools to create and manage your prodcasts")
    |> assign(:networks, Podcast.list_networks(preload: :shows))
    |> assign(:bookmarklet, get_bookmarklet(Endpoint.url() <> "/api/v1/outline", socket))
    |> reply(:ok)
  end

  @impl true
  def handle_event("new_network", _params, socket) do
    network = %Podcast.Network{}
    changeset = Podcast.change_network(network)

    socket
    |> assign(:action, :new_network)
    |> assign(:network, network)
    |> assign(:form, to_form(changeset))
    |> reply(:noreply)
  end

  def handle_event("new_show", params, socket) do
    show = %Podcast.Show{}
    changeset = Podcast.change_show(show, params)

    socket
    |> assign(:action, :new_show)
    |> assign(:show, show)
    |> assign(:form, to_form(changeset))
    |> reply(:noreply)
  end

  def handle_event("cancel", _params, socket) do
    socket
    |> assign(:action, nil)
    |> reply(:noreply)
  end

  def handle_event("validate", %{"network" => params}, socket) do
    changeset =
      socket.assigns.network
      |> Podcast.change_network(params)
      |> Map.put(:action, :validate)

    socket
    |> assign(:form, to_form(changeset))
    |> reply(:noreply)
  end

  def handle_event("validate", %{"show" => params}, socket) do
    changeset =
      socket.assigns.show
      |> Podcast.change_show(params)
      |> Map.put(:action, :validate)

    socket
    |> assign(:form, to_form(changeset))
    |> reply(:noreply)
  end

  def handle_event("save", %{"network" => params}, socket) do
    case Podcast.create_network(params) do
      {:ok, _network} ->
        socket
        |> assign(:action, nil)
        |> assign(:networks, Podcast.list_networks(preload: :shows))
        |> put_flash(:info, "Network created successfully")
        |> reply(:noreply)

      {:error, %Ecto.Changeset{} = changeset} ->
        socket
        |> assign(:form, to_form(changeset))
        |> put_flash(:info, "Network could not be created")
        |> reply(:noreply)
    end
  end

  def handle_event("save", %{"show" => params}, socket) do
    case Podcast.create_show(params) do
      {:ok, _show} ->
        socket
        |> assign(:action, nil)
        |> assign(:networks, Podcast.list_networks(preload: :shows))
        |> put_flash(:info, "Show created successfully")
        |> reply(:noreply)

      {:error, %Ecto.Changeset{} = changeset} ->
        socket
        |> assign(:form, to_form(changeset))
        |> put_flash(:info, "Show could not be created")
        |> reply(:noreply)
    end
  end

  def handle_event("delete", %{"id" => id}, socket) do
    network = Podcast.get_network!(id)
    {:ok, _} = Podcast.delete_network(network)

    socket
    |> assign(:networks, Podcast.list_networks(preload: :shows))
    # |> stream_delete(:networks, network)}
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
