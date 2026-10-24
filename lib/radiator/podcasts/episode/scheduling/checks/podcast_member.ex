defmodule Radiator.Podcasts.Episode.Scheduling.Checks.PodcastMember do
  @moduledoc "The actor is a member of the scheduled episode's podcast."

  use Ash.Policy.FilterCheck

  @impl true
  def describe(_opts), do: "actor is a member of the episode's podcast"

  @impl true
  def filter(_actor, _authorizer, _opts),
    do: expr(exists(episode.podcast.memberships, user_id == ^actor(:id)))
end
