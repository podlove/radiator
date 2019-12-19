defmodule RadiatorWeb.Admin.EpisodeController do
  use RadiatorWeb, :controller

  require Logger

  alias Radiator.Storage
  alias Radiator.Directory
  alias Radiator.Directory.{Editor, Episode, Audio}
  alias Radiator.Reporting.Statistics

  plug :assign_podcast when action in [:new, :create, :update]

  action_fallback RadiatorWeb.FallbackController

  defp assign_podcast(conn, _) do
    {:ok, podcast} = Editor.get_podcast(current_user(conn), conn.params["podcast_id"])

    conn
    |> assign(:podcast, podcast)
  end

  def new(conn, _params) do
    changeset = Editor.Manager.change_episode(%Episode{})
    render(conn, "new.html", changeset: changeset)
  end

  def create(conn, %{"episode" => episode_params}) do
    podcast = conn.assigns[:podcast]
    upload = Map.get(episode_params, "enclosure")
    file_slot = Audio.slot_name_from_content_type(upload.content_type)

    case Radiator.Directory.Editor.EpisodeManager.create_episode_with_upload(
           podcast,
           episode_params,
           %{},
           upload,
           file_slot
         ) do
      {:ok, %{episode: episode}} ->
        conn
        |> put_flash(:info, "episode created successfully.")
        |> redirect(
          to:
            Routes.admin_network_podcast_episode_path(
              conn,
              :show,
              podcast.network_id,
              podcast,
              episode
            )
        )

      {:error, %Ecto.Changeset{} = changeset} ->
        render(conn, "new.html", changeset: changeset)
    end
  end

  def show(conn, %{"id" => id}) do
    user = current_user(conn)

    {:ok, episode} = Editor.get_episode(user, id)

    episode = episode |> Directory.preload_for_episode()

    total_downloads =
      Statistics.get(%{
        subject: episode,
        time_type: :total,
        metric: :downloads
      })

    render(conn, "show.html", episode: episode, total_downloads: total_downloads)
  end

  def edit(conn, %{"id" => id}) do
    user = current_user(conn)

    {:ok, episode} = Editor.get_episode(user, id)
    changeset = Editor.Manager.change_episode(episode)

    render(conn, "edit.html", episode: episode, changeset: changeset)
  end

  def update(conn, %{"id" => id, "episode" => episode_params}) do
    user = current_user(conn)

    {:ok, episode} = Editor.get_episode(user, id)

    case Editor.Manager.update_episode(episode, episode_params) do
      {:ok, episode} ->
        conn
        |> put_flash(:info, "episode updated successfully.")
        |> redirect(
          to:
            Routes.admin_network_podcast_episode_path(
              conn,
              :show,
              episode.podcast.network_id,
              episode.podcast,
              episode
            )
        )

      {:error, %Ecto.Changeset{} = changeset} ->
        render(conn, "edit.html", episode: episode, changeset: changeset)
    end
  end

  def process_upload(_conn, podcast, params) do
    if upload = params["enclosure"] do
      {:ok, %File.Stat{size: size}} = File.stat(upload.path)
      path = Storage.file_path(podcast, upload.filename)
      Storage.upload_file(upload.path, path, upload.content_type)

      enclosure_url = Storage.file_url(podcast, upload.filename)
      {:ok, enclosure_url, upload.content_type, size}
    else
      :noupload
    end
  end

  def publish(conn, %{"network_id" => network_id, "episode_id" => id}) do
    with user <- current_user(conn),
         {:ok, episode} <- Editor.get_episode(user, id),
         {:ok, _episode} <- Editor.publish_episode(user, episode) do
      redirect(conn,
        to:
          Routes.admin_network_podcast_episode_path(
            conn,
            :show,
            network_id,
            episode.podcast_id,
            episode
          )
      )
    end
  end
end
