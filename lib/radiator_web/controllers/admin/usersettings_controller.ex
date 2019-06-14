defmodule RadiatorWeb.Admin.UserSettingsController do
  use RadiatorWeb, :controller

  alias Radiator.Auth

  action_fallback RadiatorWeb.Api.FallbackController

  def index(conn, _params) do
    render(conn, "usersettings.html", changeset: Auth.Register.change_user(%Auth.User{}))
  end

  def create(conn, params) do
    user_params = params["user"]

    if user_params["password"] != user_params["password_repeat"] do
      conn
      |> put_flash(:error, "Passwords don't match.")
      |> render("usersettings.html",
        changeset: Auth.Register.change_user(%Auth.User{}, user_params)
      )
    else
      user = authenticated_user(conn)

      case Auth.Register.update_user(user, user_params) do
        {:ok, _user} ->
          conn
          |> put_flash(:info, "Successfully updated password.")
          |> redirect(to: Routes.admin_network_path(conn, :index))

        {:error, %Ecto.Changeset{} = changeset} ->
          conn
          |> put_flash(:error, "There were problems updating the password.")
          |> render("usersettings.html", changeset: changeset)

          conn
          |> put_flash(:info, "success")
          |> render("usersettings.html",
            changeset: Auth.Register.change_user(%Auth.User{}, user_params)
          )
      end
    end
  end
end
