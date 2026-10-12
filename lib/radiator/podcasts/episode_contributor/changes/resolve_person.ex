defmodule Radiator.Podcasts.EpisodeContributor.Changes.ResolvePerson do
  @moduledoc """
  Turns the `email` argument into a `person_id`.

  The user with that address is looked up and created if they do not exist
  yet. Their person is filed under the podcast's first owner, like every
  person the feed sync creates, and named after the address until somebody
  knows better. Without an email the caller supplies `person_id` itself.

  Runs before the insert, inside the episode's transaction: a failed save
  leaves no user behind.
  """

  use Ash.Resource.Change

  require Ash.Query

  alias Radiator.Accounts
  alias Radiator.Podcasts.Episode
  alias Radiator.Podcasts.Person
  alias Radiator.Podcasts.PodcastUserRole

  @impl true
  def change(changeset, _opts, _context) do
    case Ash.Changeset.get_argument(changeset, :email) do
      nil -> changeset
      email -> Ash.Changeset.before_action(changeset, &relate_person(&1, email))
    end
  end

  defp relate_person(changeset, email) do
    with {:ok, owner_id} <- owner_id(Ash.Changeset.get_attribute(changeset, :episode_id)),
         {:ok, user} <- Accounts.find_or_create_invited_user(email),
         {:ok, person} <- find_or_create_person(owner_id, user) do
      Ash.Changeset.force_change_attribute(changeset, :person_id, person.id)
    else
      {:error, error} ->
        Ash.Changeset.add_error(changeset, field: :email, message: error_message(error))
    end
  end

  defp owner_id(episode_id) do
    with {:ok, episode} <- Ash.get(Episode, episode_id, authorize?: false) do
      case PodcastUserRole.first_owner_id(episode.podcast_id) do
        nil -> {:error, "the podcast has no owner"}
        owner_id -> {:ok, owner_id}
      end
    end
  end

  # A person the owner already named after the address is the same person.
  defp find_or_create_person(owner_id, user) do
    name = to_string(user.email)
    normalized_name = Person.normalize(name)
    user_id = user.id

    Person
    |> Ash.Query.filter(
      user_id == ^owner_id and (account_id == ^user_id or normalized_name == ^normalized_name)
    )
    |> Ash.read(authorize?: false)
    |> case do
      {:ok, []} ->
        Ash.create(Person, %{name: name, user_id: owner_id, account_id: user_id},
          action: :create,
          authorize?: false
        )

      {:ok, persons} ->
        persons
        |> Enum.find(hd(persons), &(&1.account_id == user_id))
        |> link_account(user_id)

      error ->
        error
    end
  end

  defp link_account(%{account_id: user_id} = person, user_id), do: {:ok, person}

  defp link_account(%{account_id: nil} = person, user_id),
    do: Ash.update(person, %{account_id: user_id}, action: :link_account, authorize?: false)

  defp link_account(_person, _user_id), do: {:error, "belongs to a different person"}

  defp error_message(message) when is_binary(message), do: message
  defp error_message(%{errors: [%{message: message} | _]}) when is_binary(message), do: message
  defp error_message(_error), do: "is invalid"
end
