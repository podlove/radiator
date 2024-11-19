defmodule RadiatorWeb.Api.RaindropControllerTest do
  use RadiatorWeb.ConnCase, async: true

  alias Radiator.Accounts.RaindropClient
  alias Radiator.AccountsFixtures

  describe "GET /raindrop/auth/redirect/:user_id" do
    setup %{conn: conn} do
      raindrop = RaindropClient.config()
      %{host: host, path: path} = URI.parse(raindrop.url)

      %{
        conn: conn,
        code: "some_random_string",
        client_id: raindrop.client_id,
        client_secret: raindrop.client_secret,
        host: host,
        path: path
      }
    end

    test "redirects to raindrop", %{
      conn: conn,
      code: code,
      client_id: client_id,
      client_secret: client_secret,
      host: host,
      path: path
    } do
      Req.Test.stub(RadiatorWeb.Api.RaindropController, fn conn ->
        assert {:ok, body, %{host: ^host, method: "POST", request_path: ^path}} = read_body(conn)
        assert {"content-type", "application/json"} in conn.req_headers

        assert {:ok,
                %{
                  "code" => ^code,
                  "client_id" => ^client_id,
                  "client_secret" => ^client_secret,
                  "grant_type" => "authorization_code"
                }} = Jason.decode(body)

        Req.Test.json(conn, %{
          access_token: "ae261404-11r4-47c0-bce3-e18a423da828",
          refresh_token: "c8080368-fad2-4a3f-b2c9-71d3z85011vb",
          expires: 1_209_599_768,
          token_type: "Bearer",
          expires_in: 1_209_599
        })
      end)

      user = AccountsFixtures.user_fixture()
      query_string = URI.encode_query(%{code: code})

      url =
        ~p"/api/raindrop/auth/redirect?user_id=#{user.id}"
        |> URI.parse()
        |> URI.append_query(query_string)
        |> URI.to_string()

      _conn = get(conn, url)
    end

    test "does something when an error is given instead of a code", %{conn: conn} do
      user = AccountsFixtures.user_fixture()
      query_string = URI.encode_query(%{error: "blah"})

      url =
        ~p"/api/raindrop/auth/redirect?user_id=#{user.id}"
        |> URI.parse()
        |> URI.append_query(query_string)
        |> URI.to_string()

      conn = get(conn, url)

      assert json_response(conn, 400) == %{"message" => "error"}
    end
  end
end
