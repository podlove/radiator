defmodule Radiator.Accounts do
  use Ash.Domain,
    otp_app: :radiator

  resources do
    resource Radiator.Accounts.Token
    resource Radiator.Accounts.User
  end
end
