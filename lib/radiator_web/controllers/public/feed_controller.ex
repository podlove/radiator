defmodule RadiatorWeb.Public.FeedController do
  use RadiatorWeb, :controller

  alias Radiator.Feed

  action_fallback RadiatorWeb.FallbackController

  require Logger

  def action(conn, _) do
    args = [conn, conn.params, conn.assigns]
    apply(__MODULE__, action_name(conn), args)
  end

  @doc """
  FIXME: The controller doesn't know if the feed file is actually available.
  And I think it shouldn't (a proper check before redirect would be expensive).
  The way it should be is that a podcast is only really published/public once the
  feed is available. Which means publication is a multi-step-process?

  - generate the feed
  - verify all is good
  - set podcast status to published

  If we don't enforce this there may be podcasts for a few seconds/minutes without a feed.
  """
  def show(conn, %{"page" => page, "type" => type}, %{current_podcast: podcast}) do
    with true <- Enum.member?(Feed.Storage.types() |> Enum.map(&to_string/1), type) do
      # todo: track request before redirecting
      conn
      |> put_status(307)
      |> redirect(
        external:
          Feed.Storage.url(
            podcast_id: podcast.id,
            type: type,
            page: String.to_integer(page)
          )
      )
    else
      _ -> send_resp(conn, 400, "Invalid Feed Type")
    end
  end

  def show(conn, %{"page" => page}, %{current_podcast: podcast}) do
    conn
    |> redirect(to: Routes.feed_path(conn, :show, podcast.slug, "mp3"))

    conn
    |> put_status(307)
    |> redirect(external: Feed.Storage.url(podcast_id: podcast.id, page: String.to_integer(page)))
  end

  def show(_, %{"page" => _page}, _), do: {:error, :not_found}
  # todo: enforce canonical URL when ?page=1 is set
  def show(conn, params, assigns), do: show(conn, Map.put(params, "page", "1"), assigns)
end
