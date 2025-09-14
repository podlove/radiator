defmodule RadiatorWeb.PageController do
  use RadiatorWeb, :controller

  def home(conn, _params) do
    render(conn, :home)
  end
end
