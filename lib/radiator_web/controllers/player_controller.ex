defmodule RadiatorWeb.PlayerController do
  use RadiatorWeb, :controller

  alias Radiator.Directory
  alias Radiator.Directory.{Audio, Episode, Podcast}
  alias Radiator.Media.AudioFile
  alias Radiator.AudioMeta.Chapter

  def episode_config(conn, %{"episode_id" => episode_id}) do
    episode = Directory.get_episode(episode_id)
    audio = episode.audio

    json(conn, config(conn, %{audio: audio, episode: episode}))
  end

  def audio_config(conn, %{"audio_id" => audio_id}) do
    audio = Directory.get_audio(audio_id)

    # todo: handle invalid audio id

    json(conn, config(conn, %{audio: audio}))
  end

  def config(conn, %{audio: audio, episode: episode}) do
    podcast = episode.podcast

    config(conn, %{audio: audio})
    |> Map.merge(%{
      title: episode.title,
      subtitle: episode.subtitle,
      summary: episode.description,
      poster: Episode.image_url(episode),
      show: %{
        title: podcast.title,
        subtitle: podcast.subtitle,
        summary: podcast.description,
        poster: Podcast.image_url(podcast)
      },
      reference: %{
        config: Routes.player_url(conn, :episode_config, episode.id),
        share: "//cdn.podlove.org/web-player/share.html"
      }
    })
  end

  def config(conn, %{audio: audio}) do
    %{
      title: audio.title,
      duration: audio.duration,
      audio: audio_files(audio),
      chapters: chapters(audio),
      reference: %{
        config: Routes.player_url(conn, :audio_config, audio.id),
        share: "//cdn.podlove.org/web-player/share.html"
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
