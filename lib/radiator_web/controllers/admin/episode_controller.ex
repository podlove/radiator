defmodule RadiatorWeb.Admin.EpisodeController do
  use RadiatorWeb, :controller

  alias Radiator.Directory
  alias Radiator.Directory.Episode

  plug :assign_podcast when action in [:new, :create]

  defp assign_podcast(conn, _) do
    assign(conn, :podcast, Directory.get_podcast!(conn.params["podcast_id"]))
  end

  def new(conn, _params) do
    changeset = Directory.change_episode(%Episode{})
    render(conn, "new.html", changeset: changeset)
  end

  def create(conn, %{"episode" => episode_params}) do
    podcast = conn.assigns[:podcast]

    case Directory.create_episode(podcast, episode_params) do
      {:ok, episode} ->
        conn
        |> put_flash(:info, "episode created successfully.")
        |> redirect(to: Routes.admin_podcast_episode_path(conn, :show, podcast, episode))

      {:error, %Ecto.Changeset{} = changeset} ->
        render(conn, "new.html", changeset: changeset)
    end
  end

  def show(conn, %{"id" => id}) do
    episode = Directory.get_episode!(id)

    render(conn, "show.html", episode: episode)
  end

  def edit(conn, %{"id" => id}) do
    episode = Directory.get_episode!(id)
    changeset = Directory.change_episode(episode)

    render(conn, "edit.html", episode: episode, changeset: changeset)
  end

  def update(conn, %{"id" => id, "episode" => episode_params}) do
    episode = Directory.get_episode!(id)

    case Directory.update_episode(episode, episode_params) do
      {:ok, episode} ->
        conn
        |> put_flash(:info, "episode updated successfully.")
        |> redirect(to: Routes.admin_podcast_episode_path(conn, :show, episode.podcast, episode))

      {:error, %Ecto.Changeset{} = changeset} ->
        render(conn, "edit.html", episode: episode, changeset: changeset)
    end
  end
end
