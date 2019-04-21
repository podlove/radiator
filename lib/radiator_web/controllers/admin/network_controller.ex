defmodule RadiatorWeb.Admin.NetworkController do
  use RadiatorWeb, :controller

  alias Radiator.Directory
  alias Directory.Network
  alias Directory.Editor

  def index(conn, _params) do
    me = conn.assigns.authenticated_user

    networks = Editor.list_networks(me)
    render(conn, "index.html", networks: networks)
  end

  def new(conn, _params) do
    changeset = Editor.Owner.change_network(%Network{})
    render(conn, "new.html", changeset: changeset)
  end

  def create(conn, %{"network" => network_params}) do
    user = Guardian.Plug.current_resource(conn)

    case Editor.Owner.create_network(user, network_params) do
      {:ok, %{network: network}} ->
        conn
        |> put_flash(:info, "Network created successfully.")
        |> redirect(to: Routes.admin_network_path(conn, :show, network.id))

      {:error, :network, %Ecto.Changeset{} = changeset, _} ->
        render(conn, "new.html", changeset: changeset)
    end
  end

  def show(conn, %{"id" => id}) do
    redirect(conn, to: Routes.admin_network_podcast_path(conn, :index, id))
  end

  def edit(conn, %{"id" => id}) do
    conn
    |> get_me()
    |> Editor.get_network(id)
    |> case do
      network = %Network{} ->
        changeset = Editor.Owner.change_network(network)

        render(conn, "edit.html", network: network, changeset: changeset)

      {:error, _} ->
        conn
        |> redirect(to: Routes.admin_network_path(conn, :index))
    end
  end

  def update(conn, %{"id" => id, "network" => network_params}) do
    me = get_me(conn)

    me
    |> Editor.get_network(id)
    |> case do
      network = %Network{} ->
        case Editor.update_network(me, network, network_params) do
          {:ok, network} ->
            conn
            |> put_flash(:info, "network updated successfully.")
            |> redirect(to: Routes.admin_network_path(conn, :index))

          {:error, %Ecto.Changeset{} = changeset} ->
            render(conn, "edit.html", network: network, changeset: changeset)

          other ->
            other
        end
    end
    |> case do
      {:error, _} ->
        conn
        |> redirect(to: Routes.admin_network_path(conn, :index))

      other ->
        other
    end
  end
end
