defmodule Radiator.Accounts.User.Senders.SendMagicLinkEmail do
  @moduledoc "Sends a magic link sign-in email."

  use AshAuthentication.Sender
  use RadiatorWeb, :verified_routes

  import Swoosh.Email
  alias Radiator.Mailer

  @impl true
  def send(user_or_email, token, _opts) do
    email = to_email(user_or_email)

    new()
    |> to(to_string(email))
    |> from({"Radiator", "noreply@radiator.de"})
    |> subject("Dein Login-Link")
    |> html_body("""
      <p>Hier kannst du dich anmelden:</p>
      <p><a href="#{url(~p"/auth/user/magic_link?token=#{token}")}">Anmelden</a></p>
    """)
    |> Mailer.deliver()
  end

  defp to_email(%{email: email}), do: email
  defp to_email(email), do: email
end
