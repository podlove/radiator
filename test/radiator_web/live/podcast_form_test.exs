defmodule RadiatorWeb.PodcastFormTest do
  use RadiatorWeb.ConnCase, async: true

  import Phoenix.LiveViewTest

  alias Radiator.Podcasts

  setup :register_and_log_in_user

  test "the import form offers the sync strategy", %{conn: conn} do
    {:ok, _live, html} = live(conn, ~p"/admin/podcasts/import")

    assert html =~ "podcast[sync_strategy]"
    assert html =~ "Regelmäßiger Sync"
  end

  test "the new form does not offer it", %{conn: conn} do
    {:ok, _live, html} = live(conn, ~p"/admin/podcasts/new")

    refute html =~ "podcast[sync_strategy]"
  end

  test "importing stores url and strategy and reports that the feed is queued", %{
    conn: conn,
    user: user
  } do
    {:ok, live, _html} = live(conn, ~p"/admin/podcasts/import")

    live
    |> form("#podcast-form", %{
      "podcast" => %{
        "feed_url" => "https://example.com/feed",
        "sync_strategy" => "scheduled"
      }
    })
    |> render_submit()

    assert [podcast] = Ash.read!(Radiator.Podcasts.Podcast, actor: user)
    assert podcast.feed_url == "https://example.com/feed"
    assert podcast.sync_strategy == :scheduled
    assert podcast.sync_status == :pending
  end

  test "the edit form offers the descriptive fields", %{conn: conn, user: user} do
    podcast = Podcasts.create_podcast!(%{title: "Test Show"}, actor: user)

    {:ok, _live, html} = live(conn, ~p"/admin/podcasts/#{podcast.id}/edit")

    for field <- ~w(subtitle summary description author link language image_url copyright
                    license license_url funding_url funding_text owner_name owner_email
                    podcast_type explicit feed_guid) do
      assert html =~ "podcast[#{field}]", "missing field #{field}"
    end
  end

  test "editing stores the descriptive fields", %{conn: conn, user: user} do
    podcast = Podcasts.create_podcast!(%{title: "Test Show"}, actor: user)

    {:ok, live, _html} = live(conn, ~p"/admin/podcasts/#{podcast.id}/edit")

    live
    |> form("#podcast-form", %{
      "podcast" => %{
        "subtitle" => "Kurz",
        "description" => "<p>Lang</p>",
        "podcast_type" => "serial",
        "explicit" => "true",
        "language" => "de-DE"
      }
    })
    |> render_submit()

    saved = Ash.get!(Radiator.Podcasts.Podcast, podcast.id, authorize?: false)
    assert saved.subtitle == "Kurz"
    assert saved.description == "<p>Lang</p>"
    assert saved.podcast_type == :serial
    assert saved.explicit == true
    assert saved.language == "de-DE"
  end

  test "categories can be added and are stored with their subcategory", %{
    conn: conn,
    user: user
  } do
    podcast = Podcasts.create_podcast!(%{title: "Test Show"}, actor: user)

    {:ok, live, _html} = live(conn, ~p"/admin/podcasts/#{podcast.id}/edit")

    live |> element("#add-category") |> render_click()

    live
    |> form("#podcast-form", %{
      "podcast" => %{
        "categories" => %{"0" => %{"text" => "Technology", "subcategory" => "Podcasting"}}
      }
    })
    |> render_submit()

    assert [%{text: "Technology", subcategory: "Podcasting"}] =
             Ash.get!(Radiator.Podcasts.Podcast, podcast.id, authorize?: false).categories
  end

  test "an existing category can be removed", %{conn: conn, user: user} do
    podcast =
      Podcasts.create_podcast!(
        %{title: "Test Show", categories: [%{text: "Technology"}, %{text: "Comedy"}]},
        actor: user
      )

    {:ok, live, _html} = live(conn, ~p"/admin/podcasts/#{podcast.id}/edit")

    live |> element("button[phx-value-path='podcast[categories][0]']") |> render_click()
    live |> form("#podcast-form") |> render_submit()

    assert [%{text: "Comedy"}] =
             Ash.get!(Radiator.Podcasts.Podcast, podcast.id, authorize?: false).categories
  end

  test "a podcast with a feed warns that a sync overwrites the fields", %{conn: conn, user: user} do
    podcast = Podcasts.import_podcast!(%{feed_url: "https://example.com/feed"}, actor: user)

    {:ok, _live, html} = live(conn, ~p"/admin/podcasts/#{podcast.id}/edit")

    assert html =~ "überschreibt"
  end

  test "a podcast without a feed does not warn", %{conn: conn, user: user} do
    podcast = Podcasts.create_podcast!(%{title: "By hand"}, actor: user)

    {:ok, _live, html} = live(conn, ~p"/admin/podcasts/#{podcast.id}/edit")

    refute html =~ "überschreibt"
  end

  test "editing can switch the strategy", %{conn: conn, user: user} do
    podcast = Podcasts.import_podcast!(%{feed_url: "https://example.com/feed"}, actor: user)

    {:ok, live, _html} = live(conn, ~p"/admin/podcasts/#{podcast.id}/edit")

    live
    |> form("#podcast-form", %{"podcast" => %{"sync_strategy" => "scheduled"}})
    |> render_submit()

    assert Ash.get!(Radiator.Podcasts.Podcast, podcast.id, authorize?: false).sync_strategy ==
             :scheduled
  end
end
