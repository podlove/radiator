defmodule Mix.Tasks.Radiator.Import do
  use Mix.Task

  @shortdoc "Import a public rss feed into radiator."

  @moduledoc """
  Ingest a public rss feed into radiator.
  """

  @switches [debug: :boolean, preview: :boolean]
  @aliases [d: :debug, p: :preview]

  alias Radiator.Directory

  defmacro with_services(_opts \\ [], do: block) do
    quote do
      start_services()
      unquote(block)
      stop_services()
    end
  end

  @impl true
  @doc false
  def run(argv) do
    case parse_opts(argv) do
      {opts, [url]} ->
        opts = Map.new(opts)

        with_services do
          podcast = Metalove.get_podcast(url)

          feed =
            Metalove.PodcastFeed.get_by_feed_url_await_all_pages(podcast.main_feed_url, 120_000)

          if opts[:debug], do: IO.inspect(feed, pretty: true)

          {:ok, podcast} =
            Directory.create_podcast(%{
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
            Directory.create_episode(podcast, %{
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
              enclosure_type: episode.enclosure.type
              # enclosure_length: episode.enclosure.size
            })
          end)
        end

      _ ->
        Mix.Tasks.Help.run(["radiator.import"])
    end
  end

  defp parse_opts(argv) do
    case OptionParser.parse(argv, strict: @switches, aliases: @aliases) do
      {opts, argv, []} ->
        {opts, argv}

      {_opts, _argv, [switch | _]} ->
        Mix.raise("Invalid option: " <> switch_to_string(switch))
    end
  end

  defp switch_to_string({name, nil}), do: name
  defp switch_to_string({name, val}), do: name <> "=" <> val

  @start_apps [:metalove, :postgrex, :ecto, :ecto_sql]
  @repos Application.get_env(:radiator, :ecto_repos, [])

  defp start_services do
    Enum.each(@start_apps, &Application.ensure_all_started/1)
    Enum.each(@repos, & &1.start_link(pool_size: 2))
  end

  defp stop_services do
    :init.stop()
  end
end
