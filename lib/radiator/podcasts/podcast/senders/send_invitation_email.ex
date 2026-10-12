defmodule Radiator.Podcasts.Podcast.Senders.SendInvitationEmail do
  @moduledoc """
  Tells a user they were added to a podcast, with a magic link that signs them
  in and lands on the podcast's edit page.
  """

  use RadiatorWeb, :verified_routes

  import Swoosh.Email

  alias Radiator.Accounts.InvitationEmail
  alias Radiator.Mailer

  def deliver(user, podcast, inviter) do
    url = InvitationEmail.link(user, ~p"/admin/podcasts/#{podcast.id}/edit")

    new()
    |> from({"Radiator: No Reply", "noreply@radiator.metaebene.net"})
    |> to(to_string(user.email))
    |> subject("You have been added to #{podcast.title}")
    |> html_body(body(url, podcast, inviter))
    |> Mailer.deliver!()
  end

  defp body(url, podcast, inviter) do
    """
    <p>Hello!</p>
    <p>#{InvitationEmail.escape(InvitationEmail.inviter_name(inviter))} added you to the podcast <strong>#{InvitationEmail.escape(podcast.title)}</strong> on Radiator.</p>
    <p>Click this link to sign in and open the podcast:</p>
    <p><a href="#{url}">#{url}</a></p>
    <p>#{InvitationEmail.validity_note()}</p>
    """
  end
end
