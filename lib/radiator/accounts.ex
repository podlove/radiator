defmodule Radiator.Accounts do
  @moduledoc false

  use Ash.Domain, otp_app: :radiator, extensions: [AshAdmin.Domain]

  admin do
    show? true
  end

  resources do
    resource Radiator.Accounts.Token
    resource Radiator.Accounts.User
  end
end
