defmodule RadiatorWeb.Public.FeedController do
  use RadiatorWeb, :controller

  alias Radiator.Directory
  alias Radiator.Feed.Builder

  @items_per_page 50

  action_fallback RadiatorWeb.FallbackController

  require Logger

  def action(conn, _) do
    args = [conn, conn.params, conn.assigns]
    apply(__MODULE__, action_name(conn), args)
  end

  def show(conn, %{"page" => page}, %{current_podcast: podcast}) do
    with episodes <-
           Directory.list_episodes(%{podcast: podcast, order_by: :published_at, order: :desc})
           |> Directory.reject_invalid_episodes(),
         page <- String.to_integer(page) do
      # I wonder where I could extract that to.
      #  - Directory.Feed context would be my first choice but that
      # should not know about conn. And if I pass in the URL map
      # I don't gain much.
      #  - View Layer? That's too late in the stack I think?

      Logger.debug("I am here")

      xml =
        Builder.new(
          %{
            podcast: podcast,
            episodes: episodes,
            urls: %{
              main: self_url(conn, podcast),
              self: self_url(conn, podcast),
              page_template: page_url_template(conn, podcast)
            }
          },
          items_per_page: @items_per_page,
          page: page
        )
        |> Builder.render()

      conn
      |> put_resp_content_type("text/xml")
      |> send_resp(200, xml)
    end
  end

  def show(_, %{"page" => _page}, _), do: {:error, :not_found}
  # todo: enforce canonical URL when ?page=1 is set
  def show(conn, params, assigns), do: show(conn, Map.put(params, "page", "1"), assigns)

  defp self_url(conn, podcast) do
    Routes.feed_url(conn, :show, podcast.slug)
  end

  defp page_url_template(conn, podcast) do
    self_url(conn, podcast)
    |> URI.parse()
    |> Map.put(:query, "page=:page:")
    |> URI.to_string()
  end
end
