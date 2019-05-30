defmodule RadiatorWeb.Admin.PodcastImportController do
  use RadiatorWeb, :controller

  alias Radiator.Directory.Editor

  def new(conn, _params) do
    render(conn, "new.html")
  end

  # TODO
  # - needs error handling
  # - should be done async with waiting animation (progress?) and notice/redirect when done
  def create(conn, %{"feed" => %{"feed_url" => url}}) do
    user = authenticated_user(conn)
    network = conn.assigns.current_network

    {:ok, %{podcast: podcast}} = Radiator.Directory.Importer.import_from_url(user, network, url)

    redirect(conn, to: Routes.admin_network_podcast_path(conn, :show, podcast.network_id, podcast))
  end
end
