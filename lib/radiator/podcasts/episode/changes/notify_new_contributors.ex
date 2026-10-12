defmodule Radiator.Podcasts.Episode.Changes.NotifyNewContributors do
  @moduledoc """
  Mails every person with an account who became a contributor of the episode
  in this create or update, whether they were picked or added by email.
  Persons without an account, as the feed sync creates them, are not
  reachable and get nothing, and neither does the actor who added themselves.

  Whether an account is new cannot be read from the user afterwards (invited
  users are confirmed on creation), so the accounts behind the entered
  addresses are noted before the save: an account that was not there yet was
  created for this episode.

  The mails go out after the transaction, so a rolled back save never mails
  anybody.
  """

  use Ash.Resource.Change

  require Ash.Query

  alias Radiator.Accounts.User
  alias Radiator.Podcasts.Episode.Senders.SendContributorEmail
  alias Radiator.Podcasts.EpisodeContributor

  @impl true
  def change(changeset, _opts, context) do
    case Ash.Changeset.get_argument(changeset, :contributors) do
      nil ->
        changeset

      contributors ->
        changeset
        |> Ash.Changeset.before_action(&remember_before(&1, entered_emails(contributors)))
        |> Ash.Changeset.after_transaction(&notify(&1, &2, context.actor))
    end
  end

  defp remember_before(changeset, emails) do
    Ash.Changeset.put_context(changeset, :contributors_before, %{
      person_ids: person_ids_before(changeset),
      account_ids: account_ids(emails)
    })
  end

  defp entered_emails(contributors) do
    contributors
    |> Enum.map(&(Map.get(&1, "email") || Map.get(&1, :email)))
    |> Enum.map(&(&1 |> to_string() |> String.trim()))
    |> Enum.reject(&(&1 == ""))
  end

  defp account_ids([]), do: []

  defp account_ids(emails) do
    User
    |> Ash.Query.filter(email in ^emails)
    |> Ash.read!(authorize?: false)
    |> Enum.map(& &1.id)
  end

  defp person_ids_before(%{action_type: :create}), do: []

  defp person_ids_before(changeset) do
    episode_id = changeset.data.id

    EpisodeContributor
    |> Ash.Query.filter(episode_id == ^episode_id)
    |> Ash.Query.select([:person_id])
    |> Ash.read!(authorize?: false)
    |> Enum.map(& &1.person_id)
  end

  defp notify(changeset, {:ok, episode}, inviter) do
    before = changeset.context[:contributors_before]
    episode = Ash.load!(episode, :podcast, authorize?: false)
    episode_id = episode.id
    person_ids = before.person_ids

    EpisodeContributor
    |> Ash.Query.filter(
      episode_id == ^episode_id and not is_nil(person.account_id) and
        person_id not in ^person_ids
    )
    |> Ash.Query.load(person: :account)
    |> Ash.read!(authorize?: false)
    |> Enum.map(& &1.person.account)
    |> Enum.uniq_by(& &1.id)
    |> Enum.reject(&actor?(&1, inviter))
    |> Enum.each(fn account ->
      new_account? = account.id not in before.account_ids and entered?(account, changeset)
      SendContributorEmail.deliver(account, episode, inviter, new_account?)
    end)

    {:ok, episode}
  end

  defp notify(_changeset, result, _inviter), do: result

  defp actor?(account, %{id: id}), do: account.id == id
  defp actor?(_account, _nobody), do: false

  # Only an address typed in this save can have produced a new account.
  defp entered?(account, changeset) do
    email = account.email |> to_string() |> String.downcase()

    changeset
    |> Ash.Changeset.get_argument(:contributors)
    |> entered_emails()
    |> Enum.any?(&(String.downcase(&1) == email))
  end
end
