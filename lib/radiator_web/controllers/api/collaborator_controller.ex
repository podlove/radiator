defmodule RadiatorWeb.Api.CollaboratorController do
  use RadiatorWeb, :controller
  use Radiator.Constants, :permissions

  alias Radiator.Directory.Editor
  alias Radiator.Directory.Collaborator
  alias Radiator.Auth

  action_fallback RadiatorWeb.Api.FallbackController

  def create(conn, %{"username" => username, "permission" => permission} = params) do
    with actor <- current_user(conn),
         {:ok, subject} <- current_subject(actor, params),
         user = %Auth.User{} <- Auth.Register.get_user_by_name(username),
         {:ok, collaborator} <- build_collaborator(user, permission, subject),
         {:ok, collaborator} <- Editor.add_collaborator(actor, collaborator) do
      conn
      |> put_status(:created)
      |> render("show.json", %{collaborator: collaborator})
    else
      nil -> {:error, :not_found}
      error -> error
    end
  end

  defp build_collaborator(user, permission, subject) when is_permission(permission) do
    {:ok,
     %Collaborator{
       user: user,
       permission: permission,
       subject: subject
     }}
  end

  defp build_collaborator(user, permission, subject) when is_binary(permission) do
    perm =
      try do
        String.to_existing_atom(permission)
      catch
        _, _ -> :invalid_permission
      end

    build_collaborator(user, perm, subject)
  end

  defp build_collaborator(_, _, _), do: {:error, :invalid_permission}

  def update(conn, %{"id" => username, "permission" => permission} = params) do
    with ^username <- params["username"],
         actor = current_user(conn),
         {:ok, subject} <- current_subject(actor, params) do
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
         {:ok, subject} <- current_subject(actor, params) do
      with {:ok, collaborator} <- Editor.get_collaborator(actor, subject, username),
           {:ok, collaborator} <- Editor.remove_collaborator(actor, collaborator) do
        conn
        |> render("show.json", %{collaborator: collaborator})
      end
    end
  end

  def show(conn, %{"id" => username} = params) do
    with actor = current_user(conn),
         {:ok, subject} <- current_subject(actor, params) do
      with {:ok, collaborator} <- Editor.get_collaborator(actor, subject, username) do
        conn
        |> render("show.json", %{collaborator: collaborator})
      end
    end
  end

  defp current_subject(actor = %Radiator.Auth.User{}, params) do
    case params["podcast_id"] do
      nil ->
        Editor.get_network(actor, params["network_id"])

      id ->
        Editor.get_podcast(actor, id)
    end
  end
end
