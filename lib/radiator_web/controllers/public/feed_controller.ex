defmodule RadiatorWeb.Public.FeedController do
  use RadiatorWeb, :controller

  alias Radiator.Feed

  action_fallback RadiatorWeb.FallbackController

  require Logger

  def action(conn, _) do
    args = [conn, conn.params, conn.assigns]
    apply(__MODULE__, action_name(conn), args)
  end

  def show(conn, %{"page" => page}, %{current_podcast: podcast}) do
    # todo: track request before redirecting
    conn
    |> put_status(307)
    |> redirect(external: Feed.Storage.url(podcast_id: podcast.id, page: String.to_integer(page)))
  end

  def show(_, %{"page" => _page}, _), do: {:error, :not_found}
  # todo: enforce canonical URL when ?page=1 is set
  def show(conn, params, assigns), do: show(conn, Map.put(params, "page", "1"), assigns)
end
