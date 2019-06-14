defmodule RadiatorWeb.Admin.UserSettingsController do
  use RadiatorWeb, :controller

  alias Radiator.Auth

  action_fallback RadiatorWeb.Api.FallbackController

  def index(conn, _params) do
    render(conn, "usersettings.html", changeset: Auth.Register.change_user(%Auth.User{}))
  end

  def create(conn, params) do
    user_map = params["user"]

    cond do
      user_map["password"] != user_map["password_repeat"] ->
        conn
        |> put_flash(:error, "Passwords don't match.")
        |> render("usersettings.html",
          changeset: Auth.Register.change_user(%Auth.User{}, user_map)
        )

      true ->
        user = Guardian.Plug.current_resource(conn)

        case Auth.Register.update_user(user, user_map) do
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
              changeset: Auth.Register.change_user(%Auth.User{}, user_map)
            )
        end
    end
  end
end
