defmodule Radiator.Feeds.Parser.HandlerTest do
  use ExUnit.Case, async: true

  alias Radiator.FeedFixtures
  alias Radiator.Feeds.Feed
  alias Radiator.Feeds.Feed.Category
  alias Radiator.Feeds.Parser.Handler

  defp parse!(xml) do
    {:ok, state} = Saxy.parse_string(xml, Handler, Handler.initial_state())
    Handler.to_feed(state)
  end

  defp minimal, do: parse!(FeedFixtures.read!("minimal.xml"))

  describe "channel level" do
    test "reads the unprefixed fields" do
      channel = minimal().channel

      assert channel.title == "Test Show"
      assert channel.link == "https://example.com"
      assert channel.language == "de-DE"
      assert channel.copyright == "Example Media"
    end

    test "reads CDATA content including the markup inside it" do
      assert minimal().channel.description == "Eine <em>Testsendung</em>"
    end

    test "reads the itunes fields" do
      channel = minimal().channel

      assert channel.author == "Example Media"
      assert channel.subtitle == "Kurzbeschreibung"
      assert channel.podcast_type == "episodic"
      assert channel.explicit == false
      assert channel.image_url == "https://example.com/cover.jpg"
      assert channel.owner_name == "Alice Example"
      assert channel.owner_email == "alice@example.com"
    end

    test "collects categories in document order, with their subcategory" do
      assert minimal().channel.categories == [
               %Category{text: "Technology"},
               %Category{text: "Society & Culture", subcategory: "Philosophy"}
             ]
    end

    test "reads itunes:summary" do
      assert minimal().channel.summary == "Die Zusammenfassung der Sendung"
    end

    test "reads funding and license from the podcast namespace" do
      channel = minimal().channel

      assert channel.funding_url == "https://example.com/support"
      assert channel.funding_text == "Unterstütze die Sendung"
      assert channel.license == "cc-by-4.0"
      assert channel.license_url == "https://creativecommons.org/licenses/by/4.0/"
    end

    test "reads podcast:guid" do
      assert minimal().channel.guid == "60489a00-ccbb-42ec-87f3-a090c961e8dc"
    end
  end

  describe "namespace resolution" do
    test "recognises a prefix that is bound partway through the document" do
      xml = """
      <rss version="2.0">
        <channel>
          <title>X</title>
          <late:marker xmlns:late="http://www.itunes.com/dtds/podcast-1.0.dtd">ignoriert</late:marker>
          <late:author xmlns:late="http://www.itunes.com/dtds/podcast-1.0.dtd">Spät gebunden</late:author>
        </channel>
      </rss>
      """

      assert parse!(xml).channel.author == "Spät gebunden"
    end

    test "resolves on the URI, not on the prefix" do
      xml = """
      <rss xmlns:it="http://www.itunes.com/dtds/podcast-1.0.dtd" version="2.0">
        <channel><title>X</title><it:author>Fremdes Präfix</it:author></channel>
      </rss>
      """

      assert parse!(xml).channel.author == "Fremdes Präfix"
    end

    test "rolls an overridden binding back once the subtree ends" do
      xml = """
      <rss xmlns:p="http://www.itunes.com/dtds/podcast-1.0.dtd" version="2.0">
        <channel>
          <title>X</title>
          <wrap xmlns:p="https://unknown.example/ns"><p:author>Falsch</p:author></wrap>
          <p:author>Richtig</p:author>
        </channel>
      </rss>
      """

      assert parse!(xml).channel.author == "Richtig"
    end

    test "skips unknown subtrees without losing the feed" do
      feed = minimal()

      assert %Feed{} = feed
      assert feed.channel.title == "Test Show"
    end
  end

  describe "text buffering" do
    test "joins text delivered in chunks" do
      xml = "<rss version=\"2.0\"><channel><title>Teil A &amp; Teil B</title></channel></rss>"

      assert parse!(xml).channel.title == "Teil A & Teil B"
    end

    test "returns nil when an element is absent entirely" do
      xml = "<rss version=\"2.0\"><channel><title>X</title></channel></rss>"

      assert parse!(xml).channel.copyright == nil
    end

    test "keeps the character data around inline markup" do
      xml =
        ~s(<rss version="2.0"><channel><title>X</title>) <>
          ~s(<description>Some <b>bold</b> text here</description></channel></rss>)

      assert parse!(xml).channel.description == "Some bold text here"
    end

    test "keeps the character data around inline markup in an item" do
      xml =
        ~s(<rss version="2.0"><channel><title>X</title>) <>
          ~s(<item><guid>i1</guid><title>Ti<i>t</i>le</title></item></channel></rss>)

      assert [%{title: "Title"}] = parse!(xml).items
    end

    test "does not let a child's text leak into a container element" do
      xml =
        ~s(<rss version="2.0"><channel><title>X</title>) <>
          ~s(<item><guid>i1</guid><title>T</title></item></channel></rss>)

      feed = parse!(xml)

      assert feed.channel.title == "X"
      assert [%{title: "T", guid: "i1"}] = feed.items
    end
  end
end
