defmodule Radiator.Podcasts.Episode.Scheduling.Access do
  @moduledoc """
  The two roles a user can have towards an episode's scheduling (ADR 0001
  §1): *member* of the podcast, who decides, and *contributor* of the
  episode, who votes. Used by the policies, the validations and the page,
  which all need the same answer without going through authorization.
  """

  require Ash.Query

  alias Radiator.Podcasts.Episode.Scheduling.Voter
  alias Radiator.Podcasts.PodcastUserRole

  @doc "Whether `user` is a member of the podcast `podcast_id`."
  def member?(podcast_id, %{id: user_id}) do
    PodcastUserRole
    |> Ash.Query.filter(podcast_id == ^podcast_id and user_id == ^user_id)
    |> Ash.exists?(authorize?: false)
  end

  def member?(_podcast_id, _user), do: false

  @doc "Whether `user` contributes to the episode `episode_id` with their own account."
  def contributor?(episode_id, user), do: match?({:ok, _}, Voter.person_id(episode_id, user))
end
