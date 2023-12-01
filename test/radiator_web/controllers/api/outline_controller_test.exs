defmodule RadiatorWeb.Api.OutlineControllerTest do
  use RadiatorWeb.ConnCase, async: true

  import Radiator.AccountsFixtures

  alias Radiator.Accounts
  alias Radiator.Outline

  describe "POST /api/v1/outline" do
    setup %{conn: conn} do
      user = user_fixture()

      token =
        user
        |> Accounts.generate_user_api_token()
        |> Base.url_encode64()

      %{conn: conn, user: user, token: token}
    end

    test "creates a node if content is present", %{conn: conn, user: %{id: user_id}, token: token} do
      body = %{"content" => "new node content", "token" => token}
      conn = post(conn, ~p"/api/v1/outline", body)

      %{"uuid" => uuid} = json_response(conn, 200)

      assert %{content: "new node content", creator_id: ^user_id} = Outline.get_node!(uuid)
    end

    test "can't create node when content is missing", %{conn: conn} do
      conn = post(conn, ~p"/api/v1/outline", nil)

      assert %{"error" => "missing params"} = json_response(conn, 400)
    end

    test "can't create node when token is wrong", %{conn: conn} do
      body = %{"content" => "new node content", "token" => "invalid"}
      conn = post(conn, ~p"/api/v1/outline", body)

      assert %{"error" => "params"} = json_response(conn, 400)
    end
  end
end
