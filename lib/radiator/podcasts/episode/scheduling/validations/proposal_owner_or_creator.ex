defmodule Radiator.Podcasts.Episode.Scheduling.Validations.ProposalOwnerOrCreator do
  @moduledoc """
  Validates that the `user_id` argument is either the scheduling owner or the creator
  of the proposal identified by `proposal_id`. Also validates that the proposal exists.
  """
  use Ash.Resource.Validation

  @impl true
  def init(opts), do: {:ok, opts}

  @impl true
  def validate(changeset, _opts, _context) do
    user_id = Ash.Changeset.get_argument(changeset, :user_id)
    owner_id = Ash.Changeset.get_attribute(changeset, :owner_user_id)
    proposal_id = Ash.Changeset.get_argument(changeset, :proposal_id)
    proposals = Ash.Changeset.get_attribute(changeset, :proposals) || []
    proposal = Enum.find(proposals, &(&1.id == proposal_id))

    cond do
      is_nil(proposal) ->
        {:error, message: "Proposal not found"}

      user_id == owner_id ->
        :ok

      proposal.created_by_user_id == user_id ->
        :ok

      true ->
        {:error, message: "Only the owner or proposal creator can remove proposals"}
    end
  end
end
