defmodule Radiator.Podcasts.Episode.Scheduling.Validations.EpisodeInScheduling do
  @moduledoc """
  A recording date is only searched for an episode in the `:scheduling`
  state; a scheduled or published episode has one already.
  """

  use Ash.Resource.Validation

  alias Radiator.Podcasts.Episode

  @impl true
  def validate(changeset, _opts, _context) do
    episode_id = Ash.Changeset.get_attribute(changeset, :episode_id)

    case episode_id && Ash.get(Episode, episode_id, authorize?: false) do
      {:ok, %Episode{state: :scheduling}} -> :ok
      {:ok, %Episode{}} -> {:error, field: :episode_id, message: "is not looking for a date"}
      _missing -> {:error, field: :episode_id, message: "not found"}
    end
  end
end
