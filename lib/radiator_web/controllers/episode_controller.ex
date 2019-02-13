defmodule RadiatorWeb.EpisodeController do
  use RadiatorWeb, :controller

  alias Radiator.Directory
  alias Radiator.Directory.{Episode, Podcast}

  action_fallback RadiatorWeb.FallbackController

  def index(conn, %{"podcast_id" => podcast_id}) do
    with %Podcast{} = podcast <- Directory.get_podcast!(podcast_id),
         episodes <- Directory.list_episodes(podcast) do
      render(conn, "index.json", episodes: episodes)
    end
  end

  def create(conn, %{"podcast_id" => podcast_id, "episode" => episode_params}) do
    with %Podcast{} = podcast <- Directory.get_podcast!(podcast_id),
         {:ok, %Episode{} = episode} <- Directory.create_episode(podcast, episode_params) do
      conn
      |> put_status(:created)
      |> put_resp_header(
        "location",
        Routes.podcast_episode_path(conn, :show, podcast_id, episode)
      )
      |> render("show.json", episode: episode)
    end
  end

  def show(conn, %{"id" => id}) do
    episode = Directory.get_episode!(id)
    render(conn, "show.json", episode: episode)
  end

  def update(conn, %{"id" => id, "episode" => episode_params}) do
    episode = Directory.get_episode!(id)

    with {:ok, %Episode{} = episode} <- Directory.update_episode(episode, episode_params) do
      render(conn, "show.json", episode: episode)
    end
  end

  def delete(conn, %{"id" => id}) do
    episode = Directory.get_episode!(id)

    with {:ok, %Episode{}} <- Directory.delete_episode(episode) do
      send_resp(conn, :no_content, "")
    end
  end
end
