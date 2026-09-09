defmodule Radiator.Feeds.Client.ReqClientTest do
  use ExUnit.Case, async: true

  alias Radiator.Feeds.Client.ReqClient

  @xml ~s(<rss version="2.0"><channel><title>X</title></channel></rss>)

  defp respond(conn, status, body, headers) do
    headers
    |> Enum.reduce(conn, fn {name, value}, acc ->
      Plug.Conn.put_resp_header(acc, name, value)
    end)
    |> Plug.Conn.send_resp(status, body)
  end

  defp fetch(plug, opts \\ []),
    do: ReqClient.fetch("https://example.com/feed", [plug: plug] ++ opts)

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

      assert {:not_modified, response} = fetch(plug)
      assert response.status == 304
    end

    test "rejects a non-xml content type" do
      plug = fn conn -> respond(conn, 200, "<html/>", [{"content-type", "text/html"}]) end

      assert fetch(plug) == {:error, {:unexpected_content_type, "text/html"}}
    end

    test "reports Retry-After on 429" do
      plug = fn conn -> respond(conn, 429, "", [{"retry-after", "120"}]) end

      assert fetch(plug) == {:error, {:http_status, 429, 120}}
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

  describe "final_url" do
    test "records the target of a redirect, not the url that was asked for" do
      plug = fn conn ->
        case conn.request_path do
          "/feed" -> respond(conn, 301, "", [{"location", "https://example.com/moved.xml"}])
          "/moved.xml" -> respond(conn, 200, @xml, [{"content-type", "application/rss+xml"}])
        end
      end

      assert {:ok, response} = fetch(plug)
      assert response.final_url == "https://example.com/moved.xml"
    end

    test "records the requested url when nothing redirects" do
      plug = fn conn -> respond(conn, 200, @xml, [{"content-type", "application/rss+xml"}]) end

      assert {:ok, response} = fetch(plug)
      assert response.final_url == "https://example.com/feed"
    end
  end

  describe "retry_after/1" do
    # Built through the constructor rather than as a struct literal: `headers`
    # is a `Req.Fields` map, and the constructor is what normalises it.
    defp response(headers), do: Req.Response.new(status: 429, headers: headers, body: "")

    test "reads a numeric Retry-After" do
      assert ReqClient.retry_after(response(%{"retry-after" => ["120"]})) == 120
    end

    test "ignores surrounding whitespace" do
      assert ReqClient.retry_after(response(%{"retry-after" => [" 60 "]})) == 60
    end

    test "returns nil without the header" do
      assert ReqClient.retry_after(response(%{})) == nil
    end

    test "returns nil for the http-date form" do
      assert ReqClient.retry_after(
               response(%{"retry-after" => ["Wed, 09 Sep 2026 07:00:00 GMT"]})
             ) ==
               nil
    end

    test "returns nil for zero and for garbage" do
      assert ReqClient.retry_after(response(%{"retry-after" => ["0"]})) == nil
      assert ReqClient.retry_after(response(%{"retry-after" => ["soon"]})) == nil
    end
  end
end
