defmodule RadiatorWeb.Api.AuthenticationController do
  use RadiatorWeb, :controller

  alias Radiator.Auth
  alias RadiatorWeb.Helpers.AuthHelpers

  def create(conn, %{"name" => name, "password" => password}) do
    Auth.Register.get_user_by_credentials(name, password)
    |> case do
      nil ->
        send_resp(conn, 401, "Login failed")

      user ->
        token = Auth.Guardian.api_session_token(user)

        conn
        |> json(AuthHelpers.session_response(user, token))
    end
  end

  def prolong(conn, _params) do
    user = current_user(conn)
    token = Auth.Guardian.api_session_token(user)

    conn
    |> json(AuthHelpers.session_response(user, token))
  end
end
