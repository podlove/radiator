defmodule RadiatorWeb.EpisodeFormTest do
  use RadiatorWeb.ConnCase, async: true

  import Phoenix.LiveViewTest
  import Swoosh.TestAssertions

  alias Radiator.Podcasts
  alias Radiator.Podcasts.Episode
  alias Radiator.Podcasts.EpisodeContributor

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

  describe "contributors" do
    setup %{user: user, podcast: podcast} do
      anna = generate(person(name: "Anna", normalized_name: "anna", user_id: user.id))
      past = Podcasts.create_episode!(%{podcast_id: podcast.id, title: "Früher"})
      Ash.create!(EpisodeContributor, %{episode_id: past.id, person_id: anna.id, role: "host"})

      %{person: anna}
    end

    defp contributors(episode) do
      Ash.load!(Ash.get!(Episode, episode.id), :contributors).contributors
    end

    defp type(live, text) do
      live
      |> form("#episode-form", %{"episode" => %{"contributors" => %{"0" => %{"email" => text}}}})
      |> render_change(%{"_target" => ["episode", "contributors", "0", "email"]})
    end

    test "the edit form lists the episode's contributors", %{
      conn: conn,
      podcast: podcast,
      person: person
    } do
      episode = Podcasts.create_episode!(%{podcast_id: podcast.id, title: "Folge"})

      Ash.create!(EpisodeContributor, %{
        episode_id: episode.id,
        person_id: person.id,
        role: "host"
      })

      {:ok, _live, html} =
        live(conn, ~p"/admin/podcasts/#{podcast.id}/episodes/#{episode.id}/edit")

      assert html =~ "Anna"
      assert html =~ ~s(value="host")
    end

    test "typing suggests only this podcast's contributors", %{
      conn: conn,
      podcast: podcast,
      user: user
    } do
      other = Podcasts.create_podcast!(%{title: "Other"}, actor: user)
      elsewhere = Podcasts.create_episode!(%{podcast_id: other.id, title: "Else"})
      annika = generate(person(name: "Annika", normalized_name: "annika", user_id: user.id))
      Ash.create!(EpisodeContributor, %{episode_id: elsewhere.id, person_id: annika.id})

      {:ok, live, _html} = live(conn, ~p"/admin/podcasts/#{podcast.id}/episodes/new")
      live |> element("#add-contributor") |> render_click()

      html = type(live, "ann")

      assert html =~ "pick-contributor"
      assert html =~ "Anna"
      refute html =~ "Annika"
    end

    test "a picked suggestion is saved", %{conn: conn, podcast: podcast, person: person} do
      episode = Podcasts.create_episode!(%{podcast_id: podcast.id, title: "Folge"})

      {:ok, live, _html} =
        live(conn, ~p"/admin/podcasts/#{podcast.id}/episodes/#{episode.id}/edit")

      live |> element("#add-contributor") |> render_click()
      type(live, "AN")
      live |> element("button[phx-click='pick-contributor']", "Anna") |> render_click()

      live
      |> form("#episode-form", %{
        "episode" => %{"contributors" => %{"0" => %{"role" => "guest"}}}
      })
      |> render_submit()

      person_id = person.id
      assert [%{person_id: ^person_id, role: "guest"}] = contributors(episode)
    end

    test "an email adds a new account and mails it", %{conn: conn, podcast: podcast} do
      episode = Podcasts.create_episode!(%{podcast_id: podcast.id, title: "Folge"})

      {:ok, live, _html} =
        live(conn, ~p"/admin/podcasts/#{podcast.id}/episodes/#{episode.id}/edit")

      live |> element("#add-contributor") |> render_click()
      type(live, "bob@example.com")

      live
      |> form("#episode-form", %{
        "episode" => %{"contributors" => %{"0" => %{"email" => "bob@example.com"}}}
      })
      |> render_submit()

      assert [contributor] = contributors(episode)

      assert to_string(
               Ash.load!(contributor, [person: :account], authorize?: false).person.account.email
             ) ==
               "bob@example.com"

      assert_email_sent(to: [{"", "bob@example.com"}])
    end

    test "a name that was not picked is rejected", %{conn: conn, podcast: podcast} do
      episode = Podcasts.create_episode!(%{podcast_id: podcast.id, title: "Folge"})

      {:ok, live, _html} =
        live(conn, ~p"/admin/podcasts/#{podcast.id}/episodes/#{episode.id}/edit")

      live |> element("#add-contributor") |> render_click()
      type(live, "Anna")

      html =
        live
        |> form("#episode-form", %{
          "episode" => %{"contributors" => %{"0" => %{"email" => "Anna"}}}
        })
        |> render_submit()

      assert html =~ "must be an email address"
      assert [] = contributors(episode)
    end

    test "a contributor can be removed", %{conn: conn, podcast: podcast, person: person} do
      episode = Podcasts.create_episode!(%{podcast_id: podcast.id, title: "Folge"})

      Ash.create!(EpisodeContributor, %{
        episode_id: episode.id,
        person_id: person.id,
        role: "host"
      })

      {:ok, live, _html} =
        live(conn, ~p"/admin/podcasts/#{podcast.id}/episodes/#{episode.id}/edit")

      live
      |> element("button[phx-value-path='episode[contributors][0]'][phx-click='remove-form']")
      |> render_click()

      live |> form("#episode-form") |> render_submit()

      assert [] = contributors(episode)
    end
  end

  test "saving returns to the podcast page", %{conn: conn, podcast: podcast} do
    {:ok, live, _html} = live(conn, ~p"/admin/podcasts/#{podcast.id}/episodes/new")

    live
    |> form("#episode-form", %{"episode" => %{"title" => "Erste Folge"}})
    |> render_submit()

    assert_redirect(live, ~p"/admin/podcasts/#{podcast.id}")
  end
end
