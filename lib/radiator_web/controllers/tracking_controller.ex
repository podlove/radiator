defmodule RadiatorWeb.TrackingController do
  use RadiatorWeb, :controller

  alias Radiator.Directory
  alias Radiator.Media.AudioFile

  def show(conn, %{"id" => id}) do
    case Directory.get_audio_file(id) do
      {:ok, audio} ->
        conn
        |> put_status(301)
        |> redirect(external: AudioFile.url({audio.file, audio}))

      {:error, _} ->
        send_resp(conn, 404, "Not found")
    end
  end
end
