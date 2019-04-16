defmodule RadiatorWeb.Admin.PodcastImportController do
  use RadiatorWeb, :controller

  alias Radiator.Directory
  alias Directory.Editor

  def new(conn, _params) do
    render(conn, "new.html")
  end

  # TODO
  # - needs error handling
  # - should be done async with waiting animation (progress?) and notice/redirect when done
  def create(conn, %{"feed" => %{"feed_url" => url}}) do
    network = conn.assigns.current_network

    metalove_podcast = Metalove.get_podcast(url)

    feed =
      Metalove.PodcastFeed.get_by_feed_url_await_all_pages(
        metalove_podcast.main_feed_url,
        120_000
      )

    {:ok, podcast} =
      Editor.Manager.create_podcast(network, %{
        title: feed.title,
        subtitle: feed.subtitle,
        author: feed.author,
        description: feed.description,
        image: feed.image_url,
        language: feed.language
      })

    feed.episodes
    |> Enum.map(fn episode_id -> Metalove.Episode.get_by_episode_id(episode_id) end)
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
          duration: episode.duration,
          enclosure_url: episode.enclosure.url,
          enclosure_type: episode.enclosure.type,
          enclosure_length: episode.enclosure.size
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

    redirect(conn, to: Routes.admin_network_podcast_path(conn, :show, podcast.network_id, podcast))
  end

  defp parse_chapter_time(time) when is_binary(time) do
    {:ok, parsed, _, _, _, _} = Chapters.Parsers.Normalplaytime.Parser.parse(time)
    Chapters.Parsers.Normalplaytime.Parser.total_ms(parsed)
  end
end
