defmodule Radiator.Podcasts.Episode.Scheduling.Stats do
  @moduledoc """
  The ranking a member decides on (spec 03). Pure functions over a
  scheduling and the ids of its participants, computed on every read.

  Only votes of current participants count: a contributor who was removed
  from the episode keeps their stored votes, but they no longer weigh in.

  The ranking orders proposals by total score, then by more yeses and the
  earlier date, so it is stable. (Fewer noes needs no rule of its own: with
  equal score and yeses, the noes are equal too, since score = yes - no.) The *top proposal* is only
  named when one proposal has the highest total score on its own; a tie
  leaves it `nil` even though the ranking still puts one first.
  """

  @doc """
  Statistics for every proposal, in ranking order, plus totals.

      %{
        status: :open,
        participant_count: 4,
        proposal_count: 3,
        total_votes: 10,
        voted_participant_count: 4,
        all_voted?: false,
        proposal_stats: [%{proposal_id: ..., total_score: 3, ...}, ...],
        top_proposal: %{proposal_id: ..., ...},
        top_proposal_id: "..."
      }
  """
  def voting_stats(scheduling, participant_ids) do
    participants = MapSet.new(participant_ids)
    proposal_stats = ranking(scheduling, participants)

    %{
      status: scheduling.status,
      participant_count: MapSet.size(participants),
      proposal_count: length(proposal_stats),
      total_votes: Enum.reduce(proposal_stats, 0, &(&2 + length(&1.votes))),
      voted_participant_count: voted_participant_count(proposal_stats),
      all_voted?: all_voted?(proposal_stats, participants),
      proposal_stats: proposal_stats,
      top_proposal: List.first(proposal_stats),
      top_proposal_id: top_of(proposal_stats)
    }
  end

  @doc "The proposal with the single highest total score, or `nil` on a tie or without proposals."
  def top_proposal_id(scheduling, participant_ids),
    do: scheduling |> ranking(MapSet.new(participant_ids)) |> top_of()

  @doc """
  The proposal to highlight: the chosen one once the scheduling is closed
  (the member's decision beats the ranking), the top proposal while open.
  """
  def winner_proposal_id(nil, _top_proposal_id), do: nil
  def winner_proposal_id(%{status: :closed, chosen_proposal_id: chosen_id}, _top), do: chosen_id
  def winner_proposal_id(_scheduling, top_proposal_id), do: top_proposal_id

  defp ranking(scheduling, participants) do
    scheduling.proposals
    |> List.wrap()
    |> Enum.map(&proposal_stat(&1, participants))
    |> Enum.sort_by(&{-&1.total_score, -&1.yes_count, unix(&1.datetime)})
  end

  defp proposal_stat(proposal, participants) do
    votes = Enum.filter(proposal.votes || [], &MapSet.member?(participants, &1.person_id))

    %{
      proposal_id: proposal.id,
      datetime: proposal.datetime,
      total_score: Enum.reduce(votes, 0, &(&2 + &1.score)),
      yes_count: Enum.count(votes, &(&1.score == 1)),
      maybe_count: Enum.count(votes, &(&1.score == 0)),
      no_count: Enum.count(votes, &(&1.score == -1)),
      pending_count: MapSet.size(participants) - length(votes),
      votes: votes
    }
  end

  defp top_of([]), do: nil

  defp top_of([first | rest]) do
    if Enum.any?(rest, &(&1.total_score == first.total_score)), do: nil, else: first.proposal_id
  end

  defp voted_participant_count(proposal_stats) do
    proposal_stats
    |> Enum.flat_map(& &1.votes)
    |> Enum.uniq_by(& &1.person_id)
    |> length()
  end

  # Nobody can have voted on nothing, or with nobody to ask.
  defp all_voted?([], _participants), do: false

  defp all_voted?(proposal_stats, participants),
    do: MapSet.size(participants) > 0 and Enum.all?(proposal_stats, &(&1.pending_count == 0))

  defp unix(%DateTime{} = datetime), do: DateTime.to_unix(datetime)
end
