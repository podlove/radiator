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
        |> put_flash(:error, "Wrong Username/Password.")
        |> render("login_form.html", Map.take(params, [:name_or_email]))

      valid_user ->
        conn
        |> sign_in_valid_user(valid_user)
    end
  end

  defp sign_in_valid_user(conn, user) do
    path =
      case get_session(conn, :on_login) do
        {path, _query} -> path
        _ -> "/admin"
      end

    conn
    |> Radiator.Auth.Guardian.Plug.sign_in(user)
    |> put_flash(:info, "Welcome #{user.name}!")
    |> redirect(to: path)
  end

  def logout(conn, _params) do
    conn
    |> Radiator.Auth.Guardian.Plug.sign_out()
    |> put_flash(:info, "Logged out!")
    |> redirect(to: "/")
  end

  def resend_verification_mail(conn, params) do
    case Radiator.Auth.User.validate_email_verification_request_token(params["token"]) do
      {:ok, name} ->
        user = Radiator.Auth.Directory.get_user_by_name(name)

        confirmation_url =
          Routes.login_url(
            conn,
            :verify_email,
            Radiator.Auth.User.email_verification_token(user)
          )

        user
        |> Radiator.Auth.Email.email_verification_email(confirmation_url)
        |> Radiator.Mailer.deliver_later()

        conn
        |> put_flash(:info, "Verification email sent to #{user.email}!")
        |> redirect(to: Routes.login_path(conn, :login_form, name_or_email: user.name))

      _ ->
        conn
        |> put_flash(:info, "Invalid request.")
        |> redirect(to: Routes.login_path(conn, :login_form))
    end
  end

  require Logger

  def verify_email(conn, params) do
    token = params["token"]

    case Radiator.Auth.User.validate_email_verification_token(token) do
      {:ok, user} ->
        case user.status do
          :unverified ->
            case Radiator.Auth.Directory.activate_user(user) do
              {:ok, user} ->
                conn
                |> put_flash(:info, "Email verified.")
                |> sign_in_valid_user(user)
            end

          _ ->
            conn
            |> redirect(to: "/admin")
        end

      _ ->
        conn
        |> put_flash(:info, "Could not verify email address.")
        |> redirect(to: Routes.login_path(conn, :login_form))
    end
  end
end
