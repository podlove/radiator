defmodule RadiatorSupport.TrackingGenerator do
  @moduledoc """
  Generates tracking data.
  """

  alias Radiator.Repo
  alias Radiator.Directory

  alias Radiator.Directory.{
    Podcast,
    Episode
  }

  require Logger

  # file with one user agent per line
  # maybe store it externally and download? don't feel like versioning such a potentially big file
  @user_agents_file "lib/radiator_support/generator/data/user_agents.csv"

  def generate(count) do
    episodes =
      Directory.list_episodes(%{
        items_per_page: :unlimited
      })
      |> Repo.preload(podcast: :network)

    1..count
    |> Enum.each(fn _ ->
      generate_one(Enum.random(episodes))
    end)
  end

  def generate_one(episode = %Episode{published_at: published_at, podcast: podcast = %Podcast{}}) do
    datetime = get_random_date_since(published_at) |> DateTime.from_naive!("Etc/UTC")
    [audio_file | _] = episode.audio.audio_files

    Radiator.Tracking.Server.track_download(
      podcast: podcast,
      episode: episode,
      audio_file: audio_file,
      remote_ip: "127.0.0.1",
      user_agent: get_random_user_agent(),
      time: datetime,
      http_range: ""
    )
  end

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
    |> String.replace("\\;", ";")
  end
end
