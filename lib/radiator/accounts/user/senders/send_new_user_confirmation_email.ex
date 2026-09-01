defmodule Radiator.Accounts.User.Senders.SendNewUserConfirmationEmail do
  @moduledoc """
  Sends an email for a new user to confirm their email address.
  """

  use AshAuthentication.Sender
  use RadiatorWeb, :verified_routes

  import Swoosh.Email

  alias Radiator.Mailer

  @impl true
  def send(user, token, opts) do
    new()
    |> from({"Radiator: No Reply", "noreply@radiator.metaebene.net"})
    |> to(to_string(user.email))
    |> subject(subject(opts))
    |> html_body(body(token, opts))
    |> Mailer.deliver!()
  end

  # `opts[:confirmation_type]` is `:identity_link` when an OAuth2/OIDC
  # sign-in whose email matches this already-registered account is asking
  # to be linked (the strategy's `on_untrusted_email_match :confirm`).
  # Confirming grants that provider login access to this account, so make
  # the copy unambiguous about who is asking and what it does.
  defp subject(opts) do
    case opts[:confirmation_type] do
      :identity_link -> "Confirm linking your #{opts[:provider]} login"
      _ -> "Confirm your email address"
    end
  end

  defp body(token, opts) do
    url = url(~p"/confirm_new_user/#{token}")

    case opts[:confirmation_type] do
      :identity_link ->
        """
        <p>Someone signed in with #{opts[:provider]} using your email address
        and wants to link it to your account.</p>
        <p>If this was you, confirm here: <a href="#{url}">#{url}</a></p>
        <p>If it wasn't you, ignore this email - nothing has changed.</p>
        """

      _ ->
        """
        <p>Click this link to confirm your email:</p>
        <p><a href="#{url}">#{url}</a></p>
        """
    end
  end
end
