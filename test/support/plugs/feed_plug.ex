defmodule Radiator.FeedPlug do
  @moduledoc """
  A feed server for tests, answering behind `Req.Test`.

  Every response the sync can run into lives here, keyed by path, so a test
  only has to pick the URL:

    * `/feed` — the fixture feed. Answers 304 when the request carries the
      validators from a previous 200, the way a real server would.
    * `/gone` — 404 with an HTML error page.
    * `/busy` — 429 with `Retry-After: 120`.
    * `/unavailable` — 503 with `Retry-After: 900`.
    * `/slow` — a transport timeout.
    * `/html` — 200, but an HTML page instead of a feed.
    * `/not-a-feed` — 200 with an XML content type, but no channel inside.
    * `/truncated` — 200 with a feed cut off midway.

  Anything else is a 404.
  """

  import Plug.Conn

  alias Radiator.FeedFixtures

  @etag ~s("v1")
  @last_modified "Fri, 28 Aug 2026 17:14:26 GMT"

  @html """
  <!DOCTYPE html>
  <html lang="en">
    <head><title>Error 404 (Not Found)</title></head>
    <body><h1>Error 404</h1></body>
  </html>
  """

  def init(opts), do: opts

  def call(%{request_path: "/feed"} = conn, _opts) do
    if fresh?(conn) do
      conn |> put_validators() |> send_resp(304, "")
    else
      conn |> put_validators() |> feed(FeedFixtures.read!("minimal.xml"))
    end
  end

  def call(%{request_path: "/busy"} = conn, _opts) do
    conn |> put_resp_header("retry-after", "120") |> send_resp(429, "")
  end

  def call(%{request_path: "/unavailable"} = conn, _opts) do
    conn |> put_resp_header("retry-after", "900") |> send_resp(503, "")
  end

  def call(%{request_path: "/slow"} = conn, _opts) do
    Req.Test.transport_error(conn, :timeout)
  end

  def call(%{request_path: "/html"} = conn, _opts) do
    Req.Test.html(conn, @html)
  end

  def call(%{request_path: "/not-a-feed"} = conn, _opts) do
    feed(conn, @html)
  end

  def call(%{request_path: "/truncated"} = conn, _opts) do
    feed(conn, "<rss><channel><title>Cut")
  end

  def call(conn, _opts) do
    conn |> put_status(404) |> Req.Test.html(@html)
  end

  defp fresh?(conn) do
    get_req_header(conn, "if-none-match") == [@etag] or
      get_req_header(conn, "if-modified-since") == [@last_modified]
  end

  defp put_validators(conn) do
    conn
    |> put_resp_header("etag", @etag)
    |> put_resp_header("last-modified", @last_modified)
  end

  defp feed(conn, body) do
    conn
    |> put_resp_content_type("application/rss+xml")
    |> send_resp(200, body)
  end
end
