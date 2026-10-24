defmodule Radiator.Podcasts.Episode.Scheduling.Checks.EpisodeContributor do
  @moduledoc """
  The actor is a contributor of the scheduled episode: one of its contributor
  persons is tied to the actor's account.
  """

  use Ash.Policy.FilterCheck

  @impl true
  def describe(_opts), do: "actor is a contributor of the episode"

  @impl true
  def filter(_actor, _authorizer, _opts),
    do: expr(exists(episode.contributors, person.account_id == ^actor(:id)))
end
