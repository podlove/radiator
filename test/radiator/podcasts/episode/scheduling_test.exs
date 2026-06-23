defmodule Radiator.Podcasts.Episode.SchedulingTest do
  @moduledoc """
  Resource-level tests for `Radiator.Podcasts.Episode.Scheduling`.

  Focus of this file (Issue 02 of the Episode Availability Voting epic):

  - Score model is `-1 / 0 / 1` (no, maybe, yes)
  - `voting_stats/1` exposes `total_score`, `yes_count`, `maybe_count`,
    `no_count`, `pending_count` per proposal plus a top-level
    `top_proposal_id`
  - `top_proposal_id/1` helper is consistent with `voting_stats/1`
  """
  use Radiator.DataCase, async: true

  alias Radiator.Accounts.User
  alias Radiator.Podcasts.Episode.Scheduling

  defp create_scheduling_with(opts) do
    proposed_datetimes =
      Keyword.get(opts, :proposed_datetimes, [
        ~U[2024-03-15 14:00:00Z],
        ~U[2024-03-16 10:00:00Z],
        ~U[2024-03-17 15:00:00Z]
      ])

    participant_count = Keyword.get(opts, :participant_count, 3)

    episode = generate(episode())
    owner = build_user()

    participants =
      Enum.map(1..participant_count, fn _ ->
        build_user()
      end)

    {:ok, scheduling} =
      Scheduling
      |> Ash.Changeset.for_create(:create, %{
        episode_id: episode.id,
        owner_user_id: owner.id,
        participant_user_ids: Enum.map(participants, & &1.id),
        proposed_datetimes: proposed_datetimes
      })
      |> Ash.create()

    %{scheduling: scheduling, owner: owner, participants: participants}
  end

  defp build_user do
    email = "user_#{System.unique_integer([:positive])}@example.com"
    {:ok, hashed_password} = AshAuthentication.BcryptProvider.hash("supersupersecret")
    Ash.Seed.seed!(User, %{email: email, hashed_password: hashed_password})
  end

  # Vote helper. Takes the participating `%User{}` directly and passes it as
  # both actor and `user_id` to the action.
  defp cast_vote(scheduling, proposal_id, %User{id: user_id} = user, score) do
    Scheduling.vote(scheduling, proposal_id, user_id, score, actor: user)
  end

  describe "vote/4 score values" do
    setup do
      create_scheduling_with([])
    end

    test "accepts score 1 (yes)", %{scheduling: scheduling, participants: [p | _]} do
      [proposal | _] = scheduling.proposals

      assert {:ok, updated} = cast_vote(scheduling, proposal.id, p, 1)

      [updated_proposal | _] = updated.proposals
      assert [%{user_id: pid, score: 1}] = updated_proposal.votes
      assert pid == p.id
    end

    test "accepts score 0 (maybe)", %{scheduling: scheduling, participants: [p | _]} do
      [proposal | _] = scheduling.proposals

      assert {:ok, updated} = cast_vote(scheduling, proposal.id, p, 0)

      [updated_proposal | _] = updated.proposals
      assert [%{user_id: pid, score: 0}] = updated_proposal.votes
      assert pid == p.id
    end

    test "accepts score -1 (no)", %{scheduling: scheduling, participants: [p | _]} do
      [proposal | _] = scheduling.proposals

      assert {:ok, updated} = cast_vote(scheduling, proposal.id, p, -1)

      [updated_proposal | _] = updated.proposals
      assert [%{user_id: pid, score: -1}] = updated_proposal.votes
      assert pid == p.id
    end

    test "rejects score 2 with ValidScore error", %{
      scheduling: scheduling,
      participants: [p | _]
    } do
      [proposal | _] = scheduling.proposals

      assert {:error, %Ash.Error.Invalid{} = error} = cast_vote(scheduling, proposal.id, p, 2)
      assert Exception.message(error) =~ "-1, 0 or 1"
    end

    test "rejects score -2", %{scheduling: scheduling, participants: [p | _]} do
      [proposal | _] = scheduling.proposals

      assert {:error, %Ash.Error.Invalid{} = error} = cast_vote(scheduling, proposal.id, p, -2)
      assert Exception.message(error) =~ "-1, 0 or 1"
    end

    test "rejects old-style score 5", %{scheduling: scheduling, participants: [p | _]} do
      [proposal | _] = scheduling.proposals

      assert {:error, %Ash.Error.Invalid{} = error} = cast_vote(scheduling, proposal.id, p, 5)
      assert Exception.message(error) =~ "-1, 0 or 1"
    end

    test "replaces existing vote with new score (Replace-Semantik)", %{
      scheduling: scheduling,
      participants: [p | _]
    } do
      [proposal | _] = scheduling.proposals

      assert {:ok, scheduling} = cast_vote(scheduling, proposal.id, p, 1)
      assert {:ok, scheduling} = cast_vote(scheduling, proposal.id, p, -1)

      [updated_proposal | _] = scheduling.proposals
      assert [%{user_id: pid, score: -1}] = updated_proposal.votes
      assert pid == p.id
    end

    test "rejects voting with another participant's user_id (UserIsActor)", %{
      scheduling: scheduling,
      participants: [p1, p2 | _]
    } do
      [proposal | _] = scheduling.proposals

      assert {:error, %Ash.Error.Invalid{} = error} =
               Scheduling.vote(scheduling, proposal.id, p2.id, 1, actor: p1)

      assert Exception.message(error) =~ "user does not match current actor"
    end
  end

  describe "voting_stats/1" do
    setup do
      create_scheduling_with([])
    end

    test "computes total_score, yes/maybe/no counts and pending_count=0 when everyone voted", %{
      scheduling: scheduling,
      participants: [p1, p2, p3]
    } do
      [proposal_a | _] = scheduling.proposals

      {:ok, scheduling} = cast_vote(scheduling, proposal_a.id, p1, 1)
      {:ok, scheduling} = cast_vote(scheduling, proposal_a.id, p2, 0)
      {:ok, scheduling} = cast_vote(scheduling, proposal_a.id, p3, -1)

      stats = Scheduling.voting_stats(scheduling)
      stat_a = Enum.find(stats.proposal_stats, &(&1.proposal_id == proposal_a.id))

      assert stat_a.total_score == 0
      assert stat_a.yes_count == 1
      assert stat_a.maybe_count == 1
      assert stat_a.no_count == 1
      assert stat_a.pending_count == 0
      assert length(stat_a.votes) == 3
    end

    test "pending_count equals participant_count for a proposal without any votes", %{
      scheduling: scheduling
    } do
      stats = Scheduling.voting_stats(scheduling)

      Enum.each(stats.proposal_stats, fn stat ->
        assert stat.total_score == 0
        assert stat.yes_count == 0
        assert stat.maybe_count == 0
        assert stat.no_count == 0
        assert stat.pending_count == 3
        assert stat.votes == []
      end)
    end

    test "pending_count reflects only participants without a vote on that proposal", %{
      scheduling: scheduling,
      participants: [p1, p2, _p3]
    } do
      [proposal_a | _] = scheduling.proposals

      {:ok, scheduling} = cast_vote(scheduling, proposal_a.id, p1, 1)
      {:ok, scheduling} = cast_vote(scheduling, proposal_a.id, p2, 0)

      stats = Scheduling.voting_stats(scheduling)
      stat_a = Enum.find(stats.proposal_stats, &(&1.proposal_id == proposal_a.id))

      assert stat_a.yes_count == 1
      assert stat_a.maybe_count == 1
      assert stat_a.no_count == 0
      assert stat_a.pending_count == 1
      assert stat_a.total_score == 1
    end

    test "score == 0 counts as maybe, never as pending", %{
      scheduling: scheduling,
      participants: [p1, p2, p3]
    } do
      [proposal_a | _] = scheduling.proposals

      {:ok, scheduling} = cast_vote(scheduling, proposal_a.id, p1, 0)
      {:ok, scheduling} = cast_vote(scheduling, proposal_a.id, p2, 0)
      {:ok, scheduling} = cast_vote(scheduling, proposal_a.id, p3, 0)

      stats = Scheduling.voting_stats(scheduling)
      stat_a = Enum.find(stats.proposal_stats, &(&1.proposal_id == proposal_a.id))

      assert stat_a.maybe_count == 3
      assert stat_a.pending_count == 0
      assert stat_a.total_score == 0
    end

    test "proposal_stats is sorted by total_score desc", %{
      scheduling: scheduling,
      participants: [p1, p2, p3]
    } do
      [proposal_a, proposal_b, proposal_c] = scheduling.proposals

      {:ok, scheduling} = cast_vote(scheduling, proposal_a.id, p1, 1)
      {:ok, scheduling} = cast_vote(scheduling, proposal_a.id, p2, 1)

      {:ok, scheduling} = cast_vote(scheduling, proposal_b.id, p1, 0)
      {:ok, scheduling} = cast_vote(scheduling, proposal_b.id, p3, 0)

      {:ok, scheduling} = cast_vote(scheduling, proposal_c.id, p1, -1)

      stats = Scheduling.voting_stats(scheduling)
      scores = Enum.map(stats.proposal_stats, & &1.total_score)
      ids = Enum.map(stats.proposal_stats, & &1.proposal_id)

      assert scores == [2, 0, -1]
      assert ids == [proposal_a.id, proposal_b.id, proposal_c.id]
    end

    test "top_proposal_id is set for unique winner", %{
      scheduling: scheduling,
      participants: [p1, p2, _p3]
    } do
      [proposal_a, proposal_b, _proposal_c] = scheduling.proposals

      {:ok, scheduling} = cast_vote(scheduling, proposal_a.id, p1, 1)
      {:ok, scheduling} = cast_vote(scheduling, proposal_a.id, p2, 1)

      {:ok, scheduling} = cast_vote(scheduling, proposal_b.id, p1, -1)

      stats = Scheduling.voting_stats(scheduling)
      assert stats.top_proposal_id == proposal_a.id
    end

    test "top_proposal_id is nil on tie", %{
      scheduling: scheduling,
      participants: [p1, p2, _p3]
    } do
      [proposal_a, proposal_b, _proposal_c] = scheduling.proposals

      {:ok, scheduling} = cast_vote(scheduling, proposal_a.id, p1, 1)
      {:ok, scheduling} = cast_vote(scheduling, proposal_b.id, p2, 1)

      stats = Scheduling.voting_stats(scheduling)
      assert stats.top_proposal_id == nil
    end
  end

  describe "top_proposal_id/1" do
    test "returns the proposal id for a unique winner" do
      %{scheduling: scheduling, participants: [p1, p2, _p3]} = create_scheduling_with([])
      [proposal_a, proposal_b, _proposal_c] = scheduling.proposals

      {:ok, scheduling} = cast_vote(scheduling, proposal_a.id, p1, 1)
      {:ok, scheduling} = cast_vote(scheduling, proposal_a.id, p2, 1)
      {:ok, scheduling} = cast_vote(scheduling, proposal_b.id, p1, 0)

      assert Scheduling.top_proposal_id(scheduling) == proposal_a.id
    end

    test "returns nil when two or more proposals share the highest score" do
      %{scheduling: scheduling, participants: [p1, p2, _p3]} = create_scheduling_with([])
      [proposal_a, proposal_b, _proposal_c] = scheduling.proposals

      {:ok, scheduling} = cast_vote(scheduling, proposal_a.id, p1, 1)
      {:ok, scheduling} = cast_vote(scheduling, proposal_b.id, p2, 1)

      assert Scheduling.top_proposal_id(scheduling) == nil
    end

    test "returns nil for a scheduling without proposals" do
      empty_scheduling = %Scheduling{proposals: [], participant_user_ids: []}

      assert Scheduling.top_proposal_id(empty_scheduling) == nil
    end

    test "is consistent with voting_stats(...).top_proposal_id" do
      %{scheduling: scheduling, participants: [p1, p2, p3]} = create_scheduling_with([])
      [proposal_a, proposal_b, proposal_c] = scheduling.proposals

      {:ok, scheduling} = cast_vote(scheduling, proposal_a.id, p1, 1)
      {:ok, scheduling} = cast_vote(scheduling, proposal_b.id, p2, 0)
      {:ok, scheduling} = cast_vote(scheduling, proposal_c.id, p3, -1)

      assert Scheduling.top_proposal_id(scheduling) ==
               Scheduling.voting_stats(scheduling).top_proposal_id
    end
  end

  describe "create_with_proposals action" do
    test "creates scheduling with proposals provided directly" do
      episode = generate(episode())
      owner = build_user()

      proposals = [
        %{datetime: ~U[2026-07-01 14:00:00Z], created_by_user_id: owner.id},
        %{datetime: ~U[2026-07-02 10:00:00Z], created_by_user_id: owner.id}
      ]

      assert {:ok, scheduling} =
               Scheduling
               |> Ash.Changeset.for_create(:create_with_proposals, %{
                 episode_id: episode.id,
                 owner_user_id: owner.id,
                 proposals: proposals
               })
               |> Ash.create(authorize?: false)

      assert scheduling.episode_id == episode.id
      assert scheduling.owner_user_id == owner.id
      assert scheduling.status == :open
      assert is_struct(scheduling.published_at, DateTime)
      assert length(scheduling.proposals) == 2

      datetimes = Enum.map(scheduling.proposals, & &1.datetime)
      assert ~U[2026-07-01 14:00:00Z] in datetimes
      assert ~U[2026-07-02 10:00:00Z] in datetimes
    end

    test "creates scheduling with empty proposals list" do
      episode = generate(episode())
      owner = build_user()

      assert {:ok, scheduling} =
               Scheduling
               |> Ash.Changeset.for_create(:create_with_proposals, %{
                 episode_id: episode.id,
                 owner_user_id: owner.id,
                 proposals: []
               })
               |> Ash.create(authorize?: false)

      assert scheduling.proposals == []
      assert scheduling.status == :open
    end

    test "sets status to :open and published_at" do
      episode = generate(episode())
      owner = build_user()

      {:ok, scheduling} =
        Scheduling
        |> Ash.Changeset.for_create(:create_with_proposals, %{
          episode_id: episode.id,
          owner_user_id: owner.id,
          proposals: []
        })
        |> Ash.create(authorize?: false)

      assert scheduling.status == :open
      assert %DateTime{} = scheduling.published_at
    end

    test "preserves created_by_user_id on each proposal" do
      episode = generate(episode())
      owner = build_user()
      other = build_user()

      proposals = [
        %{datetime: ~U[2026-07-01 14:00:00Z], created_by_user_id: owner.id},
        %{datetime: ~U[2026-07-02 10:00:00Z], created_by_user_id: other.id}
      ]

      {:ok, scheduling} =
        Scheduling
        |> Ash.Changeset.for_create(:create_with_proposals, %{
          episode_id: episode.id,
          owner_user_id: owner.id,
          proposals: proposals
        })
        |> Ash.create(authorize?: false)

      creator_ids = Enum.map(scheduling.proposals, & &1.created_by_user_id)
      assert owner.id in creator_ids
      assert other.id in creator_ids
    end
  end
end
