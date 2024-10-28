defmodule RadiatorWeb.Api.RaindropController do
  use RadiatorWeb, :controller

  alias Radiator.Accounts
  alias Radiator.RaindropClient
  require Logger

  def auth_redirect(conn, %{"user_id" => user_id, "code" => code}) do
    Logger.error(
      "Raindrop auth redirect code: #{code}, redirect_uri: #{RaindropClient.redirect_uri()}"
    )

    {:ok, response} =
      [
        method: :post,
        url: "https://raindrop.io/oauth/access_token",
        json: %{
          client_id: RaindropClient.config()[:client_id],
          client_secret: RaindropClient.config()[:client_secret],
          grant_type: "authorization_code",
          code: code,
          redirect_uri: RaindropClient.redirect_uri()
        }
      ]
      |> Keyword.merge(RaindropClient.config()[:options])
      |> Req.request()

    Logger.error("Response from raindrop: #{inspect(response)}")

    if response.body != "Unauthorized" && !is_nil(response.body["access_token"]) do
      expires_at =
        DateTime.now!("Etc/UTC")
        |> DateTime.shift(second: response.body["expires_in"])
        |> DateTime.truncate(:second)

      Accounts.update_raindrop_tokens(
        user_id,
        response.body["access_token"],
        response.body["refresh_token"],
        expires_at
      )
    end

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
