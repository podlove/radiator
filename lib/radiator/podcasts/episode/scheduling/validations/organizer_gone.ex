defmodule Radiator.Podcasts.Episode.Scheduling.Validations.OrganizerGone do
  @moduledoc """
  A scheduling can only be taken over while its Organizer is gone: their
  account was deleted or they are no longer a Member of the podcast
  (ADR 0002).
  """

  use Ash.Resource.Validation

  alias Radiator.Podcasts.Episode
  alias Radiator.Podcasts.Episode.Scheduling.Access

  @impl true
  def validate(changeset, _opts, _context) do
    scheduling = changeset.data

    with {:ok, episode} <- Ash.get(Episode, scheduling.episode_id, authorize?: false),
         true <- Access.organizer_gone?(scheduling, episode.podcast_id) do
      :ok
    else
      _ -> {:error, field: :organizer_id, message: "still has an organizer"}
    end
  end
end
