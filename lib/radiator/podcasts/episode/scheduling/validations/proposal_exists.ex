defmodule Radiator.Podcasts.Episode.Scheduling.Validations.ProposalExists do
  @moduledoc """
  The proposal named by an argument (`:proposal_id` unless `argument:` says
  otherwise) must be one of the scheduling's proposals.
  """

  use Ash.Resource.Validation

  @impl true
  def init(opts) do
    {:ok,
     opts
     |> Keyword.put_new(:argument, :proposal_id)
     |> Keyword.put_new(:message, "proposal not found")}
  end

  @impl true
  def validate(changeset, opts, _context) do
    argument = opts[:argument]
    proposal_id = Ash.Changeset.get_argument(changeset, argument)
    proposals = Ash.Changeset.get_attribute(changeset, :proposals) || []

    if Enum.any?(proposals, &(&1.id == proposal_id)) do
      :ok
    else
      {:error, field: argument, message: opts[:message]}
    end
  end
end
