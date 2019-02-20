defmodule RadiatorWeb.PageController do
  use RadiatorWeb, :controller

  def index(conn, _params) do
    render(conn, "index.html")
  end

  def sketch_podcasts(conn, _params) do
    render(conn, "sketch_podcasts.html")
  end

  def sketch_podcasts_create(conn, _params) do
    render(conn, "sketch_podcasts_create.html")
  end
end
