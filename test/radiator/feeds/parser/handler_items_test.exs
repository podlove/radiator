defmodule Radiator.Feeds.Parser.HandlerItemsTest do
  use ExUnit.Case, async: true

  alias Radiator.FeedFixtures
  alias Radiator.Feeds.Feed.Enclosure
  alias Radiator.Feeds.Parser.Handler

  setup do
    {:ok, state} =
      Saxy.parse_string(FeedFixtures.read!("minimal.xml"), Handler, Handler.initial_state())

    feed = Handler.to_feed(state)

    %{feed: feed, items: feed.items}
  end

  test "reads all five items in document order", %{items: items} do
    assert length(items) == 5
    assert Enum.map(items, & &1.guid) == ~w(item-1 item-2 item-3 item-4 item-5)
  end

  test "reads the unprefixed fields of the first item", %{items: [first | _]} do
    assert first.title == "Vollständige Episode"
    assert first.link == "https://example.com/e1"
    assert first.description == "Zusammenfassung eins"
  end

  test "reads content:encoded including the markup inside it", %{items: [first | _]} do
    assert first.content_html == ~s(<p>Volltext mit <a href="https://example.com">Link</a></p>)
  end

  test "reads pubDate as a DateTime in UTC", %{items: [first, second | _]} do
    assert first.published_at == ~U[2026-08-28 17:14:26Z]
    assert second.published_at == ~U[2026-08-27 08:00:00Z]
  end

  test "reads the itunes fields of the first item", %{items: [first | _]} do
    assert first.number == 1
    assert first.season == 1
    assert first.episode_type == "full"
    assert first.duration_seconds == 3723
    assert first.subtitle == "Untertitel eins"
    assert first.image_url == "https://example.com/e1.jpg"
  end

  test "reads itunes:summary and itunes:author", %{items: [first, second | _]} do
    assert first.itunes_summary == "Zusammenfassung aus itunes:summary"
    assert first.author == "Alice Example"
    assert second.itunes_summary == nil
  end

  test "reads the podcast:chapters reference", %{items: [first, second | _]} do
    assert first.chapters_url == "https://example.com/e1.json"
    assert first.chapters_type == "application/json+chapters"
    assert second.chapters_url == nil
  end

  test "reads the enclosure as a struct", %{items: [first | _]} do
    assert first.enclosure == %Enclosure{
             url: "https://example.com/e1.mp3",
             length: 149_856_131,
             type: "audio/mpeg"
           }
  end

  test "leaves absent fields at nil", %{items: [_first, second | _]} do
    assert second.number == nil
    assert second.content_html == nil
    assert second.enclosure.length == 1000
  end

  test "keeps title and itunes:title apart", %{items: items} do
    third = Enum.at(items, 2)

    assert third.title == nil
    assert third.itunes_title == "Titel nur aus itunes:title"
  end

  test "reads duration in every notation", %{items: items} do
    assert Enum.at(items, 1).duration_seconds == 3600
    assert Enum.at(items, 2).duration_seconds == 3600
  end

  test "skips an unknown subtree inside an item", %{items: items} do
    fifth = Enum.at(items, 4)

    assert fifth.title == "Mit unbekanntem Teilbaum"
    assert fifth.number == 5
  end

  test "does not confuse channel fields with item fields", %{feed: feed} do
    assert feed.channel.title == "Test Show"
    assert feed.channel.subtitle == "Kurzbeschreibung"
  end
end
