defmodule RadiatorWeb.LoginController do
  use RadiatorWeb, :controller

  alias Radiator.Auth

  alias Radiator.InstanceConfig

  def index(conn, _params) do
    render(conn, "index.html", user_changeset: Auth.Register.change_user(%Auth.User{}))
  end

  def login_form(conn, _params) do
    render(conn, "login.html")
  end

  def signup_form(conn, _params) do
    render(conn, "signup.html")
  end

  def login(conn, params) do
    case Auth.Register.get_user_by_credentials(
           params["name_or_email"],
           params["password"]
         ) do
      nil ->
        conn
        |> put_flash(:error, "Wrong Username/Password.")
        |> render("login.html", Map.take(params, [:name_or_email]))

      valid_user ->
        conn
        |> sign_in_valid_user(valid_user, "Welcome #{valid_user.name}!")
    end
  end

  def signup(conn, params) do
    user_map = params["user"]

    cond do
      user_map["password"] != user_map["password_repeat"] ->
        conn
        |> put_flash(:error, "Passwords don't match.")
        |> render("signup.html", changeset: Auth.Register.change_user(%Auth.User{}, user_map))

      true ->
        case Auth.Register.create_user(user_map) do
          {:ok, user} ->
            user
            |> Auth.Email.welcome_email(email_configuration_url(conn, user))
            |> Radiator.Mailer.deliver_later()

            conn
            |> sign_in_valid_user(
              user,
              "Welcome #{user.name}! A confirmation email has been sent to #{user.email} - please follow the contained link to finish the signup process."
            )

          {:error, %Ecto.Changeset{} = changeset} ->
            conn
            |> put_flash(:error, "There were problems creating your account.")
            |> render("signup.html", changeset: changeset)
        end
    end
  end

  defp sign_in_valid_user(conn, user, message) do
    {conn, path} =
      case get_session(conn, :on_login) do
        {path, _query} -> {delete_session(conn, :on_login), path}
        _ -> {conn, Routes.admin_network_path(conn, :index)}
      end

    conn
    |> Auth.Guardian.Plug.sign_in(user)
    |> put_flash(:info, message)
    |> redirect(to: path)
  end

  def logout(conn, _params) do
    conn
    |> Auth.Guardian.Plug.sign_out()
    |> put_flash(:info, "Logged out!")
    |> redirect(to: "/")
  end

  def email_configuration_url(conn, %Auth.User{} = user) do
    Routes.login_url(
      conn,
      :verify_email,
      Auth.User.email_verification_token(user)
    )
  end

  def resend_verification_mail(conn, params) do
    case Auth.User.validate_email_verification_request_token(params["token"]) do
      {:ok, name} ->
        user = Auth.Register.get_user_by_name(name)

        user
        |> Auth.Email.email_verification_email(email_configuration_url(conn, user))
        |> Radiator.Mailer.deliver_later()

        conn
        |> put_flash(:info, "Verification email sent to #{user.email}!")
        |> redirect(to: Routes.login_path(conn, :login_form, name_or_email: user.name))

      _ ->
        conn
        |> put_flash(:info, "Invalid request.")
        |> redirect(to: Routes.login_path(conn, :index))
    end
  end

  def verify_email(conn, params) do
    token = params["token"]

    case Auth.User.validate_email_verification_token(token) do
      {:ok, user} ->
        case user.status do
          :unverified ->
            case Auth.Register.activate_user(user) do
              {:ok, _user = %Auth.User{}} ->
                conn
                |> put_flash(:info, "Email verified.")
                |> Auth.Guardian.Plug.sign_in(user)
                |> redirect(external: InstanceConfig.base_admin_url())
            end

          _ ->
            conn
            |> redirect(
              to: Routes.admin_network_podcast_path(conn, :index, conn.assigns.current_network)
            )
        end

      _ ->
        conn
        |> put_flash(:info, "Could not verify email address.")
        |> redirect(to: Routes.login_path(conn, :index))
    end
  end
end
