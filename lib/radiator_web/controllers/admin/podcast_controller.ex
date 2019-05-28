defmodule RadiatorWeb.Admin.PodcastController do
  use RadiatorWeb, :controller

  alias Radiator.Directory
  alias Radiator.Directory.Podcast
  alias Radiator.Directory.Editor

  def index(conn, _params) do
    me = get_me(conn)
    podcasts = Editor.list_podcasts_with_episode_counts(me, conn.assigns.current_network)
    render(conn, "index.html", podcasts: podcasts)
  end

  def new(conn, _params) do
    # FIXME: change the source for the changesets
    changeset = Editor.Manager.change_podcast(%Podcast{})
    render(conn, "new.html", changeset: changeset)
  end

  def create(conn, %{"podcast" => podcast_params}) do
    me = get_me(conn)

    case Editor.create_podcast(me, conn.assigns.current_network, podcast_params) do
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
    me = get_me(conn)
    {:ok, podcast} = Editor.get_podcast(me, id)

    # FIXME: only draft episodes, probably bring over the directory options semantic
    draft_episodes = Editor.list_episodes(me, podcast)

    published_episodes =
      Directory.list_episodes(%{
        podcast: podcast,
        order_by: [desc: :published_at]
      })

    render(conn, "show.html",
      podcast: podcast,
      published_episodes: published_episodes,
      draft_episodes: draft_episodes
    )
  end

  def edit(conn, %{"id" => id}) do
    me = get_me(conn)
    podcast = Editor.get_podcast(me, id)
    changeset = Editor.Manager.change_podcast(podcast)

    render(conn, "edit.html", podcast: podcast, changeset: changeset)
  end

  def update(conn, %{"id" => id, "podcast" => podcast_params}) do
    me = get_me(conn)
    podcast = Editor.get_podcast(me, id)

    case Editor.Manager.update_podcast(podcast, podcast_params) do
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
