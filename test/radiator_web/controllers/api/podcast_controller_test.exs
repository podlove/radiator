defmodule RadiatorWeb.Api.PodcastControllerTest do
  use RadiatorWeb.ConnCase

  import Radiator.Factory

  def setup_user_and_conn(%{conn: conn}) do
    user = Radiator.TestEntries.user()

    [
      conn: Radiator.TestEntries.put_current_user(conn, user),
      user: user
    ]
  end

  setup :setup_user_and_conn

  describe "create podcast" do
    test "renders podcast when data is valid", %{conn: conn, user: user} do
      network = insert(:network) |> owned_by(user)

      conn =
        post(conn, Routes.api_podcast_path(conn, :create),
          podcast: %{title: "example", network_id: network.id}
        )

      assert %{"title" => "example"} = json_response(conn, 201)
    end

    test "renders errors when data is invalid", %{conn: conn, user: user} do
      network = insert(:network) |> owned_by(user)

      conn =
        post(conn, Routes.api_podcast_path(conn, :create), podcast: %{network_id: network.id})

      assert %{"errors" => %{"title" => _error}} = json_response(conn, 422)
    end

    test "renders errors when no network is given", %{conn: conn} do
      conn = post(conn, Routes.api_podcast_path(conn, :create), podcast: %{title: "pod"})

      assert response(conn, 422)
    end

    test "renders errors no user is present", %{conn: conn} do
      conn =
        conn
        |> delete_req_header("authorization")
        |> post(Routes.api_podcast_path(conn, :create), podcast: %{})

      assert "Unauthorized" = json_response(conn, 401)
    end
  end

  describe "show podcast" do
    test "renders a podcast", %{conn: conn, user: user} do
      podcast = insert(:podcast) |> owned_by(user)

      conn = get(conn, Routes.api_podcast_path(conn, :show, podcast.id))

      assert response = json_response(conn, 200)
      assert Map.get(response, "id") == podcast.id
      assert Map.get(response, "title") == podcast.title
    end

    test "renders an error if permissions missing", %{conn: conn} do
      podcast = insert(:podcast)

      conn = get(conn, Routes.api_podcast_path(conn, :show, podcast.id))

      assert response = json_response(conn, 401)
    end
  end

  describe "update podcast" do
    test "renders podcast", %{conn: conn, user: user} do
      podcast = insert(:podcast) |> owned_by(user)

      conn =
        put(conn, Routes.api_podcast_path(conn, :update, podcast.id), %{podcast: %{title: "new"}})

      assert %{"title" => "new"} = json_response(conn, 200)
    end

    test "renders error on invalid data", %{conn: conn, user: user} do
      podcast = insert(:podcast) |> owned_by(user)

      conn =
        put(conn, Routes.api_podcast_path(conn, :update, podcast.id), %{podcast: %{title: ""}})

      assert %{"errors" => %{"title" => _error}} = json_response(conn, 422)
    end
  end

  test "delete podcast", %{conn: conn, user: user} do
    podcast = insert(:podcast) |> owned_by(user)

    conn = delete(conn, Routes.api_podcast_path(conn, :delete, podcast.id))

    assert response(conn, 204)
  end
end
