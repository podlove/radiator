defmodule Radiator.Accounts.User.Senders.SendVotingInvitation do
  @moduledoc """
  Sends a magic-link voting invitation email.

  The link signs the recipient in via magic link and, on success, redirects to
  the voting page of the given episode (via the `return_to` query parameter,
  consumed by `RadiatorWeb.AuthController.success/4`).
  """

  use RadiatorWeb, :verified_routes

  import Swoosh.Email

  alias AshAuthentication.Strategy.MagicLink
  alias Radiator.Accounts.User
  alias Radiator.Mailer

  @doc """
  Build and deliver the invitation email for `user` and `episode`.
  """
  def send(user, episode) do
    {:ok, token} = magic_link_token(user)
    return_to = ~p"/admin/podcasts/#{episode.podcast_id}/episodes/#{episode.id}"
    sign_in_url = url(~p"/auth/user/magic_link?#{[token: token, return_to: return_to]}")

    new()
    |> to(to_string(user.email))
    |> from({"Radiator", "noreply@radiator.de"})
    |> subject("Hier kannst du abstimmen")
    |> html_body("""
      <p>Du wurdest eingeladen, über die Termine einer Episode abzustimmen.</p>
      <p><a href="#{sign_in_url}">Jetzt anmelden und abstimmen</a></p>
    """)
    |> Mailer.deliver()
  end

  defp magic_link_token(user) do
    User
    |> AshAuthentication.Info.strategy!(:magic_link)
    |> MagicLink.request_token_for(user)
  end
end
