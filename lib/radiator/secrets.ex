defmodule Radiator.Secrets do
  @moduledoc false

  use AshAuthentication.Secret

  def secret_for(
        [:authentication, :tokens, :signing_secret],
        Radiator.Accounts.User,
        _opts,
        _context
      ) do
    Application.fetch_env(:radiator, :token_signing_secret)
  end

  def secret_for(
        [:authentication, :strategies, :webauthn, :rp_id],
        Radiator.Accounts.User,
        _opts,
        _context
      ) do
    Application.fetch_env(:radiator, :webauthn_rp_id)
  end

  def secret_for(
        [:authentication, :strategies, :webauthn, :rp_name],
        Radiator.Accounts.User,
        _opts,
        _context
      ) do
    Application.fetch_env(:radiator, :webauthn_rp_name)
  end

  def secret_for(
        [:authentication, :strategies, :webauthn, :origin],
        Radiator.Accounts.User,
        _opts,
        _context
      ) do
    Application.fetch_env(:radiator, :webauthn_origin)
  end
end
