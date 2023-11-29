defmodule RadiatorWeb.Api.OutlineControllerTest do
  use RadiatorWeb.ConnCase, async: true

  alias Radiator.Outline

  describe "POST /api/v1/outline" do
    test "creates a node if content is present", %{conn: conn} do
      body = %{"content" => "new node content"}
      conn = post(conn, ~p"/api/v1/outline", body)

      %{"uuid" => uuid} = json_response(conn, 200)

      assert %{content: "new node content"} = Outline.get_node!(uuid)
    end

    test "can't create node when content is missing", %{conn: conn} do
      conn = post(conn, ~p"/api/v1/outline", nil)

      assert %{"error" => "missing params"} = json_response(conn, 400)
    end
  end
end
