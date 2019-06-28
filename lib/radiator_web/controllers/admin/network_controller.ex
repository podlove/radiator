defmodule RadiatorWeb.Admin.NetworkController do
  use RadiatorWeb, :controller

  alias Radiator.Directory.{Network, Collaborator}
  alias Radiator.Directory.Editor

  action_fallback RadiatorWeb.FallbackController

  def index(conn, _params) do
    user = current_user(conn)

    networks = Editor.list_networks(user)
    render(conn, "index.html", networks: networks)
  end

  def new(conn, _params) do
    changeset = Editor.Owner.change_network(%Network{})
    render(conn, "new.html", changeset: changeset)
  end

  def create(conn, %{"network" => network_params}) do
    user = Guardian.Plug.current_resource(conn)

    case Editor.create_network(user, network_params) do
      {:ok, %Network{} = network} ->
        conn
        |> put_flash(:info, "Network created successfully.")
        |> redirect(to: Routes.admin_network_path(conn, :show, network.id))

      {:error, %Ecto.Changeset{} = changeset} ->
        render(conn, "new.html", changeset: changeset)
    end
  end

  def show(conn, %{"id" => id}) do
    with user <- current_user(conn),
         {:ok, network} <- Editor.get_network(user, id),
         podcasts <- Editor.list_podcasts_with_episode_counts(user, network),
         collaborators <- Editor.list_collaborators(user, network) do
      render(conn, "show.html",
        network: network,
        podcasts: podcasts,
        collaborators: collaborators
      )
    end
  end

  def edit(conn, %{"id" => id}) do
    conn
    |> current_user()
    |> Editor.get_network(id)
    |> case do
      {:ok, network = %Network{}} ->
        changeset = Editor.Owner.change_network(network)

        render(conn, "edit.html", network: network, changeset: changeset)

      {:error, _} ->
        conn
        |> redirect(to: Routes.admin_network_path(conn, :index))
    end
  end

  def update(conn, %{"id" => id, "network" => network_params}) do
    user = current_user(conn)

    user
    |> Editor.get_network(id)
    |> case do
      {:ok, network = %Network{}} ->
        case Editor.update_network(user, network, network_params) do
          {:ok, _network} ->
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

  def add_collaborator(conn, %{"id" => id, "collaborator" => collaborator}) do
    with actor <- current_user(conn),
         {:ok, network} <- Editor.get_network(actor, id),
         podcasts <- Editor.list_podcasts_with_episode_counts(actor, network),
         collaborators <- Editor.list_collaborators(actor, network) do
      case Radiator.Auth.Register.get_user_by_name(collaborator["name"]) do
        nil ->
          conn
          |> put_flash(:error, "No user by this name in the system.")

        user ->
          with {:ok, _collaborator} <-
                 Editor.add_collaborator(actor, %Collaborator{
                   user: user,
                   permission: String.to_existing_atom(collaborator["permission"]),
                   subject: network
                 }) do
            conn
            |> put_flash(:info, "Added #{user.name}")
            |> redirect(to: Routes.admin_network_path(conn, :show, id))
          else
            _ ->
              conn
              |> put_flash(:error, "Could not add #{user.name} to #{network.title}.")
          end
      end
      |> render("show.html",
        network: network,
        podcasts: podcasts,
        collaborators: collaborators,
        collaborator: collaborator
      )
    end
  end
end
