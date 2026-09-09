defmodule RadiatorWeb.EpisodeFormTest do
  use RadiatorWeb.ConnCase, async: true

  import Phoenix.LiveViewTest

  alias Radiator.Podcasts
  alias Radiator.Podcasts.Episode

  setup :register_and_log_in_user

  setup %{user: user} do
    %{podcast: Podcasts.create_podcast!(%{title: "Test Show"}, actor: user)}
  end

  defp episodes(podcast),
    do: Podcasts.read_episodes!() |> Enum.filter(&(&1.podcast_id == podcast.id))

  test "the podcast page links to a new episode", %{conn: conn, podcast: podcast} do
    {:ok, _live, html} = live(conn, ~p"/admin/podcasts/#{podcast.id}")

    assert html =~ ~p"/admin/podcasts/#{podcast.id}/episodes/new"
  end

  test "creates an episode under the podcast", %{conn: conn, podcast: podcast} do
    {:ok, live, _html} = live(conn, ~p"/admin/podcasts/#{podcast.id}/episodes/new")

    live
    |> form("#episode-form", %{
      "episode" => %{
        "title" => "Erste Folge",
        "number" => "1",
        "published_at" => "2026-09-09T12:00",
        "duration_seconds" => "3600",
        "episode_type" => "full"
      }
    })
    |> render_submit()

    assert [
             %Episode{
               title: "Erste Folge",
               number: 1,
               duration_seconds: 3600,
               episode_type: :full
             } = episode
           ] =
             episodes(podcast)

    assert episode.podcast_id == podcast.id
    assert episode.published_at == ~U[2026-09-09 12:00:00.000000Z]
  end

  test "the edit form offers every field", %{conn: conn, podcast: podcast} do
    episode = Podcasts.create_episode!(%{podcast_id: podcast.id, title: "Folge"})

    {:ok, _live, html} = live(conn, ~p"/admin/podcasts/#{podcast.id}/episodes/#{episode.id}/edit")

    for field <- ~w(title subtitle summary content_html author link image_url guid number season
                    episode_type published_at duration_seconds enclosure_url enclosure_length
                    enclosure_type chapters_url chapters_type) do
      assert html =~ "episode[#{field}]", "missing field #{field}"
    end
  end

  test "editing stores the fields", %{conn: conn, podcast: podcast} do
    episode = Podcasts.create_episode!(%{podcast_id: podcast.id, title: "Folge"})

    {:ok, live, _html} = live(conn, ~p"/admin/podcasts/#{podcast.id}/episodes/#{episode.id}/edit")

    live
    |> form("#episode-form", %{
      "episode" => %{
        "title" => "Umbenannt",
        "subtitle" => "Kurz",
        "enclosure_url" => "https://example.com/e.mp3",
        "enclosure_length" => "1234",
        "enclosure_type" => "audio/mpeg"
      }
    })
    |> render_submit()

    saved = Ash.get!(Episode, episode.id)
    assert saved.title == "Umbenannt"
    assert saved.subtitle == "Kurz"
    assert saved.enclosure_url == "https://example.com/e.mp3"
    assert saved.enclosure_length == 1234
  end

  test "chapters can be added", %{conn: conn, podcast: podcast} do
    episode = Podcasts.create_episode!(%{podcast_id: podcast.id, title: "Folge"})

    {:ok, live, _html} = live(conn, ~p"/admin/podcasts/#{podcast.id}/episodes/#{episode.id}/edit")

    live |> element("#add-chapter") |> render_click()

    live
    |> form("#episode-form", %{
      "episode" => %{"chapters" => %{"0" => %{"start_ms" => "0", "title" => "Intro"}}}
    })
    |> render_submit()

    assert [%{start_ms: 0, title: "Intro"}] = Ash.get!(Episode, episode.id).chapters
  end

  test "a chapter can be removed", %{conn: conn, podcast: podcast} do
    episode =
      Podcasts.create_episode!(%{
        podcast_id: podcast.id,
        title: "Folge",
        chapters: [%{start_ms: 0, title: "Intro"}, %{start_ms: 60_000, title: "Thema"}]
      })

    {:ok, live, _html} = live(conn, ~p"/admin/podcasts/#{podcast.id}/episodes/#{episode.id}/edit")

    live |> element("button[phx-value-path='episode[chapters][0]']") |> render_click()
    live |> form("#episode-form") |> render_submit()

    assert [%{title: "Thema"}] = Ash.get!(Episode, episode.id).chapters
  end

  test "transcripts can be added", %{conn: conn, podcast: podcast} do
    episode = Podcasts.create_episode!(%{podcast_id: podcast.id, title: "Folge"})

    {:ok, live, _html} = live(conn, ~p"/admin/podcasts/#{podcast.id}/episodes/#{episode.id}/edit")

    live |> element("#add-transcript") |> render_click()

    live
    |> form("#episode-form", %{
      "episode" => %{
        "transcripts" => %{"0" => %{"url" => "https://example.com/t.vtt", "type" => "text/vtt"}}
      }
    })
    |> render_submit()

    assert [%{url: "https://example.com/t.vtt", type: "text/vtt"}] =
             Ash.get!(Episode, episode.id).transcripts
  end

  test "saving returns to the podcast page", %{conn: conn, podcast: podcast} do
    {:ok, live, _html} = live(conn, ~p"/admin/podcasts/#{podcast.id}/episodes/new")

    live
    |> form("#episode-form", %{"episode" => %{"title" => "Erste Folge"}})
    |> render_submit()

    assert_redirect(live, ~p"/admin/podcasts/#{podcast.id}")
  end
end
