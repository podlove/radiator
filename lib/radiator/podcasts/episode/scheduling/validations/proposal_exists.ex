defmodule Radiator.Podcasts.Episode.Scheduling.Validations.ProposalExists do
  @moduledoc """
  Validates that the `chosen_proposal_id` argument refers to an existing proposal
  in the scheduling's proposals list.
  """
  use Ash.Resource.Validation

  @impl true
  def init(opts), do: {:ok, opts}

  @impl true
  def validate(changeset, _opts, _context) do
    proposal_id = Ash.Changeset.get_argument(changeset, :chosen_proposal_id)
    proposals = Ash.Changeset.get_attribute(changeset, :proposals) || []

    if Enum.any?(proposals, &(&1.id == proposal_id)) do
      :ok
    else
      {:error, message: "Chosen proposal not found"}
    end
  end
end
