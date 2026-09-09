defmodule Radiator.Feeds.ParserTest do
  use ExUnit.Case, async: true

  alias Radiator.FeedFixtures
  alias Radiator.Feeds.Feed
  alias Radiator.Feeds.ParseError
  alias Radiator.Feeds.Parser

  test "reads the fixture" do
    assert {:ok, %Feed{} = feed} = Parser.parse(FeedFixtures.read!("minimal.xml"))
    assert feed.channel.title == "Test Show"
    assert length(feed.items) == 5
  end

  test "reports malformed XML" do
    assert {:error, %ParseError{reason: :malformed_xml, message: message}} =
             Parser.parse("<rss><channel><title>offen</rss>")

    assert is_binary(message)
  end

  test "reports well-formed XML that is not a feed" do
    assert {:error, %ParseError{reason: :not_a_feed}} =
             Parser.parse(~s(<?xml version="1.0"?><html><body>Fehlerseite</body></html>))
  end

  test "reports an empty body" do
    assert {:error, %ParseError{reason: :malformed_xml}} = Parser.parse("")
  end

  test "accepts a feed without items" do
    xml = ~s(<rss version="2.0"><channel><title>Leer</title></channel></rss>)

    assert {:ok, %Feed{items: [], channel: %{title: "Leer"}}} = Parser.parse(xml)
  end
end
