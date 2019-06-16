defmodule RadiatorWeb.Admin.UserSettingsController do
  use RadiatorWeb, :controller

  alias Radiator.Auth
  alias Radiator.Auth.User

  action_fallback RadiatorWeb.Api.FallbackController

  def index(conn, _params) do
    render(conn, "usersettings.html", changeset: Auth.Register.change_user(%Auth.User{}))
  end

  def update(conn, params) do
    user_params = params["user"]
    user = authenticated_user(conn)

    case User.check_password(user, user_params["password_current"]) do
      {:ok, _} ->
        case Auth.Register.change_password(user, user_params) do
          {:ok, _user} ->
            conn
            |> put_flash(:info, "Successfully updated password.")
            |> redirect(to: Routes.admin_network_path(conn, :index))

          {:error, %Ecto.Changeset{} = changeset} ->
            conn
            |> put_flash(:error, "There were problems updating the password.")
            |> render("usersettings.html", changeset: changeset)
        end

      {:error, msg} ->
        conn
        |> put_flash(:error, "The current password is incorrect: #{msg}")
        |> render("usersettings.html",
          changeset: Auth.Register.change_user(%Auth.User{}, user_params)
        )
    end
  end
end
