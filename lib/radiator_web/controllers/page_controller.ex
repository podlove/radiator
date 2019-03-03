defmodule RadiatorWeb.PageController do
  use RadiatorWeb, :controller

  def index(conn, _params) do
    render(conn, "index.html")
  end
end
