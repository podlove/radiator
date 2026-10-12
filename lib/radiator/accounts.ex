defmodule Radiator.Accounts do
  @moduledoc """
  Users and everything they authenticate with.
  """

  use Ash.Domain,
    otp_app: :radiator

  alias Radiator.Accounts.User

  resources do
    resource Radiator.Accounts.Token
    resource Radiator.Accounts.User
    resource Radiator.Accounts.ApiKey
    resource Radiator.Accounts.WebAuthnCredential
  end

  @doc """
  The user with this email, created unconfirmed if nobody has signed up with
  it yet. For people others add to a podcast or an episode.
  """
  def find_or_create_invited_user(email) do
    User
    |> Ash.Query.for_read(:get_by_email, %{email: email}, authorize?: false)
    |> Ash.read_one()
    |> case do
      {:ok, nil} -> Ash.create(User, %{email: email}, action: :create_invited, authorize?: false)
      other -> other
    end
  end
end
