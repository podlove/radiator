defmodule RadiatorWeb.Api.PodcastController do
  use RadiatorWeb, :controller

  alias Radiator.Directory
  alias Radiator.Directory.Podcast
  alias Radiator.Directory.Editor

  action_fallback RadiatorWeb.Api.FallbackController

  def index(conn, _params) do
    podcasts = Directory.list_podcasts()
    render(conn, "index.json", podcasts: podcasts)
  end

  def create(conn, %{"podcast" => podcast_params, "network_id" => network_id}) do
    network = Directory.get_network(network_id)

    with {:ok, %Podcast{} = podcast} <- Editor.Manager.create_podcast(network, podcast_params) do
      conn
      |> put_status(:created)
      |> put_resp_header("location", Routes.api_podcast_path(conn, :show, podcast))
      |> render("show.json", podcast: podcast)
    end
  end

  def show(conn, %{"id" => id}) do
    podcast = Directory.get_podcast!(id)
    render(conn, "show.json", podcast: podcast)
  end

  def update(conn, %{"id" => id, "podcast" => podcast_params}) do
    podcast = Directory.get_podcast!(id)

    with {:ok, %Podcast{} = podcast} <- Editor.Manager.update_podcast(podcast, podcast_params) do
      render(conn, "show.json", podcast: podcast)
    end
  end

  def delete(conn, %{"id" => id}) do
    podcast = Directory.get_podcast!(id)

    with {:ok, %Podcast{}} <- Editor.Manager.delete_podcast(podcast) do
      send_resp(conn, :no_content, "")
    end
  end
end
