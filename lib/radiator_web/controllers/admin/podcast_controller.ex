defmodule RadiatorWeb.Admin.PodcastController do
  use RadiatorWeb, :controller

  alias Radiator.Directory
  alias Radiator.Directory.Podcast

  def index(conn, _params) do
    podcasts = Directory.list_podcasts_with_episode_counts(conn.assigns.current_network)
    render(conn, "index.html", podcasts: podcasts)
  end

  def new(conn, _params) do
    changeset = Directory.change_podcast(%Podcast{})
    render(conn, "new.html", changeset: changeset)
  end

  def create(conn, %{"podcast" => podcast_params}) do
    case Directory.create_podcast(conn.assigns.current_network, podcast_params) do
      {:ok, podcast} ->
        conn
        |> put_flash(:info, "podcast created successfully.")
        |> redirect(
          to: Routes.admin_network_podcast_path(conn, :show, podcast.network_id, podcast)
        )

      {:error, %Ecto.Changeset{} = changeset} ->
        render(conn, "new.html", changeset: changeset)
    end
  end

  def show(conn, %{"id" => id}) do
    podcast = Directory.get_podcast!(id)

    draft_episodes =
      Directory.list_episodes(%{
        podcast: podcast,
        published: false,
        order_by: [desc: :id]
      })

    published_episodes =
      Directory.list_episodes(%{
        podcast: podcast,
        published: true,
        order_by: [desc: :published_at]
      })

    render(conn, "show.html",
      podcast: podcast,
      published_episodes: published_episodes,
      draft_episodes: draft_episodes
    )
  end

  def edit(conn, %{"id" => id}) do
    podcast = Directory.get_podcast!(id)
    changeset = Directory.change_podcast(podcast)

    render(conn, "edit.html", podcast: podcast, changeset: changeset)
  end

  def update(conn, %{"id" => id, "podcast" => podcast_params}) do
    podcast = Directory.get_podcast!(id)

    case Directory.update_podcast(podcast, podcast_params) do
      {:ok, podcast} ->
        conn
        |> put_flash(:info, "podcast updated successfully.")
        |> redirect(
          to: Routes.admin_network_podcast_path(conn, :show, podcast.network_id, podcast)
        )

      {:error, %Ecto.Changeset{} = changeset} ->
        render(conn, "edit.html", podcast: podcast, changeset: changeset)
    end
  end
end
