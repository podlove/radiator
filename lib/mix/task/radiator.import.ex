defmodule Mix.Tasks.Radiator.Import do
  use Mix.Task
  alias Mix.Shell.IO, as: ShellIO

  @shortdoc "Import a public rss feed into radiator."

  @moduledoc """
  Ingest a public rss podcast feed into radiator.

      mix radiator.import username -p fanboys.fm

  ## Options

    * `--network/-n <network>` - import into a specific network of the user
    * `--preview/-p` - only preview what is going to be imported.
    * `--debug/-d` - turn on debug logging.

  """

  @switches [debug: :boolean, preview: :boolean, network: :string]
  @aliases [d: :debug, p: :preview, n: :network]

  alias Radiator.Directory
  alias Radiator.Directory.Editor

  defmacrop with_services(_opts \\ [], do: block) do
    quote do
      start_services()
      unquote(block)
      stop_services()
    end
  end

  require Logger

  @impl true
  @doc false
  def run(argv) do
    case parse_opts(argv) do
      {opts, [username, url]} ->
        opts = Map.new(opts)

        unless opts[:debug], do: Logger.configure(level: :info)

        with_services do
          with user = %Radiator.Auth.User{} <- Radiator.Auth.Register.get_user_by_name(username) do
            ShellIO.info([
              "Importing for user ",
              :bright,
              "#{user.name} <#{user.email}>",
              :reset,
              " with id ",
              :bright,
              "#{user.id}"
            ])

            metalove_podcast = Metalove.get_podcast(url)

            ShellIO.info([
              "Fetching feed from ",
              :bright,
              "#{metalove_podcast.main_feed_url}",
              :reset
            ])

            feed =
              Metalove.PodcastFeed.get_by_feed_url_await_all_pages(
                metalove_podcast.main_feed_url,
                120_000
              )

            if opts[:debug], do: IO.inspect(feed, pretty: true)

            ShellIO.info([
              "Found ",
              :bright,
              "#{length(feed.episodes)}",
              :reset,
              " episodes "
            ])

            network_name = opts[:network] || "#{user.name}'s Network"

            network = Radiator.Repo.get_by(Directory.Network, %{title: network_name})

            ShellIO.info(
              case network do
                network = %Directory.Network{} ->
                  ["Importing into existing network ", :bright, "#{network.title}", :reset]

                _ ->
                  [
                    :yellow,
                    "Importing ",
                    "creates network ",
                    :bright,
                    "#{network_name}",
                    :reset
                  ]
              end
            )

            unless opts[:preview] do
              network =
                case network do
                  network = %Directory.Network{} ->
                    network

                  _ ->
                    {:ok, network} = Editor.create_network(user, %{title: network_name})
                    network
                end

              {:ok, podcast} =
                Editor.Manager.create_podcast(
                  network,
                  %{
                    title: feed.title,
                    subtitle: feed.subtitle,
                    author: feed.author,
                    description: feed.description,
                    image: feed.image_url,
                    language: feed.language
                  }
                )

              feed.episodes
              |> Enum.map(fn episode_id -> Metalove.Episode.get_by_episode_id(episode_id) end)
              |> Enum.map(fn episode ->
                # todo: create enclosure (pull file? currently no model for external URLs)
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
              end)
              |> Enum.count(fn
                {:ok, _} -> true
                _ -> false
              end)
              |> case do
                count -> Logger.info(~s/Created #{count} episodes in "#{podcast.title}"/)
              end
            end
          end
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
