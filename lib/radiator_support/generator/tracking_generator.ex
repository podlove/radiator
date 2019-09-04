defmodule RadiatorSupport.TrackingGenerator do
  @moduledoc """
  Generates tracking data.
  """

  alias Radiator.Repo
  alias Radiator.Directory

  alias Radiator.Directory.{
    AudioPublication,
    Podcast,
    Episode
  }

  alias Radiator.Media.AudioFile

  require Logger

  @user_agents_file "lib/radiator_support/generator/data/user_agents.txt"
  @chunk_size 100

  @doc """
  Generates n downloads for any public episodes.
  """
  def generate(count, opts \\ []) do
    opts =
      opts
      |> Keyword.put_new(:verbose, false)
      |> Keyword.put_new(:animated, false)

    if Keyword.get(opts, :verbose) do
      Logger.configure(level: :debug)
    else
      Logger.configure(level: :info)
    end

    episodes =
      Directory.list_episodes(%{
        items_per_page: :unlimited
      })
      |> Enum.filter(fn episode -> length(episode.audio.audio_files) > 0 end)
      |> Repo.preload(podcast: :network)

    total_chunks = Float.ceil(count / @chunk_size) |> trunc

    1..count
    |> Stream.chunk_every(@chunk_size)
    |> Stream.with_index(1)
    |> Stream.each(fn {chunk, index} ->
      start = System.monotonic_time(:millisecond)
      chunk_length = length(chunk)

      Enum.each(chunk, fn _ ->
        generate_one(Enum.random(episodes))
      end)

      time_spent = System.monotonic_time(:millisecond) - start
      per_second = trunc(chunk_length / (time_spent / 1000))
      progress = Float.round(index / total_chunks * 100, 1)
      progress_string = progress |> Float.to_string() |> String.pad_leading(5, " ")

      remaining_seconds =
        Float.round((total_chunks - index) * @chunk_size / per_second) |> trunc()

      progress_log = IO.ANSI.blue() <> "[#{progress_string}%]" <> IO.ANSI.reset()

      time_to_finish_log =
        IO.ANSI.yellow() <>
          "time remaining: #{time_remaining(remaining_seconds)}" <> IO.ANSI.reset()

      per_second_log = IO.ANSI.green() <> "(#{per_second}/s)" <> IO.ANSI.reset()

      if Keyword.get(opts, :animated) do
        IO.write(IO.ANSI.clear())
        IO.write(IO.ANSI.home())
      end

      Logger.info(
        progress_log <>
          " Generated #{chunk_length} in #{time_spent}ms " <>
          per_second_log <>
          ", " <>
          time_to_finish_log
      )
    end)
    |> Stream.run()
  end

  def generate_one(episode = %Episode{published_at: published_at, podcast: podcast = %Podcast{}}) do
    datetime = get_random_date_since(published_at) |> DateTime.from_naive!("Etc/UTC")
    [audio_file | _] = episode.audio.audio_files

    Radiator.Tracking.Server.track_download(
      podcast: podcast,
      episode: episode,
      audio_file: audio_file,
      remote_ip: get_random_remote_ip(),
      user_agent: get_random_user_agent(),
      time: datetime,
      http_range: get_random_http_range()
    )
  end

  def generate_one(
        audio_publication = %AudioPublication{published_at: published_at},
        audio_file = %AudioFile{}
      ) do
    datetime = get_random_date_since(published_at) |> DateTime.from_naive!("Etc/UTC")

    Radiator.Tracking.Server.track_download(
      audio_publication: audio_publication,
      audio_file: audio_file,
      remote_ip: get_random_remote_ip(),
      user_agent: get_random_user_agent(),
      time: datetime,
      http_range: get_random_http_range()
    )
  end

  # this could get a time on the date of "since" before given time
  # and a few hours into the future from now, but that's ok?
  def get_random_date_since(since = %DateTime{}) do
    from = since |> DateTime.to_date()
    to = DateTime.utc_now() |> DateTime.to_date()

    date = Date.range(from, to) |> Enum.random()

    hour = 0..23 |> Enum.random()
    minute = 0..59 |> Enum.random()
    second = 0..59 |> Enum.random()

    NaiveDateTime.from_erl!({{date.year, date.month, date.day}, {hour, minute, second}})
  end

  def get_random_user_agent() do
    File.read!(@user_agents_file)
    |> String.trim()
    |> String.split("\n")
    |> Enum.random()
  end

  def get_random_remote_ip() do
    "127.0.0.1"
  end

  def get_random_http_range() do
    ""
  end

  defp time_remaining(seconds) when seconds < 60 do
    "#{seconds}s"
  end

  defp time_remaining(seconds) do
    minutes = trunc(seconds / 60)
    seconds = Integer.mod(seconds, 60)

    "#{minutes}m #{seconds}s"
  end
end
