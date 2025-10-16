defmodule Radiator.Accounts do
  @moduledoc false

  use Ash.Domain,
    otp_app: :radiator

  resources do
    resource Radiator.Accounts.Token
    resource Radiator.Accounts.User
  end
end
