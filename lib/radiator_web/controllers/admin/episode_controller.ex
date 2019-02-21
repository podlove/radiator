defmodule RadiatorWeb.Admin.EpisodeController do
  use RadiatorWeb, :controller

  alias Radiator.Directory
  # alias Radiator.Directory.{Episode, Podcast}

  def show(conn, %{"id" => id}) do
    episode = Directory.get_episode!(id)

    render(conn, "show.html", episode: episode)
  end
end
