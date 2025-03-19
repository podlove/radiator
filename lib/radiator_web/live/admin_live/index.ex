defmodule RadiatorWeb.AdminLive.Index do
  use RadiatorWeb, :live_view

  alias Radiator.Accounts
  alias Radiator.Accounts.RaindropClient
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
    |> assign_raindrop(RaindropClient.access_enabled?(socket.assigns.current_user.id))
    |> reply(:ok)
  end

  defp assign_raindrop(socket, true) do
    items =
      socket.assigns.current_user.id
      |> RaindropClient.get_collections()
      |> Enum.map(fn item -> {item["title"], item["_id"]} end)

    socket
    |> assign(:raindrop_access, true)
    |> assign(:raindrop_collections, items)
  end

  defp assign_raindrop(socket, false) do
    socket
    |> assign(
      :raindrop_url,
      "https://raindrop.io/oauth/authorize?client_id=#{RaindropClient.config()[:client_id]}&redirect_uri=#{RaindropClient.redirect_uri_encoded(socket.assigns.current_user.id)}"
    )
    |> assign(:raindrop_access, false)
    |> assign(:raindrop_collections, [])
  end

  @impl true
  def handle_event("new_network", _params, socket) do
    network = %Podcast.Network{}
    changeset = Podcast.change_network(network)

    socket
    |> assign(:action, :new_network)
    |> assign(:page_title, "New Network")
    |> assign(:network, network)
    |> assign(:form, to_form(changeset))
    |> reply(:noreply)
  end

  def handle_event("edit_network", %{"network_id" => network_id}, socket) do
    network = Podcast.get_network!(network_id)
    changeset = Podcast.change_network(network, %{})

    socket
    |> assign(:action, :edit_network)
    |> assign(:page_title, "Edit Network")
    |> assign(:network, network)
    |> assign(:form, to_form(changeset))
    |> reply(:noreply)
  end

  def handle_event("new_show", params, socket) do
    show = %Podcast.Show{}
    changeset = Podcast.change_show(show, params)

    socket
    |> assign(:action, :new_show)
    |> assign(:page_title, "New Show")
    |> assign(:show, show)
    |> assign(:host_suggestions, [])
    |> assign(:selected_hosts, [])
    |> assign(:host_email, "")
    |> assign(:form, to_form(changeset))
    |> reply(:noreply)
  end

  def handle_event("edit_show", %{"show_id" => show_id}, socket) do
    show = Podcast.get_show_preloaded!(show_id)
    changeset = Podcast.change_show(show, %{})

    socket
    |> assign(:action, :edit_show)
    |> assign(:page_title, "Edit Show")
    |> assign(:show, show)
    |> assign(:host_suggestions, [])
    |> assign(:selected_hosts, show.hosts)
    |> assign(:host_email, "")
    |> assign(:form, to_form(changeset))
    |> reply(:noreply)
  end

  def handle_event("cancel", _params, socket) do
    socket
    |> assign(:action, nil)
    |> assign(:page_title, "Admin Dashboard")
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

  def handle_event("connect_raindrop", _params, socket) do
    socket
    |> assign_raindrop(RaindropClient.access_enabled?(socket.assigns.current_user.id))
    |> reply(:noreply)
  end

  def handle_event("save", %{"show" => params}, socket) do
    save_show(socket, socket.assigns.action, params)
  end

  def handle_event("delete", %{"id" => id}, socket) do
    network = Podcast.get_network!(id)
    {:ok, _} = Podcast.delete_network(network)

    socket
    |> assign(:networks, Podcast.list_networks(preload: :shows))
    |> reply(:noreply)
  end

  defp save_show(socket, :new_show, params) do
    case Podcast.create_show(params, socket.assigns.selected_hosts) do
      {:ok, show} ->
        save_raindrop(socket, show.id, params)

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

  defp save_show(socket, :edit_show, params) do
    case Podcast.update_show(socket.assigns.show, params, socket.assigns.selected_hosts) do
      {:ok, show} ->
        save_raindrop(socket, show.id, params)

        socket
        |> assign(:action, nil)
        |> assign(:networks, Podcast.list_networks(preload: :shows))
        |> assign(selected_hosts: [])
        |> assign(host_suggestions: [])
        |> assign(host_email: "")
        |> put_flash(:info, "Show updated successfully")
        |> reply(:noreply)

      {:error, %Ecto.Changeset{} = changeset} ->
        socket
        |> assign(:form, to_form(changeset))
        |> put_flash(:info, "Show could not be updated")
        |> reply(:noreply)
    end
  end

  # defp save_raindrop(socket, show_id, %{"show" => %{"raindrop_collection" => collection_id}}) do
  defp save_raindrop(socket, show_id, %{"raindrop_collection" => collection_id}) do
    Accounts.connect_show_with_raindrop(socket.assigns.current_user.id, show_id, collection_id)
  end

  defp save_raindrop(_socket, _show_id, _params), do: nil

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
