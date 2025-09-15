defmodule Radiator.Secrets do
  use AshAuthentication.Secret

  def secret_for(
        [:authentication, :tokens, :signing_secret],
        Radiator.Accounts.User,
        _opts,
        _context
      ) do
    Application.fetch_env(:radiator, :token_signing_secret)
  end
end
