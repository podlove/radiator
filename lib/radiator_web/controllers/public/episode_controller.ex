defmodule RadiatorWeb.Public.EpisodeController do
  use RadiatorWeb, :controller

  require Logger

  alias Radiator.Directory
  alias Radiator.Directory.{Podcast, Episode}

  action_fallback RadiatorWeb.FallbackController

  def index(conn, %{"podcast_slug" => podcast_slug}) do
    podcast =
      Directory.get_podcast_by_slug(podcast_slug)
      |> Directory.preload_episodes()

    render(conn, "index.html", podcast: podcast, episodes: podcast.episodes)
  end

  def show(conn, %{"podcast_slug" => podcast_slug, "episode_slug" => episode_slug}) do
    with podcast = %Podcast{} <- Directory.get_podcast_by_slug(podcast_slug),
         episode = %Episode{} <-
           Directory.get_episode_by_slug(podcast, episode_slug) do
      render(conn, "show.html", episode: episode)
    else
      _ ->
        {:error, :not_found}
    end
  end
end
