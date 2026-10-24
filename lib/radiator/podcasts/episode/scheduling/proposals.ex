defmodule Radiator.Podcasts.Episode.Scheduling.Proposals do
  @moduledoc """
  Pure operations on a scheduling's list of proposals.

  The scheduling's actions read the list, hand it through these functions and
  write the result back, so the rules of the list live in one place.
  """

  alias Radiator.Podcasts.Episode.Scheduling.Proposal
  alias Radiator.Podcasts.Episode.Scheduling.Vote

  @doc "A fresh proposal without votes."
  def new(%DateTime{} = datetime, created_by_user_id) do
    %Proposal{
      id: Ash.UUID.generate(),
      datetime: DateTime.truncate(datetime, :second),
      created_by_user_id: created_by_user_id,
      votes: [],
      inserted_at: DateTime.utc_now() |> DateTime.truncate(:second)
    }
  end

  @doc "The proposal with `id`, or `nil`."
  def find(proposals, id), do: Enum.find(proposals || [], &(&1.id == id))

  def add(proposals, %Proposal{} = proposal), do: [proposal | proposals || []]

  def remove(proposals, id), do: Enum.reject(proposals || [], &(&1.id == id))

  @doc """
  Records `person_id`'s vote on the proposal `id`, replacing an earlier vote
  of theirs on it. Votes on other proposals stay untouched.
  """
  def put_vote(proposals, id, person_id, score, comment \\ nil) do
    vote = %Vote{
      person_id: person_id,
      score: score,
      comment: comment,
      voted_at: DateTime.utc_now() |> DateTime.truncate(:second)
    }

    update(proposals, id, fn votes -> [vote | without(votes, person_id)] end)
  end

  @doc "Takes back `person_id`'s vote on the proposal `id`; they are pending again."
  def delete_vote(proposals, id, person_id),
    do: update(proposals, id, &without(&1, person_id))

  defp update(proposals, id, fun) do
    Enum.map(proposals || [], fn
      %{id: ^id} = proposal -> %{proposal | votes: fun.(proposal.votes || [])}
      proposal -> proposal
    end)
  end

  defp without(votes, person_id), do: Enum.reject(votes, &(&1.person_id == person_id))
end
