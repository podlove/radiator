defmodule Radiator.Podcasts.ApplyFeedTest do
  use Radiator.DataCase, async: true

  import ExUnit.CaptureLog

  # `capture_log/1` collects but does not silence; the tag keeps the run quiet.
  @moduletag :capture_log

  require Ash.Query

  alias Radiator.FeedFixtures
  alias Radiator.Feeds.Parser
  alias Radiator.Podcasts
  alias Radiator.Podcasts.Episode
  alias Radiator.Podcasts.EpisodeContributor
  alias Radiator.Podcasts.Person

  setup do
    user = generate(user())
    podcast = Podcasts.create_podcast!(%{title: "Placeholder"}, actor: user)
    {:ok, feed} = Parser.parse(FeedFixtures.read!("minimal.xml"))

    %{user: user, podcast: podcast, feed: feed}
  end

  # Stands in for the Oban worker, which runs `:apply_feed` without an actor.
  defp apply_feed(podcast, feed),
    do: Ash.update!(podcast, %{feed: feed}, action: :apply_feed, authorize?: false)

  defp episodes(podcast) do
    Episode
    |> Ash.Query.filter(podcast_id == ^podcast.id)
    |> Ash.Query.sort(guid: :asc)
    |> Ash.read!()
  end

  describe "channel data" do
    test "writes the podcast attributes", %{podcast: podcast, feed: feed} do
      updated = apply_feed(podcast, feed)

      assert updated.title == "Test Show"
      assert updated.language == "de-DE"
      assert updated.podcast_type == :episodic
      assert [%{text: "Technology"}, %{text: "Society & Culture"}] = updated.categories
    end

    test "marks the sync as succeeded and stamps both timestamps", %{
      podcast: podcast,
      feed: feed
    } do
      updated = apply_feed(podcast, feed)

      assert updated.sync_status == :succeeded
      assert updated.last_sync_error == nil
      assert updated.last_checked_at != nil
      assert updated.last_imported_at == updated.last_checked_at
    end
  end

  describe "episodes" do
    test "creates one episode per item", %{podcast: podcast, feed: feed} do
      apply_feed(podcast, feed)

      assert Enum.map(episodes(podcast), & &1.guid) == ~w(item-1 item-2 item-3 item-4 item-5)
    end

    test "writes chapters and transcripts as embedded values", %{podcast: podcast, feed: feed} do
      apply_feed(podcast, feed)

      first = Enum.find(episodes(podcast), &(&1.guid == "item-1"))

      assert [%{start_ms: 0, title: "Intro"}, %{start_ms: 754_567}] = first.chapters
      assert [%{url: "https://example.com/e1.vtt"}] = first.transcripts
    end

    test "upserts on a second run instead of duplicating", %{podcast: podcast, feed: feed} do
      first_run = apply_feed(podcast, feed)
      ids = episodes(podcast) |> Enum.map(& &1.id) |> Enum.sort()

      apply_feed(first_run, feed)

      assert length(episodes(podcast)) == 5
      assert episodes(podcast) |> Enum.map(& &1.id) |> Enum.sort() == ids
    end

    test "keeps episodes that vanished from the feed", %{podcast: podcast, feed: feed} do
      apply_feed(podcast, feed)

      {:ok, shrunk} =
        Parser.parse(
          ~s(<rss version="2.0"><channel><title>Test Show</title>) <>
            ~s(<item><guid>item-1</guid><title>Only one left</title></item>) <>
            ~s(</channel></rss>)
        )

      reloaded = Ash.get!(Radiator.Podcasts.Podcast, podcast.id, authorize?: false)
      apply_feed(reloaded, shrunk)

      assert length(episodes(podcast)) == 5
    end
  end

  describe "last_seen_in_feed_at" do
    test "matches last_imported_at exactly, so nothing looks missing", %{
      podcast: podcast,
      feed: feed
    } do
      updated = apply_feed(podcast, feed)

      assert Enum.all?(episodes(podcast), &(&1.last_seen_in_feed_at == updated.last_imported_at))
    end

    test "a second unchanged sync marks no episode as missing", %{podcast: podcast, feed: feed} do
      first_run = apply_feed(podcast, feed)
      second_run = apply_feed(first_run, feed)

      loaded =
        Episode
        |> Ash.Query.filter(podcast_id == ^podcast.id)
        |> Ash.Query.load(:missing_from_feed?)
        |> Ash.read!()

      assert second_run.last_imported_at != first_run.last_imported_at
      refute Enum.any?(loaded, & &1.missing_from_feed?)
    end
  end

  describe "persons" do
    test "creates one person per distinct name under the owner", %{
      user: user,
      podcast: podcast,
      feed: feed
    } do
      apply_feed(podcast, feed)

      names =
        Ash.read!(Person)
        |> Enum.filter(&(&1.user_id == user.id))
        |> Enum.map(& &1.normalized_name)
        |> Enum.sort()

      assert names == ["alice example", "bob beispiel"]
    end

    test "links contributors with their role", %{podcast: podcast, feed: feed} do
      apply_feed(podcast, feed)

      roles =
        Ash.read!(EpisodeContributor)
        |> Enum.map(& &1.role)
        |> Enum.sort()

      assert roles == ["guest", "host"]
    end

    test "does not duplicate links on a second run", %{podcast: podcast, feed: feed} do
      first_run = apply_feed(podcast, feed)
      apply_feed(first_run, feed)

      assert length(Ash.read!(EpisodeContributor)) == 2
    end

    test "keeps what another podcast's feed contributed to the same person", %{
      user: user,
      podcast: podcast,
      feed: feed
    } do
      apply_feed(podcast, feed)

      other = Podcasts.create_podcast!(%{title: "Other"}, actor: user)

      {:ok, sparse} =
        Parser.parse(
          ~s(<rss xmlns:podcast="https://podcastindex.org/namespace/1.0" version="2.0">) <>
            ~s(<channel><title>Other</title><item><guid>o1</guid><title>T</title>) <>
            ~s(<podcast:person role="host">Alice Example</podcast:person>) <>
            ~s(</item></channel></rss>)
        )

      apply_feed(other, sparse)

      alice = Enum.find(Ash.read!(Person), &(&1.normalized_name == "alice example"))

      assert alice.uri == "https://alice.example"
      assert alice.image_url == "https://example.com/alice.jpg"
    end
  end

  describe "items the feed cannot identify" do
    test "a feed with duplicate guids imports instead of failing", %{podcast: podcast} do
      {:ok, feed} =
        Parser.parse(
          ~s(<rss version="2.0"><channel><title>Test Show</title>) <>
            ~s(<item><guid>dup</guid><title>One</title></item>) <>
            ~s(<item><guid>dup</guid><title>Two</title></item>) <>
            ~s(</channel></rss>)
        )

      apply_feed(podcast, feed)

      assert [%{guid: "dup", title: "One"}] = episodes(podcast)
    end

    test "warns about the items it dropped", %{podcast: podcast} do
      {:ok, feed} =
        Parser.parse(
          ~s(<rss version="2.0"><channel><title>Test Show</title>) <>
            ~s(<item><title>Nameless</title></item>) <>
            ~s(<item><guid>keeper</guid><title>Keeper</title></item></channel></rss>)
        )

      log = capture_log(fn -> apply_feed(podcast, feed) end)

      assert log =~ "1 item"
      assert log =~ podcast.id
    end

    test "stays quiet when nothing was dropped", %{podcast: podcast, feed: feed} do
      refute capture_log(fn -> apply_feed(podcast, feed) end) =~ "without a usable identity"
    end
  end

  describe "not modified" do
    test "with a nil feed only the check timestamp moves", %{podcast: podcast, feed: feed} do
      imported = apply_feed(podcast, feed)
      checked = Ash.update!(imported, %{feed: nil}, action: :apply_feed, authorize?: false)

      assert checked.sync_status == :succeeded
      assert checked.last_imported_at == imported.last_imported_at
      assert DateTime.compare(checked.last_checked_at, imported.last_checked_at) == :gt
      assert length(episodes(podcast)) == 5
    end
  end
end
