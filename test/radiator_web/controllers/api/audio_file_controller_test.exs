defmodule RadiatorWeb.Api.AudioFileControllerTest do
  use RadiatorWeb.ConnCase

  def setup_user_and_conn(%{conn: conn}) do
    user = Radiator.TestEntries.user()

    [
      conn: Radiator.TestEntries.put_current_user(conn, user),
      user: user
    ]
  end

  setup :setup_user_and_conn

  describe "create audio file" do
    # test "renders audio file when data is valid", %{conn: conn, user: user} do
    #   audio_publication = insert(:audio_publication) |> owned_by(user)
    #   audio = insert(:audio, audio_publication: audio_publication)

    #   conn =
    #     post(conn, Routes.api_audio_file_path(conn, :create, audio),
    #       audio_file: %{title: "example"}
    #     )

    #   assert %{"title" => "example"} = json_response(conn, 201)
    # end

    # TODO: reenable once validate works again. Also testing the actual file upload somewhere might be prudent
    # test "renders error when data is invalid", %{conn: conn} do
    #   conn =
    #     post(conn, Routes.api_audio_file_path(conn, :create), audio_file: %{title: "example"})

    #   assert %{"errors" => %{"audio" => ["can't be blank"]}} = json_response(conn, 422)
    # end
  end
end
