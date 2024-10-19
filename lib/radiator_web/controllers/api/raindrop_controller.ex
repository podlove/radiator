defmodule RadiatorWeb.Api.RaindropController do
  use RadiatorWeb, :controller
  @raindrop Application.compile_env(:radiator, :service, :raindrop)

  def auth_redirect(conn, %{"user_id" =>user_id, "code" => code}) do
    IO.inspect(conn.request_path)

    response = Req.new(method: :post, url: "https://raindrop.io/oauth/access_token", json: %{
        client_id: @raindrop[:client_id],
        client_secret: @raindrop[:client_secret],
        grant_type: "authorization_code",
        code: code,
        redirect_uri: "YOUR_REDIRECT"
    })

    conn
    |> put_resp_content_type("application/json")
    |> send_resp(200, Jason.encode!(%{message: "redirected"}))
  end
end
