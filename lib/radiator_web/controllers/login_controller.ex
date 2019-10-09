defmodule RadiatorWeb.LoginController do
  use RadiatorWeb, :controller

  alias Radiator.Auth

  alias Radiator.InstanceConfig

  alias RadiatorWeb.Helpers.EmailHelpers

  import Phoenix.HTML.Link

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
        flash_content =
          case Auth.Register.user_by_name_or_email(params["name_or_email"]) do
            {:ok, user} ->
              [
                "Wrong Username/Password. (",
                link("Request Password Reset",
                  to:
                    Routes.login_path(
                      conn,
                      :send_reset_password_mail,
                      Radiator.Auth.User.email_reset_password_request_token(user)
                    )
                ),
                ")"
              ]

            _ ->
              "Wrong Username/Password."
          end

        conn
        |> put_flash(:error, flash_content)
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
        case EmailHelpers.singup_user(user_map) do
          {:ok, user} ->
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

  def resend_verification_mail(conn, params) do
    with {:ok, name} <- Auth.User.validate_email_verification_request_token(params["token"]),
         user <- Auth.Register.get_user_by_name(name),
         :sent <- EmailHelpers.resend_verification_email_for_user(user) do
      conn
      |> put_flash(:info, "Verification email sent to #{user.email}!")
      |> redirect(to: Routes.login_path(conn, :login_form, name_or_email: user.name))
    else
      _ ->
        conn
        |> put_flash(:info, "Invalid request.")
        |> redirect(to: Routes.login_path(conn, :index))
    end
  end

  def send_reset_password_mail(conn, params) do
    with {:ok, name} <- Auth.User.validate_email_reset_password_request_token(params["token"]),
         user <- Auth.Register.get_user_by_name(name),
         :sent <- EmailHelpers.send_reset_password_email_for_user(user) do
      conn
      |> put_flash(:info, "Password Reset email sent!")
      |> redirect(to: Routes.login_path(conn, :login_form, name_or_email: user.name))
    else
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

  def reset_password_form(conn, %{"token" => token}) do
    with {:ok, user = %Auth.User{}} <- Auth.User.validate_reset_password_token(token) do
      # TODO: burn token too
      conn
      |> put_session(:password_reset_token, token)
      |> put_session(:password_reset_user_name, user.name)
      |> configure_session(renew: true)
      |> redirect(to: Routes.login_path(conn, :reset_password_form))
    else
      _ ->
        conn
        |> put_flash(:error, "Invalid request.")
        |> redirect(to: Routes.login_path(conn, :index))
    end
  end

  def reset_password_form(conn, _) do
    token = get_session(conn, :password_reset_token)
    username = get_session(conn, :password_reset_user_name)

    conn
    |> render("password_reset.html", token: token, username: username)
  end

  def reset_password(conn, params) do
    token = get_session(conn, :password_reset_token)
    username = get_session(conn, :password_reset_user_name)
    new_password = params["password"]

    cond do
      new_password != "" and new_password == params["password_repeat"] ->
        with {:ok, user = %Auth.User{}} <- Auth.User.validate_reset_password_token(token) do
          Auth.Register.update_user(user, %{password: new_password})

          conn
          |> configure_session(drop: true)
          |> redirect(to: Routes.login_path(conn, :login_form, name_or_email: user.name))
        else
          _ ->
            conn
            |> put_flash(:error, "Invalid request.")
            |> configure_session(drop: true)
            |> redirect(to: Routes.login_path(conn, :index))
        end

      true ->
        conn
        |> put_flash(:error, "Passwords need to match")
        |> render("password_reset.html", token: token, username: username)
    end
  end
end
