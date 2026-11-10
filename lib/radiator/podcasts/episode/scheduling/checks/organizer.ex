defmodule Radiator.Podcasts.Episode.Scheduling.Checks.Organizer do
  @moduledoc """
  The actor is the scheduling's Organizer and still a Member of the
  episode's podcast (ADR 0002).
  """

  use Ash.Policy.FilterCheck

  @impl true
  def describe(_opts), do: "actor organizes the scheduling and is a member of the podcast"

  @impl true
  def filter(_actor, _authorizer, _opts),
    do:
      expr(
        organizer_id == ^actor(:id) and
          exists(episode.podcast.memberships, user_id == ^actor(:id))
      )
end
