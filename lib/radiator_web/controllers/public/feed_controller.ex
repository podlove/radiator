defmodule RadiatorWeb.Public.FeedController do
  use RadiatorWeb, :controller

  alias Radiator.Directory
  alias Radiator.Directory.Podcast
  alias Radiator.Feed.Builder
  alias Radiator.Feed.Generator

  action_fallback RadiatorWeb.FallbackController

  require Logger

  def action(conn, _) do
    args = [conn, conn.params, conn.assigns]
    apply(__MODULE__, action_name(conn), args)
  end

  def show(conn, %{"page" => page}, %{current_podcast: podcast}) do
    with xml <- Generator.generate(podcast.id, page: String.to_integer(page)) do
      conn
      |> put_resp_content_type("text/xml")
      |> send_resp(200, xml)
    end
  end

  def show(_, %{"page" => _page}, _), do: {:error, :not_found}
  # todo: enforce canonical URL when ?page=1 is set
  def show(conn, params, assigns), do: show(conn, Map.put(params, "page", "1"), assigns)
end
