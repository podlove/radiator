defmodule RadiatorWeb.Api.OutlineControllerTest do
  use RadiatorWeb.ConnCase, async: true

  alias Radiator.Outline

  describe "POST /api/v1/outline" do
    test "creates a node", %{conn: conn} do
      body = %{"content" => "new node content"}
      conn = post(conn, ~p"/api/v1/outline", body)

      %{"uuid" => uuid} = json_response(conn, 200)

      assert %{content: "new node content"} = Outline.get_node!(uuid)
    end
  end
end
