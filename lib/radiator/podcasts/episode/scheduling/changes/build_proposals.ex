defmodule Radiator.Podcasts.Episode.Scheduling.Changes.BuildProposals do
  @moduledoc """
  Turns the `proposed_datetimes` of a new scheduling into proposals by the
  actor. A date given twice becomes one proposal.
  """

  use Ash.Resource.Change

  alias Radiator.Podcasts.Episode.Scheduling.Proposals

  @impl true
  def change(changeset, _opts, context) do
    user_id = actor_id(context)

    proposals =
      changeset
      |> Ash.Changeset.get_argument(:proposed_datetimes)
      |> List.wrap()
      |> Enum.uniq_by(&DateTime.truncate(&1, :second))
      |> Enum.map(&Proposals.new(&1, user_id))

    Ash.Changeset.change_attribute(changeset, :proposals, proposals)
  end

  defp actor_id(%{actor: %{id: id}}), do: id
  defp actor_id(_context), do: nil
end
