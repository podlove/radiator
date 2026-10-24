defmodule Radiator.Podcasts.Episode.Scheduling.Changes.ChooseProposal do
  @moduledoc """
  Closes the scheduling on the proposal `chosen_proposal_id`, keeping its
  date as `chosen_datetime`. Runs after `ProposalExists`.
  """

  use Ash.Resource.Change

  alias Radiator.Podcasts.Episode.Scheduling.Proposals

  @impl true
  def change(changeset, _opts, _context) do
    proposals = Ash.Changeset.get_attribute(changeset, :proposals)
    chosen_id = Ash.Changeset.get_argument(changeset, :chosen_proposal_id)

    case Proposals.find(proposals, chosen_id) do
      nil ->
        changeset

      proposal ->
        changeset
        |> Ash.Changeset.change_attribute(:status, :closed)
        |> Ash.Changeset.change_attribute(:chosen_proposal_id, proposal.id)
        |> Ash.Changeset.change_attribute(:chosen_datetime, proposal.datetime)
        |> Ash.Changeset.change_attribute(:finalized_at, DateTime.utc_now())
    end
  end
end
