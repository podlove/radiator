defmodule Radiator.Podcasts.Episode.Scheduling.Checks.MemberOfNewEpisode do
  @moduledoc """
  For a scheduling about to be created: the actor is a member of the podcast
  of the episode named in `episode_id`. There is no record yet to filter on.
  """

  use Ash.Policy.SimpleCheck

  require Ash.Query

  alias Radiator.Podcasts.Episode
  alias Radiator.Podcasts.PodcastUserRole

  @impl true
  def describe(_opts), do: "actor is a member of the episode's podcast"

  @impl true
  def match?(%{id: actor_id}, %{subject: %Ash.Changeset{} = changeset}, _opts) do
    episode_id = Ash.Changeset.get_attribute(changeset, :episode_id)

    case episode_id && Ash.get(Episode, episode_id, authorize?: false) do
      {:ok, episode} -> member?(episode.podcast_id, actor_id)
      _missing -> false
    end
  end

  def match?(_actor, _context, _opts), do: false

  defp member?(podcast_id, user_id) do
    PodcastUserRole
    |> Ash.Query.filter(podcast_id == ^podcast_id and user_id == ^user_id)
    |> Ash.exists?(authorize?: false)
  end
end
