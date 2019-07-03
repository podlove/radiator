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

  describe "create audio file" do
    test "renders audio file when data is valid", %{conn: conn, user: user} do
      audio = insert(:audio) |> owned_by(user)

      conn =
        post(conn, Routes.api_audio_file_path(conn, :create),
          audio_file: %{title: "example", audio_id: audio.id}
        )

      assert %{"title" => "example"} = json_response(conn, 201)
    end

    test "renders error when data is invalid", %{conn: conn} do
      conn =
        post(conn, Routes.api_audio_file_path(conn, :create), audio_file: %{title: "example"})

      assert %{"errors" => %{"audio" => ["can't be blank"]}} = json_response(conn, 422)
    end
  end
end
