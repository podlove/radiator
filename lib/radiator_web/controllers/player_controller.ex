defmodule RadiatorWeb.PlayerController do
  use RadiatorWeb, :controller

  alias Radiator.Directory
  alias Radiator.Directory.Audio
  alias Radiator.Media.AudioFile
  alias Radiator.AudioMeta.Chapter

  def show(conn, %{"audio_id" => id}) do
    audio = Directory.get_audio(id)

    json(conn, config(conn, audio))
  end

  def config(conn, audio) do
    %{
      title: audio.title,
      duration: audio.duration,
      audio: audio_files(audio),
      chapters: chapters(audio),
      reference: %{
        config: Routes.player_url(conn, :show, audio.id)
      }
    }
  end

  def audio_files(%Audio{audio_files: files}) do
    Enum.map(files, fn file ->
      %{
        url: AudioFile.public_url(file),
        mimeType: file.mime_type,
        size: file.byte_length,
        title: file.mime_type
      }
    end)
  end

  def chapters(%Audio{chapters: chapters}) do
    Enum.map(chapters, fn chapter ->
      %{
        start: RadiatorWeb.Admin.EpisodeView.format_chapter_time(chapter.start),
        title: chapter.title,
        href: chapter.link,
        image: Chapter.image_url(chapter)
      }
    end)
  end
end
