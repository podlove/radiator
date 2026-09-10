defmodule Radiator.Feeds.Parser.HandlerChildrenTest do
  use ExUnit.Case, async: true

  alias Radiator.FeedFixtures
  alias Radiator.Feeds.Feed.Chapter
  alias Radiator.Feeds.Feed.Person
  alias Radiator.Feeds.Feed.Transcript
  alias Radiator.Feeds.Parser.Handler

  setup do
    {:ok, state} =
      Saxy.parse_string(FeedFixtures.read!("minimal.xml"), Handler, Handler.initial_state())

    feed = Handler.to_feed(state)

    %{feed: feed, first: hd(feed.items)}
  end

  describe "chapters" do
    # The fixture binds `xmlns:psc` on `psc:chapters` itself, not on the root.
    test "reads them in document order with milliseconds", %{first: first} do
      assert first.chapters == [
               %Chapter{start_ms: 0, title: "Intro", href: nil, image_url: nil},
               %Chapter{
                 start_ms: 754_567,
                 title: "Hauptteil",
                 href: "https://example.com/kapitel",
                 image_url: nil
               }
             ]
    end

    test "leaves items without chapters at an empty list", %{feed: feed} do
      assert Enum.at(feed.items, 1).chapters == []
    end
  end

  describe "transcripts" do
    test "reads the attributes", %{first: first} do
      assert first.transcripts == [
               %Transcript{
                 url: "https://example.com/e1.vtt",
                 type: "text/vtt",
                 language: "de",
                 rel: nil
               }
             ]
    end
  end

  describe "persons" do
    test "merges podcast:person and atom:contributor per item", %{first: first} do
      assert first.persons == [
               %Person{
                 name: "Alice Example",
                 role: "host",
                 image_url: "https://example.com/alice.jpg",
                 uri: "https://alice.example"
               },
               %Person{name: "Bob Beispiel", role: "guest", image_url: nil, uri: nil}
             ]
    end

    test "merges them at channel level too", %{feed: feed} do
      assert feed.channel.persons == [
               %Person{
                 name: "Alice Example",
                 role: "host",
                 image_url: "https://example.com/alice.jpg",
                 uri: "https://alice.example"
               }
             ]
    end

    test "leaves items without persons at an empty list", %{feed: feed} do
      assert Enum.at(feed.items, 1).persons == []
    end
  end
end
