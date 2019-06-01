defmodule Radiator.Directory.Importer do
  alias Radiator.Directory.Editor
  alias Radiator.Directory.Network
  alias Radiator.Directory.Podcast
  alias Radiator.Auth
  alias Radiator.Media

  require Logger

  def import_from_url(user = %Auth.User{}, network = %Network{}, url) do
    metalove_podcast = Metalove.get_podcast(url)

    feed =
      Metalove.PodcastFeed.get_by_feed_url_await_all_pages(
        metalove_podcast.main_feed_url,
        120_000
      )

    {:ok, podcast} =
      Editor.create_podcast(user, network, %{
        title: feed.title,
        subtitle: feed.subtitle,
        author: feed.author,
        description: feed.description,
        image: feed.image_url,
        language: feed.language
      })

    {:ok, podcast} = Editor.publish_podcast(user, podcast)

    metalove_episodes =
      feed.episodes
      |> Enum.map(fn episode_id -> Metalove.Episode.get_by_episode_id(episode_id) end)

    episodes =
      metalove_episodes
      |> Enum.map(fn episode ->
        {:ok, new_episode} =
          Editor.Manager.create_episode(podcast, %{
            guid: episode.guid,
            title: episode.title,
            subtitle: episode.subtitle,
            description: episode.description,
            content: episode.content_encoded,
            published_at: episode.pub_date,
            number: episode.episode,
            duration: episode.duration
          })

        if episode.chapters do
          Enum.each(episode.chapters, fn chapter ->
            attrs = %{
              start: parse_chapter_time(chapter.start),
              title: chapter.title,
              link: Map.get(chapter, :href),
              image: Map.get(chapter, :image)
            }

            Radiator.EpisodeMeta.create_chapter(new_episode, attrs)
          end)
        end

        new_episode
      end)

    # TODO: make optional, better structured, report progress and stuff
    spawn(__MODULE__, :import_enclosures, [user, podcast, feed])

    {:ok, %{podcast: podcast, episodes: episodes, metalove: %{feed: feed}}}
  end

  defp parse_chapter_time(time) when is_binary(time) do
    {:ok, parsed, _, _, _, _} = Chapters.Parsers.Normalplaytime.Parser.parse(time)
    Chapters.Parsers.Normalplaytime.Parser.total_ms(parsed)
  end

  def import_enclosures(
        user = %Auth.User{},
        podcast = %Podcast{},
        feed = %Metalove.PodcastFeed{},
        limit \\ 10
      ) do
    Metalove.PodcastFeed.trigger_episode_metadata_scrape(feed)
    Logger.info("Import: Scraping metadata for #{feed.feed_url}")
    feed = Metalove.PodcastFeed.get_by_feed_url_await_all_metdata(feed.feed_url, 1_000 * 15 * 60)

    Logger.info("Import: Got all metadata for #{feed.feed_url} - importing enclosures")

    feed.episodes
    |> Enum.take(limit)
    |> Enum.map(fn episode_id -> Metalove.Episode.get_by_episode_id(episode_id) end)
    |> Enum.each(fn metalove_episode ->
      Logger.info("Import:  Episode #{metalove_episode.title}")

      {:ok, podlove_episode} =
        Editor.get_episode_by_podcast_id_and_guid(user, podcast.id, metalove_episode.guid)

      case metalove_episode.enclosure.metadata do
        %{chapters: chapters} ->
          Radiator.EpisodeMeta.delete_chapters(podlove_episode)

          chapters
          |> Enum.each(fn chapter ->
            attrs = %{
              start: parse_chapter_time(chapter.start),
              title: chapter.title,
              link: Map.get(chapter, :href)
              # TODO: upload the found image and insert the url - image is a map with keys :data, and :type (mime/type)
              #              image: Map.get(chapter, :image)
            }

            Radiator.EpisodeMeta.create_chapter(podlove_episode, attrs)
          end)

        _ ->
          nil
      end

      case metalove_episode.image_url do
        nil -> nil
        url -> Editor.update_episode(user, podlove_episode, %{image: url})
      end

      Media.AudioFileUpload.sideload(metalove_episode.enclosure.url, podlove_episode)
    end)
  end
end
