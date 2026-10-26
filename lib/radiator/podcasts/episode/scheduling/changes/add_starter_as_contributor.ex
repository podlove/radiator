defmodule Radiator.Podcasts.Episode.Scheduling.Changes.AddStarterAsContributor do
  @moduledoc """
  Whoever starts the search for a date takes part in it: unless they already
  contribute to the episode with their account, they are added as a
  contributor (`host`), which makes them a voter.

  Goes through the same path as inviting somebody by email
  (`EpisodeContributor` with `email`, see `ResolvePerson`), so their person
  is found or created under the podcast's owner and tied to their account.
  Runs inside the scheduling's transaction.
  """

  use Ash.Resource.Change

  alias Radiator.Podcasts.Episode.Scheduling.Voter
  alias Radiator.Podcasts.EpisodeContributor

  @role "host"

  @impl true
  def change(changeset, _opts, %{actor: %{email: _email} = actor}) do
    Ash.Changeset.after_action(changeset, fn _changeset, scheduling ->
      case Voter.person_id(scheduling.episode_id, actor) do
        {:ok, _person_id} -> {:ok, scheduling}
        :error -> add(scheduling, actor)
      end
    end)
  end

  def change(changeset, _opts, _context), do: changeset

  defp add(scheduling, actor) do
    EpisodeContributor
    |> Ash.Changeset.for_create(
      :create,
      %{episode_id: scheduling.episode_id, email: to_string(actor.email), role: @role},
      authorize?: false
    )
    |> Ash.create(authorize?: false)
    |> case do
      {:ok, _contributor} -> {:ok, scheduling}
      error -> error
    end
  end
end
