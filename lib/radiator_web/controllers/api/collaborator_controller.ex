defmodule RadiatorWeb.Api.CollaboratorController do
  use RadiatorWeb, :controller
  use Radiator.Constants

  alias Radiator.Directory.Editor

  alias Radiator.Directory.Collaborator

  action_fallback RadiatorWeb.Api.FallbackController

  def create(conn, %{"username" => username, "permission" => permission} = params) do
    with actor <- current_user(conn),
         {:ok, subject} <- Editor.get_network(actor, params["network_id"]) do
      case Radiator.Auth.Register.get_user_by_name(username) do
        nil ->
          {:error, :not_found}

        user ->
          collaborator = %Collaborator{
            user: user,
            permission: String.to_existing_atom(permission),
            subject: subject
          }

          with {:ok, collaborator} <- Editor.add_collaborator(actor, collaborator) do
            conn
            |> put_status(:created)
            |> render("show.json", %{collaborator: collaborator})
          end
      end
    end
  end

  def update(conn, %{"id" => username, "permission" => permission} = params) do
    with ^username <- params["username"],
         actor = current_user(conn),
         {:ok, subject} <- Editor.get_network(actor, params["network_id"]) do
      with {:ok, collaborator} <- Editor.get_collaborator(actor, subject, username),
           {:ok, collaborator} <-
             Editor.update_collaborator(actor, %{
               collaborator
               | permission: String.to_existing_atom(permission)
             }) do
        conn
        |> render("show.json", %{collaborator: collaborator})
      end
    end
  end

  def delete(conn, %{"id" => username} = params) do
    with actor = current_user(conn),
         {:ok, subject} <- Editor.get_network(actor, params["network_id"]) do
      with {:ok, collaborator} <- Editor.get_collaborator(actor, subject, username),
           {:ok, collaborator} <- Editor.remove_collaborator(actor, collaborator) do
        conn
        |> render("show.json", %{collaborator: collaborator})
      end
    end
  end
end
