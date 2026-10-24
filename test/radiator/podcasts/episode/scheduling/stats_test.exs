defmodule Radiator.Podcasts.Episode.Scheduling.StatsTest do
  use ExUnit.Case, async: true

  alias Radiator.Podcasts.Episode.Scheduling
  alias Radiator.Podcasts.Episode.Scheduling.Proposal
  alias Radiator.Podcasts.Episode.Scheduling.Stats
  alias Radiator.Podcasts.Episode.Scheduling.Vote

  @fri ~U[2026-11-06 19:00:00Z]
  @sat ~U[2026-11-07 10:00:00Z]
  @sun ~U[2026-11-08 19:00:00Z]

  @people [:alice, :bob, :carol, :dave]

  defp scheduling(proposals, attrs \\ %{}),
    do: struct(%Scheduling{status: :open, proposals: proposals}, attrs)

  # `votes` maps a person to their score; persons missing are pending.
  defp proposal(id, datetime, votes) do
    %Proposal{
      id: id,
      datetime: datetime,
      votes: Enum.map(votes, fn {person, score} -> %Vote{person_id: person, score: score} end)
    }
  end

  defp stat(stats, id), do: Enum.find(stats.proposal_stats, &(&1.proposal_id == id))
  defp ids(stats), do: Enum.map(stats.proposal_stats, & &1.proposal_id)

  describe "the worked example of spec 03 §6" do
    setup do
      scheduling =
        scheduling([
          proposal(:p1, @fri, alice: 1, bob: 1, carol: 0, dave: -1),
          proposal(:p2, @sat, alice: 1, bob: 0, carol: 1, dave: 1),
          proposal(:p3, @sun, alice: -1, carol: 1)
        ])

      %{scheduling: scheduling, stats: Stats.voting_stats(scheduling, @people)}
    end

    test "counts every proposal", %{stats: stats} do
      assert %{total_score: 1, yes_count: 2, maybe_count: 1, no_count: 1, pending_count: 0} =
               stat(stats, :p1)

      assert %{total_score: 3, yes_count: 3, maybe_count: 1, no_count: 0, pending_count: 0} =
               stat(stats, :p2)

      assert %{total_score: 0, yes_count: 1, maybe_count: 0, no_count: 1, pending_count: 2} =
               stat(stats, :p3)
    end

    test "ranks and names the top proposal", %{stats: stats, scheduling: scheduling} do
      assert ids(stats) == [:p2, :p1, :p3]
      assert stats.top_proposal_id == :p2
      assert stats.top_proposal.proposal_id == :p2
      assert Stats.top_proposal_id(scheduling, @people) == :p2
    end

    test "sums up the totals", %{stats: stats} do
      assert %{
               status: :open,
               participant_count: 4,
               proposal_count: 3,
               total_votes: 10,
               voted_participant_count: 4,
               all_voted?: false
             } = stats
    end

    test "a tie on top names no top proposal but still ranks by the tie-breakers" do
      scheduling =
        scheduling([
          proposal(:p2, @sat, alice: 1, bob: 0, carol: 1, dave: 1),
          proposal(:p1, @fri, alice: 1, bob: 1, carol: 0, dave: 1)
        ])

      stats = Stats.voting_stats(scheduling, @people)

      assert stats.top_proposal_id == nil
      assert Stats.top_proposal_id(scheduling, @people) == nil
      # Same score and yeses (hence the same noes): the earlier date comes first.
      assert ids(stats) == [:p1, :p2]
    end
  end

  describe "ranking tie-breakers" do
    test "more yeses win over the same score" do
      # Both +1: two yeses and a no against one yes and two maybes.
      scheduling =
        scheduling([
          proposal(:fewer_yes, @fri, alice: 1, bob: 0, carol: 0),
          proposal(:more_yes, @sat, alice: 1, bob: 1, carol: -1)
        ])

      assert scheduling |> Stats.voting_stats(@people) |> ids() == [:more_yes, :fewer_yes]
    end
  end

  describe "pending and participants" do
    test "a proposal without votes is pending for everybody and scores zero" do
      stats = Stats.voting_stats(scheduling([proposal(:p, @fri, [])]), @people)

      assert %{total_score: 0, pending_count: 4, votes: []} = stat(stats, :p)
      assert stats.voted_participant_count == 0
    end

    test "maybe is a vote, not pending" do
      stats = Stats.voting_stats(scheduling([proposal(:p, @fri, alice: 0)]), @people)

      assert %{maybe_count: 1, pending_count: 3} = stat(stats, :p)
    end

    test "votes of persons who are no participants anymore do not count" do
      stats =
        Stats.voting_stats(scheduling([proposal(:p, @fri, alice: 1, gone: -1)]), [:alice, :bob])

      assert %{total_score: 1, no_count: 0, pending_count: 1} = stat(stats, :p)
      assert [%Vote{person_id: :alice}] = stat(stats, :p).votes
      assert stats.total_votes == 1
    end

    test "all voted only when no participant is pending anywhere" do
      everybody = [alice: 1, bob: -1]

      assert Stats.voting_stats(
               scheduling([proposal(:a, @fri, everybody), proposal(:b, @sat, everybody)]),
               [:alice, :bob]
             ).all_voted?

      refute Stats.voting_stats(
               scheduling([proposal(:a, @fri, everybody), proposal(:b, @sat, alice: 1)]),
               [:alice, :bob]
             ).all_voted?
    end

    test "without proposals or participants nobody has voted" do
      stats = Stats.voting_stats(scheduling([]), @people)

      assert %{proposal_count: 0, top_proposal: nil, top_proposal_id: nil, all_voted?: false} =
               stats

      refute Stats.voting_stats(scheduling([proposal(:p, @fri, [])]), []).all_voted?
    end
  end

  describe "winner" do
    test "is the top proposal while open" do
      assert Stats.winner_proposal_id(scheduling([], chosen_proposal_id: :chosen), :top) == :top
    end

    test "is the chosen proposal once closed, whatever the ranking says" do
      closed = scheduling([], status: :closed, chosen_proposal_id: :chosen)

      assert Stats.winner_proposal_id(closed, :top) == :chosen
    end

    test "is nobody when closed without a choice or without a scheduling" do
      assert Stats.winner_proposal_id(scheduling([], status: :closed), :top) == nil
      assert Stats.winner_proposal_id(nil, :top) == nil
    end
  end
end
