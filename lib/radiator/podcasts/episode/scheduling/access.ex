defmodule Radiator.Podcasts.Episode.Scheduling.Access do
  @moduledoc """
  The roles a user can have towards an episode's scheduling (ADR 0001 §1,
  ADR 0002): *Member* of the podcast, *Participant* of the episode, who
  votes, and *Organizer* of the scheduling, who decides. Used by the
  validations and the page, which need the same answer without going
  through authorization.
  """

  require Ash.Query

  alias Radiator.Podcasts.Episode.Scheduling.Participant
  alias Radiator.Podcasts.PodcastUserRole

  @doc "Whether `user` is a Member of the podcast `podcast_id`."
  def member?(podcast_id, %{id: user_id}) do
    PodcastUserRole
    |> Ash.Query.filter(podcast_id == ^podcast_id and user_id == ^user_id)
    |> Ash.exists?(authorize?: false)
  end

  def member?(_podcast_id, _user), do: false

  @doc "Whether `user` is a Participant of the episode `episode_id`: a contributor with their own account."
  def participant?(episode_id, user),
    do: match?({:ok, _}, Participant.person_id(episode_id, user))

  @doc """
  Whether `user` is the scheduling's Organizer and still a Member of the
  podcast `podcast_id`; only then may they decide.
  """
  def organizer?(%{organizer_id: id}, podcast_id, %{id: id} = user) when is_binary(id),
    do: member?(podcast_id, user)

  def organizer?(_scheduling, _podcast_id, _user), do: false

  @doc "Whether the scheduling's Organizer is gone: account deleted or no longer a Member."
  def organizer_gone?(%{organizer_id: nil}, _podcast_id), do: true
  def organizer_gone?(%{organizer_id: id}, podcast_id), do: not member?(podcast_id, %{id: id})
end
