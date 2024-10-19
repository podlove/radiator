defmodule RadiatorWeb.Api.RaindropController do
  use RadiatorWeb, :controller

  alias Radiator.Accounts

  require Logger

  @raindrop Application.compile_env(:radiator, [:service, :raindrop])

  def auth_redirect(conn, %{"user_id" => user_id, "code" => code}) do
    %{host: host, request_path: request_path} = conn

    {:ok, response} =
      [
        method: :post,
        url: "https://raindrop.io/oauth/access_token",
        json: %{
          client_id: @raindrop[:client_id],
          client_secret: @raindrop[:client_secret],
          grant_type: "authorization_code",
          code: code,
          redirect_uri: host <> request_path
        }
      ]
      |> Keyword.merge(@raindrop[:options])
      |> Req.request()

    Logger.error("Response from raindrop: #{inspect(response)}")

    if response.body != "Unauthorized" do
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

  # Authorization: Bearer ae261404-11r4-47c0-bce3-e18a423da828
  def get_bookmarks(conn, _params) do
    # GENERATED DUMMY CODE!!!!
    user = Accounts.get_user!(conn.assigns[:access_token])

    response =
      [
        method: :get,
        url: "https://api.raindrop.io/rest/v1/collections",
        headers: [
          {"Authorization", "Bearer #{user.raindrop_access_token}"}
        ]
      ]
      |> Keyword.merge(@raindrop[:options])
      |> Req.request()
      |> Req.run()

    conn
    |> put_resp_content_type("application/json")
    |> send_resp(200, Jason.encode!(response.body))
  end
end
