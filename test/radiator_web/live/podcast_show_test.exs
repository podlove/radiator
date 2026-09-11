defmodule RadiatorWeb.PodcastShowTest do
  use RadiatorWeb.ConnCase, async: false

  import Phoenix.LiveViewTest

  alias Radiator.FeedFixtures
  alias Radiator.Feeds.Parser
  alias Radiator.Podcasts

  setup :register_and_log_in_user

  setup %{user: user} do
    podcast = Podcasts.import_podcast!(%{feed_url: "https://example.com/feed"}, actor: user)
    {:ok, feed} = Parser.parse(FeedFixtures.read!("minimal.xml"))

    %{podcast: podcast, feed: feed}
  end

  test "shows the sync status", %{conn: conn, podcast: podcast} do
    {:ok, _live, html} = live(conn, ~p"/admin/podcasts/#{podcast.id}")

    assert html =~ "Sync angefordert"
  end

  test "shows the error after a failure", %{conn: conn, podcast: podcast} do
    Ash.update!(podcast, %{error: {:http_status, 404}},
      action: :mark_sync_failed,
      authorize?: false
    )

    {:ok, _live, html} = live(conn, ~p"/admin/podcasts/#{podcast.id}")

    assert html =~ "Fehlgeschlagen"
    assert html =~ "404"
  end

  test "the sync button warns that local edits are overwritten", %{conn: conn, podcast: podcast} do
    {:ok, _live, html} = live(conn, ~p"/admin/podcasts/#{podcast.id}")

    assert html =~ "data-confirm"
    assert html =~ "überschreib"
  end

  test "pressing sync puts the podcast back to pending", %{conn: conn, podcast: podcast} do
    Ash.update!(podcast, %{error: :timeout}, action: :mark_sync_failed, authorize?: false)

    {:ok, live, _html} = live(conn, ~p"/admin/podcasts/#{podcast.id}")

    live |> element("#request-sync") |> render_click()

    assert Ash.get!(Radiator.Podcasts.Podcast, podcast.id).sync_status == :pending
  end

  test "a background sync updates the open page", %{conn: conn, podcast: podcast, feed: feed} do
    {:ok, live, html} = live(conn, ~p"/admin/podcasts/#{podcast.id}")

    refute html =~ "Test Show"

    Ash.update!(podcast, %{feed: feed}, action: :apply_feed, authorize?: false)

    assert render(live) =~ "Test Show"
  end

  test "shows the imported identity and episode details", %{
    conn: conn,
    podcast: podcast,
    feed: feed
  } do
    Ash.update!(podcast, %{feed: feed}, action: :apply_feed, authorize?: false)

    {:ok, _live, html} = live(conn, ~p"/admin/podcasts/#{podcast.id}")

    assert html =~ ~s(src="https://example.com/cover.jpg")
    assert html =~ "Example Media"
    assert html =~ "5 Episoden"
    assert html =~ "1:02:03"
    assert html =~ "gerade eben"
  end

  test "while a sync is pending the button is disabled", %{conn: conn, podcast: podcast} do
    {:ok, live, _html} = live(conn, ~p"/admin/podcasts/#{podcast.id}")

    assert live |> element("#request-sync[disabled]") |> has_element?()
  end

  test "each episode links to its edit form", %{conn: conn, podcast: podcast, feed: feed} do
    Ash.update!(podcast, %{feed: feed}, action: :apply_feed, authorize?: false)
    [episode | _] = Ash.load!(podcast, :episodes).episodes

    {:ok, _live, html} = live(conn, ~p"/admin/podcasts/#{podcast.id}")

    assert html =~ ~p"/admin/podcasts/#{podcast.id}/episodes/#{episode.id}/edit"
  end

  test "a podcast without episodes says so", %{conn: conn, podcast: podcast} do
    {:ok, _live, html} = live(conn, ~p"/admin/podcasts/#{podcast.id}")

    assert html =~ "Noch keine Episoden"
  end

  test "lists the episodes and marks the ones missing from the feed", %{
    conn: conn,
    podcast: podcast,
    feed: feed
  } do
    imported = Ash.update!(podcast, %{feed: feed}, action: :apply_feed, authorize?: false)

    {:ok, shrunk} =
      Parser.parse(
        ~s(<rss version="2.0"><channel><title>Test Show</title>) <>
          ~s(<item><guid>item-1</guid><title>Only one left</title></item>) <>
          ~s(</channel></rss>)
      )

    Ash.update!(imported, %{feed: shrunk}, action: :apply_feed, authorize?: false)

    {:ok, _live, html} = live(conn, ~p"/admin/podcasts/#{podcast.id}")

    assert html =~ "Only one left"
    assert html =~ "Nicht mehr im Feed"
  end
end
