defmodule RadiatorWeb.Api.EpisodeControllerTest do
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

  describe "create episode" do
    test "renders episode when data is valid", %{conn: conn, user: user} do
      podcast = insert(:podcast) |> publish() |> owned_by(user)

      conn =
        post(conn, Routes.api_episode_path(conn, :create),
          episode: %{title: "example", podcast_id: podcast.id}
        )

      assert %{"title" => "example"} = json_response(conn, 201)
    end

    test "renders errors when data is invalid", %{conn: conn, user: user} do
      podcast = insert(:podcast) |> publish() |> owned_by(user)

      conn =
        post(conn, Routes.api_episode_path(conn, :create), episode: %{podcast_id: podcast.id})

      assert %{"errors" => %{"title" => _error}} = json_response(conn, 422)
    end

    test "renders errors when no podcast is given", %{conn: conn} do
      conn = post(conn, Routes.api_episode_path(conn, :create), episode: %{title: "pod"})

      assert response(conn, 422)
    end

    test "renders errors no user is present", %{conn: conn} do
      conn =
        conn
        |> delete_req_header("authorization")
        |> post(Routes.api_episode_path(conn, :create), episode: %{})

      assert "Unauthorized" = json_response(conn, 401)
    end
  end

  describe "show episode" do
    test "renders a episode", %{conn: conn, user: user} do
      episode = insert(:episode) |> owned_by(user)

      conn = get(conn, Routes.api_episode_path(conn, :show, episode.id))

      assert response = json_response(conn, 200)
      assert Map.get(response, "id") == episode.id
      assert Map.get(response, "title") == episode.title
    end

    test "renders an error if permissions missing", %{conn: conn} do
      episode = insert(:episode)

      conn = get(conn, Routes.api_episode_path(conn, :show, episode.id))

      assert response = json_response(conn, 401)
    end
  end

  describe "update episode" do
    test "renders episode", %{conn: conn, user: user} do
      episode = insert(:episode) |> owned_by(user)

      conn =
        put(conn, Routes.api_episode_path(conn, :update, episode.id), %{episode: %{title: "new"}})

      assert %{"title" => "new"} = json_response(conn, 200)
    end

    test "renders error on invalid data", %{conn: conn, user: user} do
      episode = insert(:episode) |> owned_by(user)

      conn =
        put(conn, Routes.api_episode_path(conn, :update, episode.id), %{episode: %{title: ""}})

      assert %{"errors" => %{"title" => _error}} = json_response(conn, 422)
    end
  end

  test "delete episode", %{conn: conn, user: user} do
    episode = insert(:episode) |> owned_by(user)

    conn = delete(conn, Routes.api_episode_path(conn, :delete, episode.id))

    assert response(conn, 204)
  end
end
