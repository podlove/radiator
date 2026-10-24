defmodule Radiator.Podcasts.Episode.Scheduling.Voter do
  @moduledoc """
  Who votes for the signed-in user.

  The voters of an episode are its contributors whose person is tied to an
  account. A user votes as the contributor person tied to their own account;
  actions therefore never take a person id, so nobody can vote as somebody
  else.
  """

  require Ash.Query

  alias Radiator.Podcasts.Person

  @doc "The id of the person `actor` votes as on this episode."
  def person_id(episode_id, %{id: actor_id}) do
    Person
    |> Ash.Query.for_read(:scheduling_participants, %{episode_id: episode_id})
    |> Ash.Query.filter(account_id == ^actor_id)
    |> Ash.Query.limit(1)
    |> Ash.read_one(authorize?: false)
    |> case do
      {:ok, %Person{id: id}} -> {:ok, id}
      _none -> :error
    end
  end

  def person_id(_episode_id, _actor), do: :error
end
