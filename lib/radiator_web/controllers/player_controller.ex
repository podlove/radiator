defmodule RadiatorWeb.PlayerController do
  use RadiatorWeb, :controller

  alias Radiator.Directory

  alias Radiator.Directory.{
    AudioPublication,
    Audio,
    Episode,
    Podcast
  }

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

  def audio_publication_config(conn, %{"audio_publication_id" => audio_publication_id}) do
    with audio_publication = %AudioPublication{} <-
           Directory.get_audio_publication(audio_publication_id),
         audio <- audio_publication.audio do
      json(conn, config(conn, %{audio: audio, audio_publication: audio_publication}))
    else
      _ -> {:error, :not_found}
    end
  end

  def config(conn, %{audio: audio, episode: episode}) do
    podcast = episode.podcast

    audio_config(conn, %{audio: audio, episode: episode})
    |> Map.merge(%{
      title: episode.title,
      subtitle: episode.subtitle,
      summary: episode.summary_html || episode.summary,
      poster: Episode.image_url(episode, %{podcast: podcast}),
      link: Episode.public_url(episode, podcast),
      publicationDate: DateTime.to_iso8601(episode.published_at),
      show: %{
        title: podcast.title,
        subtitle: podcast.subtitle,
        summary: podcast.summary,
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

  def config(conn, %{audio: audio, audio_publication: audio_publication}) do
    audio_config(conn, %{audio: audio, audio_publication: audio_publication})
    |> Map.merge(%{
      title: audio_publication.title,
      # subtitle: audio_publication.subtitle,
      # summary: audio_publication.summary_html || audio_publication.summary,
      poster: AudioPublication.image_url(audio_publication),
      # link: Episode.public_url(audio_publication, podcast),
      publicationDate: DateTime.to_iso8601(audio_publication.published_at),
      # show: %{
      #   title: podcast.title,
      #   subtitle: podcast.subtitle,
      #   summary: podcast.summary,
      #   poster: Podcast.image_url(podcast),
      #   link: Podcast.public_url(podcast)
      # },
      reference: %{
        config: Routes.player_url(conn, :audio_publication_config, audio_publication.id),
        share: "//cdn.podlove.org/web-player/share.html"
      }
      # theme: %{
      #   main: podcast.main_color
      # }
    })
  end

  def audio_config(conn, %{audio: audio, audio_publication: audio_publication}) do
    %{
      title: audio.title,
      duration: audio.duration,
      audio: audio_files(audio, audio_publication),
      chapters: chapters(audio),
      reference: %{
        config: Routes.player_url(conn, :audio_publication_config, audio_publication.id),
        share: "//cdn.podlove.org/web-player/share.html"
      }
    }
  end

  def audio_config(conn, %{audio: audio, episode: episode}) do
    %{
      duration: audio.duration,
      audio: audio_files(audio, episode),
      chapters: chapters(audio),
      reference: %{
        config: Routes.player_url(conn, :episode_config, episode.id),
        share: "//cdn.podlove.org/web-player/share.html"
      }
    }
  end

  def audio_files(%Audio{audio_files: files}, context) do
    Enum.map(files, fn file ->
      %{
        url: AudioFile.public_url(file, context),
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
