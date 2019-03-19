defmodule RadiatorWeb.LoginController do
  use RadiatorWeb, :controller

  def login_form(conn, _params) do
    render(conn, "login_form.html")
  end

  def login(conn, params) do
    case Radiator.Auth.Directory.get_user_by_credentials(
           params["name_or_email"],
           params["password"]
         ) do
      nil ->
        conn
        |> put_flash(:error, "Wrong Username/Password. #{inspect(params)}")
        |> render("login_form.html", Map.take(params, [:name_or_email]))

      valid_user ->
        path =
          case get_session(conn, :on_login) do
            {path, _query} -> path
            _ -> "/admin"
          end

        conn
        |> Radiator.Auth.Guardian.Plug.sign_in(valid_user)
        |> put_flash(:info, "Welcome #{valid_user.name}!")
        |> redirect(to: path)
    end
  end

  def logout(conn, _params) do
    conn
    |> Radiator.Auth.Guardian.Plug.sign_out()
    |> put_flash(:info, "Logged out!")
    |> redirect(to: "/")
  end
end
