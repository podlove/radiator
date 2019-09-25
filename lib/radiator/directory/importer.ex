defmodule Radiator.Directory.Importer do
  alias Radiator.Directory.{
    Editor,
    Network,
    Podcast,
    Episode
  }

  alias Radiator.Auth
  alias Radiator.Media

  alias Radiator.Task.{
    TaskWorker,
    TaskManager
  }

  import RadiatorWeb.FormatHelpers, only: [shorten_string: 3]

  require Logger

  def short_id_from_metalove_podcast(%Metalove.PodcastFeed{} = feed) do
    metalove_episodes =
      feed.episodes
      |> Enum.map(fn episode_id -> Metalove.Episode.get_by_episode_id(episode_id) end)

    # common title?
    titles =
      metalove_episodes
      |> Enum.map(fn episode ->
        episode.title
      end)

    filenames =
      metalove_episodes
      |> Enum.map(fn episode ->
        uri =
          episode.enclosure.url
          |> URI.parse()

        uri.path
        |> Path.basename()
      end)

    candidate =
      [filenames, titles]
      |> Enum.map(&Enum.take(&1, 10))
      |> Enum.map(&prefix_candidate/1)
      |> Enum.find(fn value -> value end)

    case candidate do
      nil ->
        feed.title
        |> String.slice(0, 3)
        |> String.upcase()

      candidate ->
        candidate
    end
  end

  defp prefix_candidate(stringlist) do
    case :binary.longest_common_prefix(stringlist) do
      length when length >= 2 ->
        stringlist
        |> hd
        |> String.slice(0, length)
        |> only_first_alphas()

      _ ->
        nil
    end
  end

  defp only_first_alphas(binary) do
    hd(Regex.run(~r/[\w]+/, hd(Regex.run(~r/[\D]+/, binary))))
  end

  defp shortsafe_string(nil), do: nil

  defp shortsafe_string(string) do
    shorten_string(string, 200, "…")
  end

  def start_import_task(user = %Auth.User{}, network = %Network{}, url, opts \\ []) do
    title = "Import '#{url}' into #{network.title}"

    TaskManager.start_task(
      fn task_worker ->
        import_task(task_worker, user, network, url, opts)
      end,
      title
    )
  end

  require Logger

  defp import_task(task_worker, user = %Auth.User{}, network = %Network{}, url, opts) do
    ## setup task
    opt_map =
      Enum.into(opts, %{
        limit: :unlimited,
        short_id: :deduce,
        enclosure_types: :all
      })

    metalove_podcast = Metalove.get_podcast(url)

    feed =
      Metalove.PodcastFeed.get_by_feed_url_await_all_pages(
        metalove_podcast.main_feed_url,
        120_000
      )

    episode_count = length(feed.episodes)

    total =
      case opt_map.limit do
        :unlimited -> episode_count
        limit -> min(limit, episode_count)
      end

    short_id =
      case opt_map.short_id do
        :deduce -> short_id_from_metalove_podcast(feed)
        short_id when is_binary(short_id) -> short_id
      end

    TaskWorker.increment_total(task_worker, total)

    {:ok, podcast} = create_podcast(user, network, feed, short_id)

    TaskWorker.set_in_description(task_worker, :subject, {Podcast, podcast.id()})

    TaskWorker.finish_setup(task_worker)

    ## end of setup

    feed.episodes
    |> Enum.take(total)
    |> Enum.map(fn episode_id -> Metalove.Episode.get_by_episode_id(episode_id) end)
    |> Enum.each(fn episode ->
      {:ok, radiator_episode} =
        Editor.Manager.create_episode(podcast, %{
          guid: episode.guid,
          title: episode.title,
          subtitle: shortsafe_string(episode.subtitle || episode.description),
          summary: episode.summary || episode.description,
          summary_html: episode.content_encoded,
          published_at: episode.pub_date,
          publish_state: :drafted,
          number: episode.episode,
          short_id: Episode.generate_short_id(short_id, episode.episode)
        })

      {:ok, audio} =
        Editor.Manager.create_audio(radiator_episode, %{
          published_at: episode.pub_date,
          duration: episode.duration && parse_chapter_time(episode.duration)
        })

      Media.AudioFileUpload.sideload(episode.enclosure.url, audio)

      case episode.chapters do
        chapters = [_ | _] ->
          chapters
          |> Enum.each(fn chapter ->
            attrs = %{
              start: parse_chapter_time(chapter.start),
              title: chapter.title,
              link: Map.get(chapter, :href),
              image: Map.get(chapter, :image)
            }

            Radiator.AudioMeta.create_chapter(audio, attrs)
          end)

        _no_chapters ->
          ## try to get chapters from scraped metadata info
          ## TODO: implement better support for incremental metadata loading in metalove

          try do
            enclosure = episode.enclosure

            enclosure =
              case Metalove.Enclosure.fetch_metadata(enclosure) do
                ^enclosure ->
                  enclosure

                enclosure ->
                  # update existing episode with found metadata
                  Metalove.Episode.get_by_episode_id({:episode, episode.feed_url, episode.guid})
                  |> Map.put(:enclosure, enclosure)
                  |> Metalove.Episode.store()

                  enclosure
              end

            create_chapters_from_metadata(audio, enclosure.metadata)
          rescue
            _ -> nil
          end
      end

      with url when not is_nil(url) <- episode.image_url do
        Editor.update_episode(user, radiator_episode, %{image: url})
        Editor.update_audio(user, audio, %{image: url})
      end

      TaskWorker.increment_progress(task_worker)

      Logger.info("Imported episode: #{episode.title}")
    end)
  end

  defp create_chapters_from_metadata(audio, metadata) do
    with %{chapters: chapters} <- metadata do
      Radiator.AudioMeta.delete_chapters(audio)

      chapters
      |> Enum.with_index(1)
      |> Enum.each(fn {chapter, index} ->
        attrs = %{
          start: parse_chapter_time(chapter.start),
          title: chapter.title,
          link: Map.get(chapter, :href)
        }

        with {:ok, radiator_chapter} <-
               Radiator.AudioMeta.create_chapter(audio, attrs) do
          case Map.get(chapter, :image) do
            %{
              data: binary_data,
              type: mime_type
            } ->
              extension = hd(:mimerl.mime_to_exts(mime_type))

              # TODO: make a nice wrapper around this temporary file creation
              upload = %Plug.Upload{
                content_type: mime_type,
                filename: "Chapter_#{index}.#{extension}",
                path: Plug.Upload.random_file!("chapter")
              }

              File.write(upload.path, binary_data)

              {:ok, radiator_chapter} =
                Radiator.AudioMeta.update_chapter(radiator_chapter, %{image: upload})

              File.rm(upload.path)
              radiator_chapter

            _ ->
              radiator_chapter
          end
        else
          failure ->
            Logger.debug(
              "Failed to create chapter #{index} with attributes: #{inspect(attrs, pretty: true)} - result: #{
                inspect(failure)
              }"
            )
        end
      end)
    end
  end

  defp create_podcast(user, network, feed, short_id) do
    Editor.create_podcast(user, network, %{
      title: feed.title,
      subtitle: shortsafe_string(feed.subtitle || feed.description),
      summary: feed.summary,
      author: feed.author,
      image: feed.image_url,
      language: feed.language,
      short_id: short_id
    })
  end

  defp parse_chapter_time(time) when is_binary(time) do
    Chapters.Parsers.Normalplaytime.Parser.parse_total_ms(time) || 0
  end

  def import_enclosures(
        user = %Auth.User{},
        podcast = %Podcast{},
        feed = %Metalove.PodcastFeed{},
        limit \\ 10
      ) do
    Metalove.PodcastFeed.trigger_episode_metadata_scrape(feed)
    Logger.info("Import: Scraping metadata for #{feed.feed_url}")

    feed =
      Metalove.PodcastFeed.get_by_feed_url_await_all_metdata(feed.feed_url, :timer.minutes(10))
      |> case do
        # just get the one without the parsed metadata, probably something went wrong on download
        nil -> Metalove.PodcastFeed.get_by_feed_url(feed.feed_url)
        feed -> feed
      end

    Logger.info("Import: Got all metadata for #{feed.feed_url} - importing enclosures")

    feed.episodes
    |> Enum.take(limit)
    |> Enum.map(fn episode_id -> Metalove.Episode.get_by_episode_id(episode_id) end)
    |> Enum.each(fn metalove_episode ->
      Logger.info("Import:  Episode #{metalove_episode.title}")

      {:ok, radiator_episode} =
        Editor.get_episode_by_podcast_id_and_guid(user, podcast.id, metalove_episode.guid)

      create_chapters_from_metadata(radiator_episode.audio, metalove_episode.enclosure.metadata)

      case metalove_episode.image_url do
        nil ->
          nil

        url ->
          Editor.update_episode(user, radiator_episode, %{image: url})
          Editor.update_audio(user, radiator_episode.audio, %{image: url})
      end

      Media.AudioFileUpload.sideload(metalove_episode.enclosure.url, radiator_episode.audio)
    end)
  end
end
