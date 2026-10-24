defmodule Radiator.Podcasts.Episode.Scheduling.Changes.RemoveProposal do
  @moduledoc "Removes the proposal `proposal_id` together with its votes."

  use Ash.Resource.Change

  alias Radiator.Podcasts.Episode.Scheduling.Proposals

  @impl true
  def change(changeset, _opts, _context) do
    proposal_id = Ash.Changeset.get_argument(changeset, :proposal_id)
    proposals = Ash.Changeset.get_attribute(changeset, :proposals)

    Ash.Changeset.change_attribute(
      changeset,
      :proposals,
      Proposals.remove(proposals, proposal_id)
    )
  end
end
