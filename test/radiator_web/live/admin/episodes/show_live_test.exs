defmodule RadiatorWeb.Admin.Episodes.ShowLiveTest do
  use RadiatorWeb.FeatureCase, async: true

  import Phoenix.ConnTest
  import Phoenix.LiveViewTest
  import Radiator.Generator

  alias AshAuthentication.Plug.Helpers
  alias Radiator.Accounts.User
  alias Radiator.Podcasts.Episode.Scheduling

  @endpoint RadiatorWeb.Endpoint

  # 2026-06-09 (Tuesday) and 2026-06-12 (Friday) are weekdays.
  # 2026-06-13 (Saturday) is a weekend day -> highlighted column.
  @tuesday ~U[2026-06-09 10:00:00Z]
  @friday ~U[2026-06-12 14:00:00Z]
  @saturday ~U[2026-06-13 18:00:00Z]

  describe "without authentication" do
    test "redirects to /sign-in", %{conn: conn} do
      podcast = generate(podcast())
      episode = generate(episode(%{podcast_id: podcast.id}))

      conn
      |> visit(~p"/admin/podcasts/#{podcast.id}/episodes/#{episode.id}")
      |> assert_path(~p"/sign-in")
    end
  end

  describe "as bob (participant)" do
    setup [:register_bob, :create_episode_with_bob_as_participant]

    test "renders the availability section with table", %{
      conn: conn,
      podcast: podcast,
      episode: episode
    } do
      conn
      |> visit(~p"/admin/podcasts/#{podcast.id}/episodes/#{episode.id}")
      |> assert_has("#availability")
      |> assert_has("table#availability-table")
      |> assert_has("h2", text: "Availability")
    end

    test "wraps the table in an overflow-x-auto container", %{
      conn: conn,
      podcast: podcast,
      episode: episode
    } do
      conn
      |> visit(~p"/admin/podcasts/#{podcast.id}/episodes/#{episode.id}")
      |> assert_has(".overflow-x-auto #availability-table")
    end

    test "marks Bob's row with a (du) suffix", %{
      conn: conn,
      podcast: podcast,
      episode: episode,
      bob: bob
    } do
      conn
      |> visit(~p"/admin/podcasts/#{podcast.id}/episodes/#{episode.id}")
      |> assert_has("#availability-row-#{bob.id}", text: "Bob")
      |> assert_has("#availability-row-#{bob.id}", text: "(du)")
    end

    test "does not mark other participants' rows with (du)", %{
      conn: conn,
      podcast: podcast,
      episode: episode,
      jim: jim,
      alice: alice
    } do
      session =
        conn
        |> visit(~p"/admin/podcasts/#{podcast.id}/episodes/#{episode.id}")

      session
      |> refute_has("#availability-row-#{jim.id}", text: "(du)")
      |> refute_has("#availability-row-#{alice.id}", text: "(du)")
    end

    test "marks the top proposal column header with border-2 border-primary", %{
      conn: conn,
      podcast: podcast,
      episode: episode,
      friday_proposal: friday_proposal,
      tuesday_proposal: tuesday_proposal
    } do
      session =
        conn
        |> visit(~p"/admin/podcasts/#{podcast.id}/episodes/#{episode.id}")

      session
      |> assert_has("#availability-header-#{friday_proposal.id}.border-2")
      |> assert_has("#availability-header-#{friday_proposal.id}.border-primary")
      |> refute_has("#availability-header-#{tuesday_proposal.id}.border-primary")
    end

    test "marks weekend column headers with bg-base-200", %{
      conn: conn,
      podcast: podcast,
      episode: episode,
      saturday_proposal: saturday_proposal,
      tuesday_proposal: tuesday_proposal
    } do
      session =
        conn
        |> visit(~p"/admin/podcasts/#{podcast.id}/episodes/#{episode.id}")

      session
      |> assert_has("#availability-header-#{saturday_proposal.id}.bg-base-200")
      |> refute_has("#availability-header-#{tuesday_proposal.id}.bg-base-200")
    end

    test "renders text-success icon for yes votes", %{
      conn: conn,
      podcast: podcast,
      episode: episode,
      friday_proposal: friday_proposal,
      jim: jim
    } do
      conn
      |> visit(~p"/admin/podcasts/#{podcast.id}/episodes/#{episode.id}")
      |> assert_has("#availability-row-#{jim.id} .text-success")
      |> assert_has("#availability-cell-#{friday_proposal.id}-#{jim.id} .text-success")
    end

    test "renders text-warning icon for maybe votes", %{
      conn: conn,
      podcast: podcast,
      episode: episode,
      tuesday_proposal: tuesday_proposal,
      carol: carol
    } do
      conn
      |> visit(~p"/admin/podcasts/#{podcast.id}/episodes/#{episode.id}")
      |> assert_has("#availability-cell-#{tuesday_proposal.id}-#{carol.id} .text-warning")
    end

    test "renders text-error icon for no votes", %{
      conn: conn,
      podcast: podcast,
      episode: episode,
      tuesday_proposal: tuesday_proposal,
      alice: alice
    } do
      conn
      |> visit(~p"/admin/podcasts/#{podcast.id}/episodes/#{episode.id}")
      |> assert_has("#availability-cell-#{tuesday_proposal.id}-#{alice.id} .text-error")
    end

    test "Bob's own cells render voting buttons instead of opacity-40 dashes", %{
      conn: conn,
      podcast: podcast,
      episode: episode,
      bob: bob,
      tuesday_proposal: tuesday_proposal,
      friday_proposal: friday_proposal,
      saturday_proposal: saturday_proposal
    } do
      session =
        conn
        |> visit(~p"/admin/podcasts/#{podcast.id}/episodes/#{episode.id}")

      session
      |> refute_has("#availability-cell-#{tuesday_proposal.id}-#{bob.id} .opacity-40")
      |> refute_has("#availability-cell-#{friday_proposal.id}-#{bob.id} .opacity-40")
      |> refute_has("#availability-cell-#{saturday_proposal.id}-#{bob.id} .opacity-40")
      |> assert_has("#availability-cell-#{tuesday_proposal.id}-#{bob.id} button")
      |> assert_has("#availability-cell-#{friday_proposal.id}-#{bob.id} button")
      |> assert_has("#availability-cell-#{saturday_proposal.id}-#{bob.id} button")
    end

    test "renders footer score cells with sign prefix", %{
      conn: conn,
      podcast: podcast,
      episode: episode,
      friday_proposal: friday_proposal,
      tuesday_proposal: tuesday_proposal,
      saturday_proposal: saturday_proposal
    } do
      session =
        conn
        |> visit(~p"/admin/podcasts/#{podcast.id}/episodes/#{episode.id}")

      session
      |> assert_has("#availability-footer-#{friday_proposal.id}", text: "+3")
      |> assert_has("#availability-footer-#{tuesday_proposal.id}", text: "0")
      |> assert_has("#availability-footer-#{saturday_proposal.id}", text: "-2")
    end

    test "footer cell of top proposal carries border-2 border-primary", %{
      conn: conn,
      podcast: podcast,
      episode: episode,
      friday_proposal: friday_proposal
    } do
      conn
      |> visit(~p"/admin/podcasts/#{podcast.id}/episodes/#{episode.id}")
      |> assert_has("#availability-footer-#{friday_proposal.id}.border-2")
      |> assert_has("#availability-footer-#{friday_proposal.id}.border-primary")
    end

    test "name column cells are sticky left-0", %{
      conn: conn,
      podcast: podcast,
      episode: episode,
      bob: bob
    } do
      conn
      |> visit(~p"/admin/podcasts/#{podcast.id}/episodes/#{episode.id}")
      |> assert_has("#availability-table thead th.sticky.left-0")
      |> assert_has("#availability-row-#{bob.id} td.sticky.left-0")
    end

    test "renders weekday labels in column headers", %{
      conn: conn,
      podcast: podcast,
      episode: episode,
      tuesday_proposal: tuesday_proposal,
      friday_proposal: friday_proposal,
      saturday_proposal: saturday_proposal
    } do
      session =
        conn
        |> visit(~p"/admin/podcasts/#{podcast.id}/episodes/#{episode.id}")

      session
      |> assert_has("#availability-header-#{tuesday_proposal.id}", text: "Di")
      |> assert_has("#availability-header-#{friday_proposal.id}", text: "Fr")
      |> assert_has("#availability-header-#{saturday_proposal.id}", text: "Sa")
    end

    test "renders three voting buttons per proposal in Bob's row", %{
      conn: conn,
      podcast: podcast,
      episode: episode,
      tuesday_proposal: tuesday_proposal,
      friday_proposal: friday_proposal,
      saturday_proposal: saturday_proposal
    } do
      session = visit(conn, ~p"/admin/podcasts/#{podcast.id}/episodes/#{episode.id}")

      for proposal <- [tuesday_proposal, friday_proposal, saturday_proposal] do
        session
        |> assert_has("button#vote-#{proposal.id}-yes")
        |> assert_has("button#vote-#{proposal.id}-maybe")
        |> assert_has("button#vote-#{proposal.id}-no")
      end
    end

    test "yes button click activates btn-success and updates footer score", %{
      conn: conn,
      podcast: podcast,
      episode: episode,
      friday_proposal: friday_proposal
    } do
      {:ok, lv, _html} =
        live(conn, ~p"/admin/podcasts/#{podcast.id}/episodes/#{episode.id}")

      lv
      |> element("#vote-#{friday_proposal.id}-yes")
      |> render_click()

      assert has_element?(lv, "#vote-#{friday_proposal.id}-yes.btn-success")
      assert has_element?(lv, "#availability-footer-#{friday_proposal.id}", "+4")
    end

    test "clicking no after yes flips the active state and adjusts footer score", %{
      conn: conn,
      podcast: podcast,
      episode: episode,
      friday_proposal: friday_proposal
    } do
      {:ok, lv, _html} =
        live(conn, ~p"/admin/podcasts/#{podcast.id}/episodes/#{episode.id}")

      lv |> element("#vote-#{friday_proposal.id}-yes") |> render_click()
      lv |> element("#vote-#{friday_proposal.id}-no") |> render_click()

      refute has_element?(lv, "#vote-#{friday_proposal.id}-yes.btn-success")
      assert has_element?(lv, "#vote-#{friday_proposal.id}-no.btn-error")
      assert has_element?(lv, "#availability-footer-#{friday_proposal.id}", "+2")
    end

    test "manipulated score value triggers flash and no DB write", %{
      conn: conn,
      podcast: podcast,
      episode: episode,
      friday_proposal: friday_proposal,
      bob: bob
    } do
      {:ok, lv, _html} =
        live(conn, ~p"/admin/podcasts/#{podcast.id}/episodes/#{episode.id}")

      html =
        render_hook(lv, "vote", %{
          "proposal-id" => friday_proposal.id,
          "score" => "2"
        })

      assert html =~ "Could not record your vote"

      [scheduling] = Scheduling.get_by_episode!(episode.id, authorize?: false)

      updated_friday = Enum.find(scheduling.proposals, &(&1.id == friday_proposal.id))
      refute Enum.any?(updated_friday.votes, &(&1.user_id == bob.id))
    end
  end

  describe "as bob (participant) on a closed scheduling" do
    setup [:register_bob, :create_closed_scheduling_with_bob]

    test "all three voting buttons in Bob's row are disabled", %{
      conn: conn,
      podcast: podcast,
      episode: episode,
      tuesday_proposal: tuesday_proposal,
      friday_proposal: friday_proposal,
      saturday_proposal: saturday_proposal
    } do
      session = visit(conn, ~p"/admin/podcasts/#{podcast.id}/episodes/#{episode.id}")

      for proposal <- [tuesday_proposal, friday_proposal, saturday_proposal] do
        session
        |> assert_has("button#vote-#{proposal.id}-yes[disabled]")
        |> assert_has("button#vote-#{proposal.id}-maybe[disabled]")
        |> assert_has("button#vote-#{proposal.id}-no[disabled]")
      end
    end

    test "render_hook on vote does not persist a vote when closed", %{
      conn: conn,
      podcast: podcast,
      episode: episode,
      friday_proposal: friday_proposal,
      bob: bob
    } do
      {:ok, lv, _html} =
        live(conn, ~p"/admin/podcasts/#{podcast.id}/episodes/#{episode.id}")

      html =
        render_hook(lv, "vote", %{
          "proposal-id" => friday_proposal.id,
          "score" => "1"
        })

      assert html =~ "Could not record your vote"

      [scheduling] = Scheduling.get_by_episode!(episode.id, authorize?: false)

      updated_friday = Enum.find(scheduling.proposals, &(&1.id == friday_proposal.id))
      refute Enum.any?(updated_friday.votes, &(&1.user_id == bob.id))
    end

    test "chosen proposal column header shows a 'Chosen' badge", %{
      conn: conn,
      podcast: podcast,
      episode: episode,
      tuesday_proposal: tuesday_proposal,
      friday_proposal: friday_proposal
    } do
      session = visit(conn, ~p"/admin/podcasts/#{podcast.id}/episodes/#{episode.id}")

      session
      |> assert_has("#availability-header-#{tuesday_proposal.id} span.badge", text: "Chosen")
      |> refute_has("#availability-header-#{friday_proposal.id} span.badge", text: "Chosen")
    end

    test "winner highlight follows chosen proposal, not automatic top", %{
      conn: conn,
      podcast: podcast,
      episode: episode,
      tuesday_proposal: tuesday_proposal,
      friday_proposal: friday_proposal
    } do
      session = visit(conn, ~p"/admin/podcasts/#{podcast.id}/episodes/#{episode.id}")

      session
      |> assert_has("#availability-header-#{tuesday_proposal.id}.border-primary")
      |> assert_has("#availability-footer-#{tuesday_proposal.id}.border-primary")
      |> refute_has("#availability-header-#{friday_proposal.id}.border-primary")
      |> refute_has("#availability-footer-#{friday_proposal.id}.border-primary")
    end
  end

  describe "as bob (participant) on a closed scheduling without chosen proposal" do
    setup [:register_bob, :create_closed_scheduling_without_chosen]

    test "all three voting buttons in Bob's row are disabled", %{
      conn: conn,
      podcast: podcast,
      episode: episode,
      tuesday_proposal: tuesday_proposal,
      friday_proposal: friday_proposal,
      saturday_proposal: saturday_proposal
    } do
      session = visit(conn, ~p"/admin/podcasts/#{podcast.id}/episodes/#{episode.id}")

      for proposal <- [tuesday_proposal, friday_proposal, saturday_proposal] do
        session
        |> assert_has("button#vote-#{proposal.id}-yes[disabled]")
        |> assert_has("button#vote-#{proposal.id}-maybe[disabled]")
        |> assert_has("button#vote-#{proposal.id}-no[disabled]")
      end
    end

    test "no chosen badge appears anywhere", %{
      conn: conn,
      podcast: podcast,
      episode: episode
    } do
      conn
      |> visit(~p"/admin/podcasts/#{podcast.id}/episodes/#{episode.id}")
      |> refute_has("#availability span.badge", text: "Chosen")
    end

    test "no winner highlight on any header or footer", %{
      conn: conn,
      podcast: podcast,
      episode: episode
    } do
      conn
      |> visit(~p"/admin/podcasts/#{podcast.id}/episodes/#{episode.id}")
      |> refute_has("#availability-table .border-primary")
    end
  end

  describe "as user who is not a participant" do
    setup [:register_unrelated_user, :create_episode_without_bob]

    test "renders the availability table without a (du) marker anywhere", %{
      conn: conn,
      podcast: podcast,
      episode: episode
    } do
      conn
      |> visit(~p"/admin/podcasts/#{podcast.id}/episodes/#{episode.id}")
      |> assert_has("#availability-table")
      |> refute_has("#availability tbody", text: "(du)")
    end

    test "is read-only: no vote buttons render", %{
      conn: conn,
      podcast: podcast,
      episode: episode
    } do
      conn
      |> visit(~p"/admin/podcasts/#{podcast.id}/episodes/#{episode.id}")
      |> refute_has("[id^='vote-']")
      |> refute_has("[phx-click='vote']")
    end
  end

  describe "as user who is not a participant of the scheduling" do
    setup [:register_unrelated_user, :create_episode_without_bob]

    test "renders the availability table without a (du) marker anywhere", %{
      conn: conn,
      podcast: podcast,
      episode: episode,
      user: user
    } do
      session =
        conn
        |> visit(~p"/admin/podcasts/#{podcast.id}/episodes/#{episode.id}")

      session
      |> assert_has("#availability-table")
      |> refute_has("#availability tbody", text: "(du)")
      |> refute_has("#availability-row-#{user.id}")
    end

    test "is read-only: no vote buttons render", %{
      conn: conn,
      podcast: podcast,
      episode: episode
    } do
      conn
      |> visit(~p"/admin/podcasts/#{podcast.id}/episodes/#{episode.id}")
      |> refute_has("[id^='vote-']")
      |> refute_has("[phx-click='vote']")
    end
  end

  defp register_bob(%{conn: conn} = context) do
    {user, conn} = create_user_and_log_in(conn, "bob", "Bob")
    Map.merge(context, %{conn: conn, user: user, bob: user})
  end

  defp register_unrelated_user(%{conn: conn} = context) do
    {user, conn} = create_user_and_log_in(conn, "outsider", "Outsider")
    Map.merge(context, %{conn: conn, user: user})
  end

  defp create_user_and_log_in(conn, prefix, display_name) do
    email = "#{prefix}_#{System.unique_integer([:positive])}@example.com"
    password = "supersupersecret"
    {:ok, hashed_password} = AshAuthentication.BcryptProvider.hash(password)

    Ash.Seed.seed!(User, %{email: email, hashed_password: hashed_password})

    strategy = AshAuthentication.Info.strategy!(User, :password)

    {:ok, user} =
      AshAuthentication.Strategy.action(strategy, :sign_in, %{
        email: email,
        password: password
      })

    person = generate(person(%{display_name: display_name}))

    user =
      user
      |> Ash.Changeset.for_update(:update_profile, %{person_id: person.id}, authorize?: false)
      |> Ash.update!()
      |> Ash.load!([:display_name], authorize?: false)

    new_conn =
      conn
      |> Phoenix.ConnTest.init_test_session(%{})
      |> Helpers.store_in_session(user)

    {user, new_conn}
  end

  defp create_episode_with_bob_as_participant(%{bob: bob} = context) do
    owner = build_user("Owner")
    jim = build_user("Jim")
    alice = build_user("Alice")
    carol = build_user("Carol")

    podcast = generate(podcast())
    episode = generate(episode(%{podcast_id: podcast.id}))

    {:ok, scheduling} =
      Scheduling
      |> Ash.Changeset.for_create(:create, %{
        episode_id: episode.id,
        owner_user_id: owner.id,
        participant_user_ids: [bob.id, jim.id, alice.id, carol.id],
        proposed_datetimes: [@tuesday, @friday, @saturday]
      })
      |> Ash.create(authorize?: false)

    [tuesday_proposal, friday_proposal, saturday_proposal] =
      Enum.sort_by(scheduling.proposals, & &1.datetime, DateTime)

    scheduling
    |> place_vote!(tuesday_proposal.id, jim, 1)
    |> place_vote!(tuesday_proposal.id, alice, -1)
    |> place_vote!(tuesday_proposal.id, carol, 0)
    |> place_vote!(friday_proposal.id, jim, 1)
    |> place_vote!(friday_proposal.id, alice, 1)
    |> place_vote!(friday_proposal.id, carol, 1)
    |> place_vote!(saturday_proposal.id, jim, 0)
    |> place_vote!(saturday_proposal.id, alice, -1)
    |> place_vote!(saturday_proposal.id, carol, -1)

    Map.merge(context, %{
      podcast: podcast,
      episode: episode,
      owner: owner,
      jim: jim,
      alice: alice,
      carol: carol,
      tuesday_proposal: tuesday_proposal,
      friday_proposal: friday_proposal,
      saturday_proposal: saturday_proposal
    })
  end

  defp create_closed_scheduling_with_bob(context) do
    # Bob's row has the highest score on Friday (auto top). The owner deliberately
    # picks the weaker Tuesday slot so we can prove the winner highlight follows
    # the owner's choice, not the automatic ranking.
    context
    |> create_episode_with_bob_as_participant()
    |> finalize_scheduling_to(:tuesday_proposal)
  end

  defp create_closed_scheduling_without_chosen(context) do
    context
    |> create_episode_with_bob_as_participant()
    |> finalize_scheduling_to(:tuesday_proposal)
    |> clear_chosen_proposal()
  end

  defp finalize_scheduling_to(context, proposal_key) do
    chosen_proposal = Map.fetch!(context, proposal_key)
    episode = Map.fetch!(context, :episode)

    [scheduling] = Scheduling.get_by_episode!(episode.id, authorize?: false)

    {:ok, finalized} =
      scheduling
      |> Ash.Changeset.for_update(:finalize, %{
        chosen_proposal_id: chosen_proposal.id,
        user_id: scheduling.owner_user_id
      })
      |> Ash.update(authorize?: false)

    Map.put(context, :scheduling, finalized)
  end

  defp clear_chosen_proposal(%{scheduling: scheduling} = context) do
    cleared =
      Ash.Seed.update!(scheduling, %{
        chosen_proposal_id: nil,
        chosen_datetime: nil
      })

    Map.put(context, :scheduling, cleared)
  end

  defp create_episode_without_bob(context) do
    owner = build_user("Owner")
    jim = build_user("Jim")
    alice = build_user("Alice")

    podcast = generate(podcast())
    episode = generate(episode(%{podcast_id: podcast.id}))

    {:ok, _scheduling} =
      Scheduling
      |> Ash.Changeset.for_create(:create, %{
        episode_id: episode.id,
        owner_user_id: owner.id,
        participant_user_ids: [jim.id, alice.id],
        proposed_datetimes: [@tuesday, @friday, @saturday]
      })
      |> Ash.create(authorize?: false)

    Map.merge(context, %{
      podcast: podcast,
      episode: episode,
      owner: owner,
      jim: jim,
      alice: alice
    })
  end

  defp build_user(name) do
    person = generate(person(%{display_name: name}))
    generate(user(%{person_id: person.id}))
  end

  defp place_vote!(scheduling, proposal_id, %User{id: user_id} = user, score) do
    {:ok, scheduling} =
      scheduling
      |> Ash.Changeset.for_update(
        :vote,
        %{
          proposal_id: proposal_id,
          user_id: user_id,
          score: score
        },
        actor: user
      )
      |> Ash.update(authorize?: false)

    scheduling
  end
end
