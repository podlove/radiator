defmodule Radiator.Podcasts.Podcast.Changes.InviteNewMembers do
  @moduledoc """
  Sends an invitation with a magic link to every user who became a member of
  the podcast in this create or update, whether they had an account already
  or not. The actor added themselves or is already in, so they get none.

  The mails go out after the transaction, so a rolled back update never
  invites anybody.
  """

  use Ash.Resource.Change

  require Ash.Query

  alias Radiator.Accounts.User
  alias Radiator.Podcasts.Podcast.Senders.SendInvitationEmail
  alias Radiator.Podcasts.PodcastUserRole

  @impl true
  def change(changeset, _opts, context) do
    if Ash.Changeset.get_argument(changeset, :memberships) do
      changeset
      |> Ash.Changeset.before_action(fn changeset ->
        Ash.Changeset.put_context(
          changeset,
          :member_ids_before,
          members_before(changeset, context)
        )
      end)
      |> Ash.Changeset.after_transaction(&invite(&1, &2, context.actor))
    else
      changeset
    end
  end

  defp invite(changeset, {:ok, podcast}, inviter) do
    before = changeset.context[:member_ids_before] || []

    podcast.id
    |> member_ids()
    |> Kernel.--(before)
    |> invite_users(podcast, inviter)

    {:ok, podcast}
  end

  defp invite(_changeset, result, _inviter), do: result

  defp members_before(changeset, context) do
    actor_ids = List.wrap(context.actor && context.actor.id)

    case changeset.action_type do
      :create -> actor_ids
      _update -> actor_ids ++ member_ids(changeset.data.id)
    end
  end

  defp invite_users([], _podcast, _inviter), do: :ok

  defp invite_users(user_ids, podcast, inviter) do
    User
    |> Ash.Query.filter(id in ^user_ids)
    |> Ash.read!(authorize?: false)
    |> Enum.each(&SendInvitationEmail.deliver(&1, podcast, inviter))
  end

  defp member_ids(podcast_id) do
    PodcastUserRole
    |> Ash.Query.filter(podcast_id == ^podcast_id)
    |> Ash.Query.select([:user_id])
    |> Ash.read!(authorize?: false)
    |> Enum.map(& &1.user_id)
  end
end
