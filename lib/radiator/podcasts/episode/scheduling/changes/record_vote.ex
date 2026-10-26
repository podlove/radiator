defmodule Radiator.Podcasts.Episode.Scheduling.Changes.RecordVote do
  @moduledoc """
  Records or (with `remove?: true`) takes back the actor's vote on the
  proposal `proposal_id`.

  The vote is cast by the contributor person tied to the actor's account
  (see `Voter`); an actor who is not such a contributor gets an error.
  """

  use Ash.Resource.Change

  alias Radiator.Podcasts.Episode.Scheduling.Proposals
  alias Radiator.Podcasts.Episode.Scheduling.Voter

  @impl true
  def change(changeset, opts, context) do
    case Voter.person_id(changeset.data.episode_id, context.actor) do
      {:ok, person_id} ->
        proposals = Ash.Changeset.get_attribute(changeset, :proposals)
        proposal_id = Ash.Changeset.get_argument(changeset, :proposal_id)

        Ash.Changeset.change_attribute(
          changeset,
          :proposals,
          update(proposals, proposal_id, person_id, changeset, opts[:remove?])
        )

      :error ->
        Ash.Changeset.add_error(changeset, message: "only contributors of the episode can vote")
    end
  end

  defp update(proposals, proposal_id, person_id, _changeset, true),
    do: Proposals.delete_vote(proposals, proposal_id, person_id)

  defp update(proposals, proposal_id, person_id, changeset, _remove?) do
    Proposals.put_vote(
      proposals,
      proposal_id,
      person_id,
      Ash.Changeset.get_argument(changeset, :score),
      Ash.Changeset.get_argument(changeset, :comment)
    )
  end
end
