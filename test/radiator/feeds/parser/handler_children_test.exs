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

    test "recognises psc even when the prefix is bound on psc:chapters itself", %{
      first: first
    } do
      assert length(first.chapters) == 2
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

    test "does not mix channel persons with item persons", %{feed: feed} do
      assert length(feed.channel.persons) == 1
      assert length(hd(feed.items).persons) == 2
    end

    test "leaves items without persons at an empty list", %{feed: feed} do
      assert Enum.at(feed.items, 1).persons == []
    end
  end
end
