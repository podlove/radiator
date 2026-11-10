defmodule Radiator.Podcasts.Episode.Scheduling.Validations.OrganizerOrProposalCreator do
  @moduledoc """
  A proposal may be removed by whoever proposed it and by the scheduling's
  Organizer (ADR 0002).

  Runs after `ProposalExists`; the membership lookup is the only database hit
  and only happens for somebody else's proposal.
  """

  use Ash.Resource.Validation

  alias Radiator.Podcasts.Episode
  alias Radiator.Podcasts.Episode.Scheduling.Access

  @message "only its creator or the organizer can remove a proposal"

  @impl true
  def validate(changeset, _opts, %{actor: %{id: actor_id} = actor}) do
    proposal_id = Ash.Changeset.get_argument(changeset, :proposal_id)
    proposals = Ash.Changeset.get_attribute(changeset, :proposals) || []

    case Enum.find(proposals, &(&1.id == proposal_id)) do
      %{created_by_user_id: ^actor_id} -> :ok
      _other -> organizer(changeset.data, actor)
    end
  end

  def validate(_changeset, _opts, _context), do: {:error, message: @message}

  defp organizer(scheduling, actor) do
    with {:ok, episode} <- Ash.get(Episode, scheduling.episode_id, authorize?: false),
         true <- Access.organizer?(scheduling, episode.podcast_id, actor) do
      :ok
    else
      _ -> {:error, message: @message}
    end
  end
end
