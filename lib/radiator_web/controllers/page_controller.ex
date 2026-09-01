defmodule RadiatorWeb.PageController do
  use RadiatorWeb, :controller

  def imprint(conn, _params) do
    conn
    |> assign(:page_title, "Impressum")
    |> render(:imprint)
  end
end
