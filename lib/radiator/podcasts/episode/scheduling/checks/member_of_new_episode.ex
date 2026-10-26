defmodule Radiator.Podcasts.Episode.Scheduling.Checks.MemberOfNewEpisode do
  @moduledoc """
  For a scheduling about to be created: the actor is a member of the podcast
  of the episode named in `episode_id`. There is no record yet to filter on.
  """

  use Ash.Policy.SimpleCheck

  alias Radiator.Podcasts.Episode
  alias Radiator.Podcasts.Episode.Scheduling.Access

  @impl true
  def describe(_opts), do: "actor is a member of the episode's podcast"

  @impl true
  def match?(actor, %{subject: %Ash.Changeset{} = changeset}, _opts) do
    episode_id = Ash.Changeset.get_attribute(changeset, :episode_id)

    case episode_id && Ash.get(Episode, episode_id, authorize?: false) do
      {:ok, episode} -> Access.member?(episode.podcast_id, actor)
      _missing -> false
    end
  end

  def match?(_actor, _context, _opts), do: false
end
