defmodule RadiatorWeb.Helpers.AuthHelpers do
  @moduledoc """
  Authentication helper functions for the web layer.
  """
  alias Radiator.Auth
  alias Radiator.Auth.User

  def session_response(user = %User{}, token) do
    %{
      username: user.name,
      token: token,
      expires_at: Auth.Guardian.get_expiry_datetime(token)
    }
  end

  def current_user(conn) do
    conn.assigns[:current_user]
  end

  def load_current_user(conn) do
    user =
      case current_user_from_token(conn) do
        {:ok, user} -> user
        {:error, _} -> nil
      end

    conn
    |> Plug.Conn.assign(:current_user, user)
  end

  def current_user_from_token(conn) do
    with {:ok, token} <- get_token_from_conn(conn),
         {:ok, claims} <- ensure_valid_api_session(token),
         {:ok, user} <- Auth.Guardian.resource_from_claims(claims) do
      {:ok, user}
    else
      {:error, reason} -> {:error, reason}
    end
  end

  defp ensure_valid_api_session(token) do
    case Auth.Guardian.decode_and_verify(token) do
      {:ok, claims = %{"typ" => "api_session"}} -> {:ok, claims}
      _ -> {:error, :token_verification_failed}
    end
  end

  defp get_token_from_conn(conn) do
    with ["Bearer " <> token] <- Plug.Conn.get_req_header(conn, "authorization") do
      {:ok, token}
    else
      _ -> {:error, :token_missing}
    end
  end
end
