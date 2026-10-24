defmodule Radiator.Podcasts.Episode.Scheduling.Changes.AddProposal do
  @moduledoc "Adds the `datetime` argument as a new proposal by the actor."

  use Ash.Resource.Change

  alias Radiator.Podcasts.Episode.Scheduling.Proposals

  @impl true
  def change(changeset, _opts, context) do
    proposal =
      changeset
      |> Ash.Changeset.get_argument(:datetime)
      |> Proposals.new(context.actor && context.actor.id)

    proposals = Ash.Changeset.get_attribute(changeset, :proposals)
    Ash.Changeset.change_attribute(changeset, :proposals, Proposals.add(proposals, proposal))
  end
end
