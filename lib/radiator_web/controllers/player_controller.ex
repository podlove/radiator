defmodule RadiatorWeb.PlayerController do
  use RadiatorWeb, :controller

  alias Radiator.Directory
  alias Radiator.Directory.{Audio, Episode, Podcast}
  alias Radiator.Media.AudioFile
  alias Radiator.AudioMeta.Chapter

  action_fallback RadiatorWeb.Api.FallbackController

  def episode_config(conn, %{"episode_id" => episode_id}) do
    with episode = %Episode{} <- Directory.get_episode(episode_id),
         audio <- episode.audio do
      json(conn, config(conn, %{audio: audio, episode: episode}))
    else
      _ -> {:error, :not_found}
    end
  end

  def audio_config(conn, %{"audio_id" => audio_id}) do
    with audio = %Audio{} <- Directory.get_audio(audio_id) do
      json(conn, config(conn, %{audio: audio}))
    else
      _ -> {:error, :not_found}
    end
  end

  def config(conn, %{audio: audio, episode: episode}) do
    podcast = episode.podcast

    config(conn, %{audio: audio})
    |> Map.merge(%{
      title: episode.title,
      subtitle: episode.subtitle,
      summary: episode.description,
      poster: Episode.image_url(episode, %{podcast: podcast}),
      link: Episode.public_url(episode, podcast),
      publicationDate: DateTime.to_iso8601(episode.published_at),
      show: %{
        title: podcast.title,
        subtitle: podcast.subtitle,
        summary: podcast.description,
        poster: Podcast.image_url(podcast),
        link: Podcast.public_url(podcast)
      },
      reference: %{
        config: Routes.player_url(conn, :episode_config, episode.id),
        share: "//cdn.podlove.org/web-player/share.html"
      },
      theme: %{
        main: podcast.main_color
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
        start: RadiatorWeb.FormatHelpers.format_chapter_time(chapter.start),
        title: chapter.title,
        href: chapter.link,
        image: Chapter.image_url(chapter)
      }
    end)
  end
end
