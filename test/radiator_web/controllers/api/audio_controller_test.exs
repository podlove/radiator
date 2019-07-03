defmodule RadiatorWeb.Api.AudioControllerTest do
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

  describe "create audio" do
    test "renders audio when data is valid", %{conn: conn, user: user} do
      network = insert(:network) |> owned_by(user)

      conn =
        post(conn, Routes.api_audio_path(conn, :create),
          audio: %{title: "example", network_id: network.id}
        )

      assert %{"title" => "example"} = json_response(conn, 201)
    end

    test "renders errors when data is invalid", %{conn: conn} do
      conn = post(conn, Routes.api_audio_path(conn, :create), audio: %{})

      assert %{"errors" => %{"assignment" => _error}} = json_response(conn, 422)
    end

    test "renders errors when no network is given", %{conn: conn} do
      conn = post(conn, Routes.api_audio_path(conn, :create), audio: %{title: "pod"})

      assert response(conn, 422)
    end

    test "renders errors no user is present", %{conn: conn} do
      conn =
        conn
        |> delete_req_header("authorization")
        |> post(Routes.api_audio_path(conn, :create), audio: %{})

      assert "Unauthorized" = json_response(conn, 401)
    end
  end

  describe "show audio" do
    test "renders a audio", %{conn: conn, user: user} do
      audio = insert(:audio) |> owned_by(user)

      conn = get(conn, Routes.api_audio_path(conn, :show, audio.id))

      assert response = json_response(conn, 200)
      assert Map.get(response, "id") == audio.id
      assert Map.get(response, "title") == audio.title
    end

    test "renders an error if permissions missing", %{conn: conn} do
      audio = insert(:audio)

      conn = get(conn, Routes.api_audio_path(conn, :show, audio.id))

      assert response = json_response(conn, 401)
    end
  end

  describe "update audio" do
    test "renders audio", %{conn: conn, user: user} do
      audio = insert(:audio) |> owned_by(user)

      conn = put(conn, Routes.api_audio_path(conn, :update, audio.id), %{audio: %{title: "new"}})

      assert %{"title" => "new"} = json_response(conn, 200)
    end

    # test "renders error on invalid data", %{conn: conn, user: user} do
    #   audio = insert(:audio) |> owned_by(user)

    #   conn =
    #     put(conn, Routes.api_audio_path(conn, :update, audio.id), %{
    #       audio: %{}
    #     })

    #   assert %{"errors" => %{"title" => _error}} = json_response(conn, 422)
    # end
  end

  describe "delete audio" do
    test "delete audio", %{conn: conn, user: user} do
      audio = insert(:audio) |> owned_by(user)

      conn = delete(conn, Routes.api_audio_path(conn, :delete, audio.id))

      assert response(conn, 204)
    end

    test "deletes associated audio files", %{conn: conn, user: user} do
      audio = insert(:audio) |> owned_by(user)
      _file1 = insert(:audio_file, audio: audio)
      _file2 = insert(:audio_file, audio: audio)

      conn = delete(conn, Routes.api_audio_path(conn, :delete, audio.id))

      assert response(conn, 204)

      assert [] == Radiator.Repo.all(Radiator.Directory.Audio)
      assert [] == Radiator.Repo.all(Radiator.Media.AudioFile)
    end
  end
end
