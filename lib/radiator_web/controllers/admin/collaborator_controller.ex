defmodule RadiatorWeb.Admin.CollaboratorController do
  use RadiatorWeb, :controller

  alias Radiator.Directory.Collaborator
  alias Radiator.Directory.{Network, Podcast}
  alias Radiator.Directory.Editor

  action_fallback RadiatorWeb.FallbackController

  def create(conn, %{"collaborator" => collaborator_params}) do
    actor = current_user(conn)
    subject = current_subject(conn)

    case Radiator.Auth.Register.get_user_by_name(collaborator_params["name"]) do
      nil ->
        conn
        |> put_flash(:error, "No user by this name in the system.")

      user ->
        with {:ok, _collaborator} <-
               Editor.add_collaborator(actor, %Collaborator{
                 user: user,
                 permission: String.to_existing_atom(collaborator_params["permission"]),
                 subject: subject
               }) do
          conn
          |> put_flash(:info, "Added #{user.name} to collaborators.")
          |> redirect_back(subject)
          |> halt()
        else
          _ ->
            conn
            |> put_flash(:error, "Could not add #{user.name} to collaborators.")
        end
    end
    |> redirect_back(subject, collaborator: collaborator_params)
  end

  def delete(conn, %{"id" => collaborator_name}) do
    actor = current_user(conn)
    subject = current_subject(conn)

    case Radiator.Auth.Register.get_user_by_name(collaborator_name) do
      nil ->
        conn
        |> put_flash(:error, "No user by this name in the system.")

      user ->
        with {:ok, collaborator} <-
               Editor.get_collaborator(actor, subject, collaborator_name),
             {:ok, _collaborator} <-
               Editor.remove_collaborator(actor, collaborator) do
          conn
          |> put_flash(:info, "Removed #{collaborator.user.name}")
        else
          _ ->
            conn
            |> put_flash(:error, "Could not remove #{user.name} from #{subject.title}.")
        end
    end
    |> redirect_back(subject)
  end

  defp current_subject(conn) do
    current_podcast(conn) || current_network(conn)
  end

  defp redirect_back(conn, subject, params \\ [])

  defp redirect_back(conn, subject = %Network{}, params) do
    conn
    |> redirect(to: Routes.admin_network_path(conn, :show, subject.id, params))
  end

  defp redirect_back(conn, subject = %Podcast{}, params) do
    conn
    |> redirect(
      to: Routes.admin_network_podcast_path(conn, :show, subject.network_id, subject.id, params)
    )
  end
end
