defmodule Radiator.Accounts do
  @moduledoc false

  use Ash.Domain, otp_app: :radiator, extensions: [AshAdmin.Domain]

  alias Radiator.Accounts.User.Senders.SendVotingInvitation

  admin do
    show? true
  end

  resources do
    resource Radiator.Accounts.Token
    resource Radiator.Accounts.User
  end

  @doc """
  Sends a magic-link "you can vote now" invitation to `user` that signs them in
  and deep-links to the voting page of `episode`.
  """
  def send_voting_invitation(user, episode) do
    SendVotingInvitation.send(user, episode)
  end
end
