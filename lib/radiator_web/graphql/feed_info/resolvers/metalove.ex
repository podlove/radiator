defmodule RadiatorWeb.GraphQL.FeedInfo.Resolvers.Metalove do
  def get_feed_info(_, %{url: url}, _) do
    with podcast = %Metalove.Podcast{} <- Metalove.get_podcast(url),
         main_feed = %Metalove.PodcastFeed{} <-
           Metalove.PodcastFeed.get_by_feed_url(podcast.main_feed_url),
         short_id <- Radiator.Directory.Importer.short_id_from_metalove_podcast(main_feed) do
      %{
        title: main_feed.title,
        subtitle: main_feed.subtitle,
        link: main_feed.link,
        image: main_feed.image_url,
        suggested_short_id: short_id,
        feeds:
          podcast.feed_urls
          |> Enum.map(&Metalove.PodcastFeed.get_by_feed_url/1)
          |> Enum.reject(&is_nil/1)
          |> Enum.map(&metalove_feed_to_podcast_feed/1)
      }
      |> (&{:ok, &1}).()
    else
      _ ->
        {:error, "No feeds found at '#{url}'"}
    end
  end

  def metalove_feed_to_podcast_feed(feed = %Metalove.PodcastFeed{}) do
    %{
      feed_url: feed.feed_url,
      link: feed.link,
      title: feed.title,
      subtitle: feed.subtitle,
      description: feed.description,
      author: feed.author,
      image: feed.image_url,
      episodes:
        feed.episodes
        |> Enum.map(&Metalove.Episode.get_by_episode_id/1)
        |> Enum.map(&metalove_episode_to_podcast_feed_episode/1),
      episode_count: length(feed.episodes),
      waiting_for_pages: feed.waiting_for_pages
    }
  end

  def get_feed_content(_, %{url: url}, _) do
    # make sure we tried fetching the podcast first
    Metalove.get_podcast(url)

    with feed = %Metalove.PodcastFeed{} <- Metalove.PodcastFeed.get_by_feed_url(url) do
      feed
      |> metalove_feed_to_podcast_feed()
      |> (&{:ok, &1}).()
    else
      _ ->
        {:error, "Could not get feed content from '#{url}'"}
    end
  end

  def metalove_episode_to_podcast_feed_episode(ep = %Metalove.Episode{}) do
    %{
      guid: ep.guid,
      title: ep.title,
      subtitle: ep.subtitle,
      summary: ep.summary,
      description: ep.description,
      content_encoded: ep.content_encoded,
      duration: ep.duration,
      link: ep.link,
      season: ep.season,
      episode: ep.episode,
      image: ep.image_url,
      enclosure_url: ep.enclosure.url,
      enclosure_type: ep.enclosure.type
    }
  end
end
