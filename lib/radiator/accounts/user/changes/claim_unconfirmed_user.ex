defmodule Radiator.Accounts.User.Changes.ClaimUnconfirmedUser do
  @moduledoc """
  Lets a valid magic link sign in to an account that was never confirmed.

  The confirmation add-on refuses that upsert on purpose: somebody could have
  registered the address with a password without owning it, and would keep
  access once the real owner signs in. That also locks out users who were
  invited to a podcast after registering without confirming.

  Following the confirmation guide, the account is claimed instead: whoever
  holds the magic link owns the address, so the account is confirmed and
  everything an unverified registrant could have set up to get back in (the
  password, API keys, passkeys) is removed. The upsert then finds a confirmed
  user and signs in as usual.
  """

  use Ash.Resource.Change

  require Ash.Query

  alias Radiator.Accounts.ApiKey
  alias Radiator.Accounts.WebAuthnCredential

  @impl true
  def change(changeset, _opts, _context) do
    Ash.Changeset.before_action(changeset, &claim/1)
  end

  # A changeset with an invalid token is already failing; `email` comes from
  # the verified token otherwise.
  defp claim(%{valid?: false} = changeset), do: changeset

  defp claim(changeset) do
    email = Ash.Changeset.get_attribute(changeset, :email)

    changeset.resource
    |> Ash.Query.filter(email == ^email and is_nil(confirmed_at))
    |> Ash.read_one!(authorize?: false)
    |> case do
      nil -> changeset
      user -> claim_user(changeset, user)
    end
  end

  defp claim_user(changeset, user) do
    for resource <- [ApiKey, WebAuthnCredential] do
      resource
      |> Ash.Query.filter(user_id == ^user.id)
      |> Ash.bulk_destroy!(:destroy, %{}, authorize?: false, strategy: [:atomic, :stream])
    end

    user
    |> Ash.Changeset.for_update(:claim_unconfirmed, %{}, authorize?: false)
    |> Ash.update!()

    changeset
  end
end
