defmodule Radiator.Directory.Importer do
  alias Radiator.Directory.Editor
  alias Radiator.Directory.{Network, Podcast, Episode}

  require Logger

  def import_from_url(user, network, url) do
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
            image: episode.image_url,
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

  def import_enclosures(user, podcast, feed) do
    Metalove.PodcastFeed.trigger_episode_metadata_scrape(feed)
    Logger.info("Import: Scraping metadata for #{feed.feed_url}")
    feed = Metalove.PodcastFeed.get_by_feed_url_await_all_metdata(feed.feed_url, 1_000 * 15 * 60)

    Logger.info("Import: Got all metadata for #{feed.feed_url} - importing enclosures")

    feed.episodes
    |> Enum.map(fn episode_id -> Metalove.Episode.get_by_episode_id(episode_id) end)
    |> Enum.each(fn metalove_episode ->
      Logger.info("Import:  Episode #{metalove_episode.title}")

      {:ok, podlove_episode} =
        Editor.get_episode_by_podcast_id_and_guid(user, podcast.id, metalove_episode.guid)

      if metalove_episode.chapters do
        Radiator.EpisodeMeta.delete_chapters(podlove_episode)

        Enum.each(metalove_episode.chapters, fn chapter ->
          attrs = %{
            start: parse_chapter_time(chapter.start),
            title: chapter.title,
            link: Map.get(chapter, :href),
            image: Map.get(chapter, :image)
          }

          Radiator.EpisodeMeta.create_chapter(podlove_episode, attrs)
        end)
      end
    end)
  end
end
