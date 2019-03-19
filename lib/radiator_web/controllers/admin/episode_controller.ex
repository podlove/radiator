defmodule RadiatorWeb.Admin.EpisodeController do
  use RadiatorWeb, :controller

  alias Radiator.Directory
  alias Radiator.Storage
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

    episode_params =
      case process_upload(conn, episode_params) do
        {:ok, enclosure_url, enclosure_type, enclosure_size} ->
          episode_params
          |> Map.put("enclosure_url", enclosure_url)
          |> Map.put("enclosure_type", enclosure_type)
          |> Map.put("enclosure_length", enclosure_size)

        _ ->
          episode_params
      end

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

    episode_params =
      case process_upload(conn, episode_params) do
        {:ok, enclosure_url, enclosure_type, enclosure_size} ->
          episode_params
          |> Map.put("enclosure_url", enclosure_url)
          |> Map.put("enclosure_type", enclosure_type)
          |> Map.put("enclosure_length", enclosure_size)

        _ ->
          episode_params
      end

    case Directory.update_episode(episode, episode_params) do
      {:ok, episode} ->
        conn
        |> put_flash(:info, "episode updated successfully.")
        |> redirect(to: Routes.admin_podcast_episode_path(conn, :show, episode.podcast, episode))

      {:error, %Ecto.Changeset{} = changeset} ->
        render(conn, "edit.html", episode: episode, changeset: changeset)
    end
  end

  def process_upload(conn, params) do
    import SweetXml

    if upload = params["enclosure"] do
      {:ok, %File.Stat{size: size}} = File.stat(upload.path)
      %{body: xml} = Storage.upload_file(upload.path, upload.filename, upload.content_type)

      file_key = xml |> xpath(~x"//Key/text()"s)
      enclosure_url = Storage.file_url(file_key)
      {:ok, enclosure_url, upload.content_type, size}
    else
      :noupload
    end
  end
end
