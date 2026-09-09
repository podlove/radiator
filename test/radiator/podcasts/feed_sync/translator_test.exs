defmodule Radiator.Podcasts.FeedSync.TranslatorTest do
  use ExUnit.Case, async: true

  alias Radiator.FeedFixtures
  alias Radiator.Feeds.Parser
  alias Radiator.Podcasts.FeedSync.Translation
  alias Radiator.Podcasts.FeedSync.Translator

  setup do
    {:ok, feed} = Parser.parse(FeedFixtures.read!("minimal.xml"))

    %{translation: Translator.translate(feed)}
  end

  describe "podcast attributes" do
    test "maps the channel onto podcast attributes", %{translation: translation} do
      assert %Translation{podcast: podcast} = translation

      assert podcast.title == "Test Show"
      assert podcast.subtitle == "Kurzbeschreibung"
      assert podcast.description == "Eine <em>Testsendung</em>"
      assert podcast.link == "https://example.com"
      assert podcast.language == "de-DE"
      assert podcast.author == "Example Media"
      assert podcast.owner_name == "Alice Example"
      assert podcast.owner_email == "alice@example.com"
      assert podcast.image_url == "https://example.com/cover.jpg"
      assert podcast.copyright == "Example Media"
      assert podcast.explicit == false
      assert podcast.feed_guid == "60489a00-ccbb-42ec-87f3-a090c961e8dc"
    end

    test "turns itunes:type into the PodcastType enum value", %{translation: translation} do
      assert translation.podcast.podcast_type == :episodic
    end

    test "maps summary, funding and license", %{translation: translation} do
      podcast = translation.podcast

      assert podcast.summary == "Die Zusammenfassung der Sendung"
      assert podcast.funding_url == "https://example.com/support"
      assert podcast.funding_text == "Unterstütze die Sendung"
      assert podcast.license == "cc-by-4.0"
      assert podcast.license_url == "https://creativecommons.org/licenses/by/4.0/"
    end

    test "maps categories", %{translation: translation} do
      assert translation.podcast.categories == [
               %{text: "Technology", subcategory: nil},
               %{text: "Society & Culture", subcategory: "Philosophy"}
             ]
    end

    test "leaves an unknown itunes:type at nil" do
      xml =
        ~s(<rss xmlns:itunes="http://www.itunes.com/dtds/podcast-1.0.dtd" version="2.0">) <>
          ~s(<channel><title>X</title><itunes:type>weekly</itunes:type></channel></rss>)

      {:ok, feed} = Parser.parse(xml)

      assert Translator.translate(feed).podcast.podcast_type == nil
    end
  end

  describe "episode attributes" do
    test "maps every item that carries an identity", %{translation: translation} do
      assert Enum.map(translation.episodes, & &1.guid) == ~w(item-1 item-2 item-3 item-4 item-5)
    end

    test "maps the full first episode", %{translation: translation} do
      [first | _] = translation.episodes

      assert first.title == "Vollständige Episode"
      assert first.number == 1
      assert first.season == 1
      assert first.episode_type == :full
      assert first.subtitle == "Untertitel eins"
      assert first.summary == "Zusammenfassung aus itunes:summary"
      assert first.content_html =~ "<p>Volltext"
      assert first.link == "https://example.com/e1"
      assert first.published_at == ~U[2026-08-28 17:14:26Z]
      assert first.duration_seconds == 3723
      assert first.image_url == "https://example.com/e1.jpg"
      assert first.enclosure_url == "https://example.com/e1.mp3"
      assert first.enclosure_length == 149_856_131
      assert first.enclosure_type == "audio/mpeg"
    end

    test "prefers itunes:summary for the summary and falls back to description", %{
      translation: translation
    } do
      [first, second | _] = translation.episodes

      assert first.summary == "Zusammenfassung aus itunes:summary"
      assert second.summary == "Nur aus description"
    end

    test "maps author and the chapters reference", %{translation: translation} do
      [first | _] = translation.episodes

      assert first.author == "Alice Example"
      assert first.chapters_url == "https://example.com/e1.json"
      assert first.chapters_type == "application/json+chapters"
    end

    test "flattens chapters and transcripts into embeddable maps", %{translation: translation} do
      [first | _] = translation.episodes

      assert first.chapters == [
               %{start_ms: 0, title: "Intro", href: nil, image_url: nil},
               %{
                 start_ms: 754_567,
                 title: "Hauptteil",
                 href: "https://example.com/kapitel",
                 image_url: nil
               }
             ]

      assert first.transcripts == [
               %{url: "https://example.com/e1.vtt", type: "text/vtt", language: "de", rel: nil}
             ]
    end
  end

  describe "title fallback chain" do
    test "falls back to itunes:title when title is missing", %{translation: translation} do
      third = Enum.find(translation.episodes, &(&1.guid == "item-3"))

      assert third.title == "Titel nur aus itunes:title"
    end

    test "falls back to the episode number when both titles are missing", %{
      translation: translation
    } do
      fourth = Enum.find(translation.episodes, &(&1.guid == "item-4"))

      assert fourth.title == "Episode 4"
    end

    test "falls back to the guid when there is no number either" do
      xml =
        ~s(<rss version="2.0"><channel><title>X</title>) <>
          ~s(<item><guid>only-a-guid</guid></item></channel></rss>)

      {:ok, feed} = Parser.parse(xml)
      [episode] = Translator.translate(feed).episodes

      assert episode.title == "only-a-guid"
    end
  end

  describe "identity" do
    test "falls back to link, then to the enclosure url" do
      xml =
        ~s(<rss version="2.0"><channel><title>X</title>) <>
          ~s(<item><title>A</title><link>https://example.com/a</link></item>) <>
          ~s(<item><title>B</title><enclosure url="https://example.com/b.mp3"/></item>) <>
          ~s(</channel></rss>)

      {:ok, feed} = Parser.parse(xml)

      assert Enum.map(Translator.translate(feed).episodes, & &1.guid) ==
               ["https://example.com/a", "https://example.com/b.mp3"]
    end

    test "keeps the first of two items sharing an identity and counts the rest" do
      xml =
        ~s(<rss version="2.0"><channel><title>X</title>) <>
          ~s(<item><guid>dup</guid><title>One</title></item>) <>
          ~s(<item><guid>dup</guid><title>Two</title></item>) <>
          ~s(<item><guid>other</guid><title>Three</title></item></channel></rss>)

      {:ok, feed} = Parser.parse(xml)
      translation = Translator.translate(feed)

      assert Enum.map(translation.episodes, &{&1.guid, &1.title}) ==
               [{"dup", "One"}, {"other", "Three"}]

      assert translation.skipped == 1
    end

    test "records one contribution per person and episode even across duplicates" do
      xml =
        ~s(<rss xmlns:podcast="https://podcastindex.org/namespace/1.0" version="2.0">) <>
          ~s(<channel><title>X</title>) <>
          ~s(<item><guid>dup</guid><title>One</title>) <>
          ~s(<podcast:person role="host">Alice</podcast:person></item>) <>
          ~s(<item><guid>dup</guid><title>Two</title>) <>
          ~s(<podcast:person role="host">Alice</podcast:person></item>) <>
          ~s(</channel></rss>)

      {:ok, feed} = Parser.parse(xml)

      assert Translator.translate(feed).contributions ==
               [%{guid: "dup", normalized_name: "alice", role: "host"}]
    end

    test "drops items without any identity and counts them" do
      xml =
        ~s(<rss version="2.0"><channel><title>X</title>) <>
          ~s(<item><title>Nameless</title></item>) <>
          ~s(<item><guid>keeper</guid></item></channel></rss>)

      {:ok, feed} = Parser.parse(xml)
      translation = Translator.translate(feed)

      assert Enum.map(translation.episodes, & &1.guid) == ["keeper"]
      assert translation.skipped == 1
    end
  end

  describe "persons and contributions" do
    test "deduplicates persons across channel and items", %{translation: translation} do
      names = translation.persons |> Enum.map(& &1.normalized_name) |> Enum.sort()

      assert names == ["alice example", "bob beispiel"]
    end

    test "carries image and uri onto the deduplicated person", %{translation: translation} do
      alice = Enum.find(translation.persons, &(&1.normalized_name == "alice example"))

      assert alice.name == "Alice Example"
      assert alice.image_url == "https://example.com/alice.jpg"
      assert alice.uri == "https://alice.example"
    end

    test "records one contribution per person and episode, with the role", %{
      translation: translation
    } do
      assert translation.contributions == [
               %{guid: "item-1", normalized_name: "alice example", role: "host"},
               %{guid: "item-1", normalized_name: "bob beispiel", role: "guest"}
             ]
    end

    test "records no contribution for channel-level persons", %{translation: translation} do
      assert Enum.all?(translation.contributions, &(&1.guid == "item-1"))
    end
  end
end
