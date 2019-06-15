defmodule RadiatorWeb.Public.EpisodeController do
  use RadiatorWeb, :controller

  require Logger

  alias Radiator.Directory
  alias Radiator.Directory.{Podcast, Episode, Audio}

  def index(conn, %{"podcast_slug" => podcast_slug}) do
    podcast =
      Directory.get_podcast_by_slug(podcast_slug)
      |> Directory.preload_episodes()

    render(conn, "index.html", podcast: podcast, episodes: podcast.episodes)
  end

  def show(conn, %{"podcast_slug" => podcast_slug, "episode_slug" => episode_slug}) do
    podcast = Directory.get_podcast_by_slug(podcast_slug)

    episode = Directory.get_episode_by_slug(podcast, episode_slug)

    render(conn, "show.html", episode: episode)
  end
end
