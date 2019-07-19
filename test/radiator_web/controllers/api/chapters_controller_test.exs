defmodule RadiatorWeb.Api.ChaptersControllerTest do
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

  describe "create chapter" do
    test "renders chapter when data is valid", %{conn: conn, user: user} do
      audio = insert(:audio) |> owned_by(user)

      conn =
        post(conn, Routes.api_audio_chapters_path(conn, :create, audio.id),
          chapter: %{title: "example", start: 123_000, link: "http://example.com"}
        )

      assert %{"title" => "example", "start" => 123_000, "link" => "http://example.com"} =
               json_response(conn, 201)
    end

    test "renders error when permissions are invalid", %{conn: conn} do
      audio = insert(:audio)

      conn =
        post(conn, Routes.api_audio_chapters_path(conn, :create, audio.id),
          chapter: %{title: "example"}
        )

      assert json_response(conn, 401)
    end
  end

  describe "update chapter" do
    test "updates and renders chapter", %{conn: conn, user: user} do
      audio = insert(:audio) |> owned_by(user)
      chapter = insert(:chapter, audio: audio)

      conn =
        put(conn, Routes.api_audio_chapters_path(conn, :update, audio.id, chapter.start), %{
          chapter: %{title: "new"}
        })

      assert %{"title" => "new"} = json_response(conn, 200)
    end
  end

  test "delete chapter", %{conn: conn, user: user} do
    audio = insert(:audio) |> owned_by(user)
    chapter = insert(:chapter, audio: audio)

    conn = delete(conn, Routes.api_audio_chapters_path(conn, :delete, audio.id, chapter.start))

    assert response(conn, 204)
  end
end
