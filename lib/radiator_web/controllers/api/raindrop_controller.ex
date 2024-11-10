defmodule RadiatorWeb.Api.RaindropController do
  use RadiatorWeb, :controller

  alias Radiator.Accounts.RaindropClient
  require Logger

  def auth_redirect(conn, %{"user_id" => user_id, "code" => code}) do
    Logger.error(
      "Raindrop auth redirect code: #{code}, redirect_uri: #{RaindropClient.redirect_uri()}"
    )

    RaindropClient.init_and_store_access_token(user_id, code)

    conn
    |> put_resp_content_type("application/json")
    |> send_resp(200, Jason.encode!(%{message: "redirected"}))
  end

  def auth_redirect(conn, %{"error" => error}) do
    Logger.error("Raindrop auth redirect error: #{error}")

    conn
    |> put_resp_content_type("application/json")
    |> send_resp(400, Jason.encode!(%{message: "error"}))
  end
end
