defmodule Radiator.FeedsTest do
  use ExUnit.Case, async: true

  alias Radiator.Feeds
  alias Radiator.Feeds.Client.ReqClient
  alias Radiator.Feeds.Feed
  alias Radiator.Feeds.ParseError
  alias Radiator.Feeds.Response

  setup do
    Req.Test.stub(ReqClient, Radiator.FeedPlug)
    :ok
  end

  test "load/2 returns feed and response on 200" do
    assert {:ok, %Feed{channel: %{title: "Test Show"}}, %Response{etag: ~s("v1")}} =
             Feeds.load("https://example.com/feed")
  end

  test "load/2 sends the validators and passes a 304 through without parsing" do
    assert {:not_modified, %Response{etag: ~s("v1")}} =
             Feeds.load("https://example.com/feed", etag: ~s("v1"))
  end

  test "load/2 forwards the parse error" do
    assert {:error, %ParseError{reason: :not_a_feed}} =
             Feeds.load("https://example.com/not-a-feed")
  end

  test "load/2 forwards a transport error" do
    Req.Test.stub(ReqClient, &Req.Test.transport_error(&1, :econnrefused))

    assert {:error, %Req.TransportError{reason: :econnrefused}} =
             Feeds.load("https://example.com/feed")
  end
end
