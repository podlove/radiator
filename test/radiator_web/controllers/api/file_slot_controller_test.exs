defmodule RadiatorWeb.Api.FileSlotControllerTest do
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

  describe "list available slots" do
    test "for audio", %{conn: conn, user: user} do
      episode = insert(:episode) |> owned_by(user)
      audio = episode.audio

      conn = get(conn, Routes.api_audio_slot_path(conn, :index, audio))

      assert %{
               "_embedded" => %{
                 "rad:file_slot" => [%{"file" => "empty", "slot" => "audio_mp3"} | _]
               }
             } = json_response(conn, :ok)
    end
  end
end
