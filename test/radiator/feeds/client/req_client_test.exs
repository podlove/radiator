defmodule Radiator.Feeds.Client.ReqClientTest do
  use ExUnit.Case, async: true

  alias Radiator.Feeds.Client.ReqClient
  alias Radiator.Feeds.Response

  @xml ~s(<rss version="2.0"><channel><title>X</title></channel></rss>)

  defp respond(conn, status, body, headers) do
    headers
    |> Enum.reduce(conn, fn {name, value}, acc ->
      Plug.Conn.put_resp_header(acc, name, value)
    end)
    |> Plug.Conn.send_resp(status, body)
  end

  # The test config routes the client through `Req.Test`; each test stubs the
  # server it wants to talk to.
  defp fetch(plug, opts \\ []) do
    Req.Test.stub(ReqClient, plug)
    ReqClient.fetch("https://example.com/feed", opts)
  end

  describe "plain responses" do
    test "reads the body and the validators" do
      plug = fn conn ->
        respond(conn, 200, @xml, [
          {"content-type", "application/rss+xml"},
          {"etag", ~s("v1")},
          {"last-modified", "Fri, 28 Aug 2026 17:14:26 GMT"}
        ])
      end

      assert {:ok, response} = fetch(plug)
      assert response.body == @xml
      assert response.etag == ~s("v1")
      assert response.last_modified == "Fri, 28 Aug 2026 17:14:26 GMT"
    end

    test "passes 304 through without a body" do
      plug = fn conn -> respond(conn, 304, "", [{"etag", ~s("v1")}]) end

      assert {:not_modified, %Response{etag: ~s("v1")}} = fetch(plug)
    end

    test "rejects a non-xml content type" do
      plug = fn conn -> respond(conn, 200, "<html/>", [{"content-type", "text/html"}]) end

      assert fetch(plug) == {:error, {:unexpected_content_type, "text/html"}}
    end

    test "reports Retry-After on 429, whitespace included" do
      plug = fn conn -> respond(conn, 429, "", [{"retry-after", " 120 "}]) end

      assert fetch(plug) == {:error, {:http_status, 429, 120}}
    end

    # The http-date form and garbage both fall back to exponential backoff.
    test "reports a 503 without a usable Retry-After as nil" do
      plug = fn conn ->
        respond(conn, 503, "", [{"retry-after", "Wed, 09 Sep 2026 07:00:00 GMT"}])
      end

      assert fetch(plug) == {:error, {:http_status, 503, nil}}
    end

    test "reports a plain status without Retry-After" do
      plug = fn conn -> respond(conn, 404, "", []) end

      assert fetch(plug) == {:error, {:http_status, 404}}
    end
  end

  describe "encoding" do
    # Req's own `compressed` step steps aside as soon as `into:` streams the
    # body, and so does its decompression. Rather than reimplementing gzip, the
    # client asks for the identity encoding and lets the size limit do its job.
    test "does not ask for a compressed body" do
      test_pid = self()

      plug = fn conn ->
        send(test_pid, {:accept_encoding, Plug.Conn.get_req_header(conn, "accept-encoding")})

        respond(conn, 200, @xml, [{"content-type", "application/rss+xml"}])
      end

      assert {:ok, _response} = fetch(plug)
      assert_receive {:accept_encoding, []}
    end
  end

  describe "size limit" do
    test "refuses a body larger than max_bytes" do
      plug = fn conn ->
        respond(conn, 200, String.duplicate("a", 5_000), [
          {"content-type", "application/rss+xml"}
        ])
      end

      assert fetch(plug, max_bytes: 1_000) == {:error, :feed_too_large}
    end
  end
end
