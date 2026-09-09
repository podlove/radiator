defmodule Radiator.FeedsTest do
  use ExUnit.Case, async: true

  alias Radiator.FeedFixtures
  alias Radiator.Feeds
  alias Radiator.Feeds.Feed
  alias Radiator.Feeds.ParseError
  alias Radiator.Feeds.Response
  alias Radiator.StubFeedClient

  setup do
    StubFeedClient.reset()
    :ok
  end

  test "load/2 returns feed and response on 200" do
    StubFeedClient.put(
      {:ok,
       %Response{
         status: 200,
         body: FeedFixtures.read!("minimal.xml"),
         etag: ~s("abc"),
         last_modified: "Fri, 28 Aug 2026 17:14:26 GMT",
         final_url: "https://example.com/feed"
       }}
    )

    assert {:ok, %Feed{} = feed, %Response{etag: ~s("abc")}} =
             Feeds.load("https://example.com/feed")

    assert feed.channel.title == "Test Show"
  end

  test "load/2 passes 304 through without parsing" do
    StubFeedClient.put({:not_modified, %Response{status: 304, body: "", etag: ~s("abc")}})

    assert {:not_modified, %Response{status: 304}} = Feeds.load("https://example.com/feed")
  end

  test "load/2 forwards the parse error" do
    StubFeedClient.put({:ok, %Response{status: 200, body: "<html></html>"}})

    assert {:error, %ParseError{reason: :not_a_feed}} = Feeds.load("https://example.com/feed")
  end

  test "load/2 forwards a transport error" do
    StubFeedClient.put({:error, :timeout})

    assert {:error, :timeout} = Feeds.load("https://example.com/feed")
  end

  test "fetch/2 passes the options through to the client" do
    StubFeedClient.put({:ok, %Response{status: 200, body: ""}})

    assert {:ok, %Response{}} = Feeds.fetch("https://example.com/feed", etag: ~s("abc"))
    assert [{"https://example.com/feed", opts}] = StubFeedClient.calls()
    assert opts[:etag] == ~s("abc")
  end
end
