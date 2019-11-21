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

      # IO.inspect(json_response(conn, :ok))

      assert %{
               "_embedded" => %{
                 "rad:file_slot" => [%{"file" => "empty", "slot" => "audio_mp3"} | _]
               }
             } = json_response(conn, :ok)
    end
  end

  describe "fill slot" do
    test "for audio, success case", %{conn: conn, user: user} do
      episode = insert(:episode) |> owned_by(user)
      audio = episode.audio
      network = episode.podcast.network |> owned_by(user)
      slot_name = "audio_mp3"

      {:ok, file} = Radiator.Storage.create_file(network, "test/fixtures/pling.mp3")

      conn =
        post(conn, Routes.api_audio_fill_slot_path(conn, :fill, audio, slot_name),
          file_id: file.id
        )

      assert json_response(conn, :created)

      conn =
        conn
        |> recycle()
        |> get(Routes.api_audio_slot_path(conn, :index, audio))

      assert %{
               "_embedded" => %{
                 "rad:file_slot" => [
                   %{"file" => %{"id" => mp3_file_id}, "slot" => "audio_mp3"} | _
                 ]
               }
             } = json_response(conn, :ok)

      assert mp3_file_id
    end
  end
end
