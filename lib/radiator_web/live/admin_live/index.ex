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
    |> assign(:host_suggestions, [])
    |> assign(:selected_hosts, [])
    |> assign(:host_email, "")
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

  @impl true
  def handle_event("add_host", _params, socket) do
    case Accounts.get_user_by_email(socket.assigns.host_email) do
      nil ->
        {:noreply, put_flash(socket, :error, "User not found")}

      user ->
        selected_hosts = [user | socket.assigns.selected_hosts] |> Enum.uniq_by(& &1.id)

        {:noreply,
         socket
         |> assign(selected_hosts: selected_hosts)
         # Clear the input field
         |> assign(host_email: "")
         # Clear suggestions
         |> assign(host_suggestions: [])}
    end
  end

  @impl true
  def handle_event("remove_host", %{"host-id" => host_id}, socket) do
    selected_hosts =
      Enum.reject(socket.assigns.selected_hosts, &(&1.id == String.to_integer(host_id)))

    {:noreply, assign(socket, selected_hosts: selected_hosts)}
  end

  @impl true
  def handle_event("suggest_hosts", %{"show" => %{"host_email" => search}}, socket) do
    suggestions = Accounts.search_users(search)

    {:noreply,
     socket
     |> assign(host_suggestions: suggestions)
     |> assign(host_email: search)}
  end

  def handle_event("save", %{"show" => params}, socket) do
    case Podcast.create_show(params, socket.assigns.selected_hosts) do
      {:ok, _show} ->
        socket
        |> assign(:action, nil)
        |> assign(:networks, Podcast.list_networks(preload: :shows))
        |> assign(selected_hosts: [])
        |> assign(host_suggestions: [])
        |> assign(host_email: "")
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
