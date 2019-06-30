defmodule RadiatorWeb.Admin.NetworkCollaboratorController do
  use RadiatorWeb, :controller

  alias Radiator.Directory.Collaborator
  alias Radiator.Directory.Editor

  action_fallback RadiatorWeb.FallbackController

  def create(conn, %{"collaborator" => collaborator_params}) do
    actor = current_user(conn)
    network = current_network(conn)

    case Radiator.Auth.Register.get_user_by_name(collaborator_params["name"]) do
      nil ->
        conn
        |> put_flash(:error, "No user by this name in the system.")

      user ->
        with {:ok, _collaborator} <-
               Editor.add_collaborator(actor, %Collaborator{
                 user: user,
                 permission: String.to_existing_atom(collaborator_params["permission"]),
                 subject: network
               }) do
          conn
          |> put_flash(:info, "Added #{user.name} to collaborators.")
          |> redirect(to: Routes.admin_network_path(conn, :show, network.id))
        else
          _ ->
            conn
            |> put_flash(:error, "Could not add #{user.name} to collaborators.")
        end
    end
    |> redirect(
      to: Routes.admin_network_path(conn, :show, network.id, collaborator: collaborator_params)
    )
  end

  def delete(conn, %{"id" => collaborator_name}) do
    actor = current_user(conn)
    network = current_network(conn)

    case Radiator.Auth.Register.get_user_by_name(collaborator_name) do
      nil ->
        conn
        |> put_flash(:error, "No user by this name in the system.")

      user ->
        with {:ok, collaborator} <- Editor.get_collaborator(actor, network, collaborator_name),
             {:ok, _collaborator} <-
               Editor.remove_collaborator(actor, collaborator) do
          conn
          |> put_flash(:info, "Removed #{collaborator.user.name}")
        else
          _ ->
            conn
            |> put_flash(:error, "Could not remove #{user.name} from #{network.title}.")
        end
    end
    |> redirect(to: Routes.admin_network_path(conn, :show, network.id))
  end
end
