defmodule RadiatorWeb.TrackingController do
  use RadiatorWeb, :controller

  alias Radiator.Directory
  alias Radiator.Media.AudioFile

  def show(conn, %{"id" => id}) do
    audio = Directory.get_audio_file(id)

    redirect(conn, external: AudioFile.url({audio.file, audio}))
  end
end
