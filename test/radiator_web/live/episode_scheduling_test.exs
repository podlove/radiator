defmodule RadiatorWeb.EpisodeSchedulingTest do
  use RadiatorWeb.ConnCase, async: true

  import Phoenix.LiveViewTest

  alias Radiator.Podcasts
  alias Radiator.Podcasts.Episode
  alias Radiator.Podcasts.EpisodeContributor
  alias Radiator.Podcasts.Person
  alias Radiator.Podcasts.PodcastUserRole

  # 19:00 in Berlin in November.
  @fri ~U[2026-11-06 18:00:00Z]
  @sat ~U[2026-11-07 09:00:00Z]

  setup :register_and_log_in_user

  setup %{user: member} do
    podcast = Podcasts.create_podcast!(%{title: "Test Show"}, actor: member)
    episode = Podcasts.create_episode!(%{podcast_id: podcast.id, title: "Folge 1"})

    alice = register_user("alice@example.com")
    bob = register_user("bob@example.com")
    alice_person = contribute!(episode, member, "Alice", alice)
    bob_person = contribute!(episode, member, "Bob", bob)

    %{
      member: member,
      podcast: podcast,
      episode: episode,
      alice: alice,
      alice_person: alice_person,
      bob: bob,
      bob_person: bob_person,
      path: ~p"/admin/podcasts/#{podcast.id}/episodes/#{episode.id}/scheduling"
    }
  end

  defp contribute!(episode, owner, name, account) do
    person =
      Ash.create!(Person, %{name: name, user_id: owner.id, account_id: account.id},
        action: :create
      )

    Ash.create!(EpisodeContributor, %{episode_id: episode.id, person_id: person.id})
    person
  end

  defp as(user), do: log_in(build_conn(), user)

  defp start!(%{episode: episode, member: member}, datetimes \\ [@fri, @sat]),
    do: Podcasts.start_scheduling!(episode.id, datetimes, actor: member)

  defp proposal_at(scheduling, datetime),
    do: Enum.find(scheduling.proposals, &(&1.datetime == datetime))

  defp scheduling!(%{episode: episode, member: member}),
    do: Podcasts.get_scheduling_by_episode!(episode.id, actor: member)

  describe "access" do
    test "somebody who neither is a member nor contributes is sent away", %{path: path} do
      stranger = register_user("stranger@example.com")

      assert {:error, {:live_redirect, %{to: "/admin", flash: flash}}} = live(as(stranger), path)
      assert flash["error"] =~ "nicht für dich"
    end

    test "a contributor who is no member opens the page from the invitation", %{
      alice: alice,
      path: path
    } do
      assert {:ok, _live, html} = live(as(alice), path)
      assert html =~ "Folge 1"
      assert html =~ "Test Show"
    end
  end

  describe "before the search started" do
    test "a member starts it with a first date in their time zone", context do
      %{conn: conn, path: path} = context
      {:ok, live, _html} = live(conn, path)

      live
      |> form("#start-form", proposal: %{datetime: "2026-11-06T19:00"})
      |> render_submit()

      assert [%{datetime: @fri}] = scheduling!(context).proposals
      assert has_element?(live, "#availability-table")
      assert render(live) =~ "Terminfindung gestartet."
    end

    test "a contributor is told nothing is being searched yet", %{alice: alice, path: path} do
      {:ok, live, html} = live(as(alice), path)

      assert html =~ "noch kein Termin gesucht"
      refute has_element?(live, "#start-form")
    end
  end

  describe "the availability matrix" do
    setup context, do: %{scheduling: start!(context)}

    test "shows the dates in calendar order with weekday, weekend and local time", %{
      conn: conn,
      path: path,
      scheduling: scheduling
    } do
      {:ok, live, _html} = live(conn, path)
      fri = proposal_at(scheduling, @fri)
      sat = proposal_at(scheduling, @sat)

      assert live |> element("#availability-header-#{fri.id}") |> render() =~ "Fr"
      assert live |> element("#availability-header-#{fri.id}") |> render() =~ "06.11.2026"
      assert live |> element("#availability-header-#{fri.id}") |> render() =~ "19:00"
      assert has_element?(live, "#availability-header-#{sat.id}.bg-base-200")
      refute has_element?(live, "#availability-header-#{fri.id}.bg-base-200")
    end

    test "uses the browser's time zone", %{conn: conn, path: path, scheduling: scheduling} do
      fri = proposal_at(scheduling, @fri)

      {:ok, live, _html} =
        conn |> put_connect_params(%{"timezone" => "America/New_York"}) |> live(path)

      assert live |> element("#availability-header-#{fri.id}") |> render() =~ "13:00"
    end

    test "lists the contributors with an account and marks the own row", %{
      alice: alice,
      alice_person: alice_person,
      bob_person: bob_person,
      path: path
    } do
      {:ok, live, _html} = live(as(alice), path)

      assert live |> element("#availability-row-#{alice_person.id}") |> render() =~ "(du)"
      refute live |> element("#availability-row-#{bob_person.id}") |> render() =~ "(du)"
    end

    test "a contributor votes and changes their mind", %{
      alice: alice,
      path: path,
      scheduling: scheduling
    } do
      fri = proposal_at(scheduling, @fri)
      {:ok, live, _html} = live(as(alice), path)

      live |> element("#vote-#{fri.id}-yes") |> render_click()

      assert has_element?(live, "#vote-#{fri.id}-yes.btn-success")
      assert live |> element("#availability-footer-#{fri.id}") |> render() =~ "+1"

      live |> element("#vote-#{fri.id}-no") |> render_click()

      assert has_element?(live, "#vote-#{fri.id}-no.btn-error")
      refute has_element?(live, "#vote-#{fri.id}-yes.btn-success")
      assert live |> element("#availability-footer-#{fri.id}") |> render() =~ "-1"
    end

    test "other people's votes show as icons", %{
      bob: bob,
      bob_person: bob_person,
      alice: alice,
      path: path,
      scheduling: scheduling
    } do
      fri = proposal_at(scheduling, @fri)
      Podcasts.vote_on_proposal!(scheduling, fri.id, 0, actor: bob)

      {:ok, live, _html} = live(as(alice), path)

      assert has_element?(live, "#availability-cell-#{fri.id}-#{bob_person.id} .text-warning")
      refute has_element?(live, "#availability-cell-#{fri.id}-#{bob_person.id} button")
    end

    test "a forged score shows an error and stores nothing",
         %{alice: alice, path: path} = context do
      fri = proposal_at(context.scheduling, @fri)
      {:ok, live, _html} = live(as(alice), path)

      html = render_click(live, "vote", %{"proposal-id" => fri.id, "score" => "5"})

      assert html =~ "Deine Stimme konnte nicht gespeichert werden."
      assert proposal_at(scheduling!(context), @fri).votes == []
    end

    test "the member who started it votes, another member does not", %{
      conn: conn,
      podcast: podcast,
      path: path,
      scheduling: scheduling
    } do
      fri = proposal_at(scheduling, @fri)
      {:ok, starter_live, _html} = live(conn, path)

      assert has_element?(starter_live, "#vote-#{fri.id}-yes:not([disabled])")

      other = register_user("other-member@example.com")

      Ash.create!(
        PodcastUserRole,
        %{podcast_id: podcast.id, user_id: other.id, role: :owner},
        authorize?: false
      )

      {:ok, other_live, _html} = live(as(other), path)

      refute has_element?(other_live, "button[phx-click='vote']")
      assert has_element?(other_live, "#ranking")
    end

    test "a contributor proposes a date and removes only their own",
         %{
           alice: alice,
           path: path,
           scheduling: scheduling
         } = context do
      {:ok, live, _html} = live(as(alice), path)

      live
      |> form("#proposal-form", proposal: %{datetime: "2026-11-08T19:00"})
      |> render_submit()

      new = proposal_at(scheduling!(context), ~U[2026-11-08 18:00:00Z])
      assert new
      assert has_element?(live, "#remove-proposal-#{new.id}")
      refute has_element?(live, "#remove-proposal-#{proposal_at(scheduling, @fri).id}")

      live |> element("#remove-proposal-#{new.id}") |> render_click()

      refute proposal_at(scheduling!(context), ~U[2026-11-08 18:00:00Z])
    end
  end

  describe "the decision" do
    setup context do
      scheduling = start!(context)
      fri = proposal_at(scheduling, @fri)
      scheduling = Podcasts.vote_on_proposal!(scheduling, fri.id, 1, actor: context.alice)
      %{scheduling: scheduling}
    end

    test "only members see the ranking", %{conn: conn, alice: alice, path: path} do
      {:ok, member_live, _html} = live(conn, path)
      {:ok, alice_live, _html} = live(as(alice), path)

      assert has_element?(member_live, "#ranking")
      refute has_element?(alice_live, "#ranking")
    end

    test "the ranking puts the best date first and tells who is missing", %{
      conn: conn,
      path: path,
      scheduling: scheduling
    } do
      {:ok, live, _html} = live(conn, path)
      fri = proposal_at(scheduling, @fri)

      assert live |> element("#ranking li:first-child") |> render() =~ "06.11.2026"
      assert has_element?(live, "#availability-header-#{fri.id} [aria-label='Bester Termin']")
      assert live |> element("#ranking-pending") |> render() =~ "1 von 3 haben abgestimmt."
    end

    test "a member picks a date, which closes the vote, and reopens it", %{
      conn: conn,
      alice: alice,
      path: path,
      scheduling: scheduling,
      episode: episode
    } do
      sat = proposal_at(scheduling, @sat)
      {:ok, live, _html} = live(conn, path)

      live |> element("#finalize-#{sat.id}") |> render_click()

      assert has_element?(live, "#scheduling-status", "07.11.2026")
      assert live |> element("#availability-header-#{sat.id}") |> render() =~ "Gewählt"
      assert has_element?(live, "#availability-header-#{sat.id} [aria-label='Bester Termin']")
      assert Ash.get!(Episode, episode.id).state == :scheduled

      {:ok, alice_live, _html} = live(as(alice), path)
      assert has_element?(alice_live, "#vote-#{sat.id}-yes[disabled]")
      refute has_element?(alice_live, "#proposal-form")

      live |> element("#reopen") |> render_click()

      refute has_element?(live, "#scheduling-status")
      assert Ash.get!(Episode, episode.id).state == :scheduling
    end
  end

  describe "links" do
    setup context, do: %{scheduling: start!(context)}

    test "the podcast page and the episode form lead to the scheduling", %{
      conn: conn,
      podcast: podcast,
      episode: episode,
      path: path
    } do
      {:ok, podcast_live, _html} = live(conn, ~p"/admin/podcasts/#{podcast.id}")
      assert has_element?(podcast_live, "#scheduling-link-#{episode.id}[href='#{path}']")

      {:ok, form_live, _html} =
        live(conn, ~p"/admin/podcasts/#{podcast.id}/episodes/#{episode.id}/edit")

      assert has_element?(form_live, "#scheduling-link[href='#{path}']")
    end
  end
end
