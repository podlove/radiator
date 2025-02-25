defmodule RadiatorWeb.Api.OutlineControllerTest do
  use RadiatorWeb.ConnCase, async: true

  import Radiator.AccountsFixtures
  import Radiator.PodcastFixtures

  alias Radiator.{Accounts, Podcast}
  alias Radiator.Outline.NodeRepository

  describe "POST /api/v1/outline" do
    setup %{conn: conn} do
      user = user_fixture()
      show_id = episode_fixture().show_id

      token =
        user
        |> Accounts.generate_user_api_token()
        |> Base.url_encode64()

      %{conn: conn, user: user, token: token, show_id: show_id}
    end

    test "creates a node if content is present", %{
      conn: conn,
      user: %{id: user_id},
      show_id: show_id,
      token: token
    } do
      body = %{"content" => "new node content", "token" => token, show_id: show_id}
      conn = post(conn, ~p"/api/v1/outline", body)

      %{"uuid" => uuid} = json_response(conn, 200)

      assert %{content: "new node content", creator_id: ^user_id} =
               NodeRepository.get_node!(uuid)
    end

    test "created node is connected to episode", %{
      conn: conn,
      show_id: show_id,
      token: token
    } do
      body = %{"content" => "new node content", "token" => token, show_id: show_id}
      conn = post(conn, ~p"/api/v1/outline", body)

      %{"uuid" => uuid} = json_response(conn, 200)

      outline_node_container_id =
        Podcast.get_current_episode_for_show(show_id).outline_node_container_id

      assert %{content: "new node content", container_id: ^outline_node_container_id} =
               NodeRepository.get_node!(uuid)
    end

    test "can't create node when content is missing", %{conn: conn} do
      conn = post(conn, ~p"/api/v1/outline", nil)

      assert %{"error" => "missing params"} = json_response(conn, 400)
    end

    test "can't create node when token is wrong", %{
      conn: conn,
      show_id: show_id
    } do
      body = %{"content" => "new node content", "token" => "invalid", show_id: show_id}
      conn = post(conn, ~p"/api/v1/outline", body)

      assert %{"error" => "params"} = json_response(conn, 400)
    end
  end
end
