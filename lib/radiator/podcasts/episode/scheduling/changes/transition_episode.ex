defmodule Radiator.Podcasts.Episode.Scheduling.Changes.TransitionEpisode do
  @moduledoc """
  Runs the episode's state transition `action` after the scheduling was
  written, inside the same transaction: if the episode cannot make the
  transition, the scheduling change is rolled back as well, so a closed
  scheduling always belongs to a scheduled episode and vice versa.
  """

  use Ash.Resource.Change

  alias Radiator.Podcasts.Episode

  @impl true
  def change(changeset, opts, _context) do
    Ash.Changeset.after_action(changeset, fn _changeset, scheduling ->
      with {:ok, episode} <- Ash.get(Episode, scheduling.episode_id, authorize?: false),
           {:ok, _episode} <- Ash.update(episode, %{}, action: opts[:action], authorize?: false) do
        {:ok, scheduling}
      end
    end)
  end
end
