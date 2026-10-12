defmodule Radiator.Podcasts.Episode.Senders.SendContributorEmail do
  @moduledoc """
  Tells a user they were added as a contributor to an episode, with a magic
  link that signs them in and lands on the episode's edit page.

  Somebody whose account was created for this very occasion learns that it
  exists; following the link is how they get in.
  """

  use RadiatorWeb, :verified_routes

  import Swoosh.Email

  alias Radiator.Accounts.InvitationEmail
  alias Radiator.Mailer

  def deliver(user, episode, inviter, new_account?) do
    url =
      InvitationEmail.link(
        user,
        ~p"/admin/podcasts/#{episode.podcast_id}/episodes/#{episode.id}/edit"
      )

    new()
    |> from({"Radiator: No Reply", "noreply@radiator.metaebene.net"})
    |> to(to_string(user.email))
    |> subject(subject_line(new_account?, episode))
    |> html_body(body(new_account?, episode, inviter, url))
    |> Mailer.deliver!()
  end

  defp subject_line(true, _episode), do: "An account was created for you on Radiator"
  defp subject_line(false, episode), do: "You were added to #{episode.title}"

  defp body(new_account?, episode, inviter, url) do
    """
    <p>Hello!</p>
    <p>#{InvitationEmail.escape(InvitationEmail.inviter_name(inviter))} added you as a contributor to <strong>#{InvitationEmail.escape(episode.title)}</strong> of the podcast <strong>#{InvitationEmail.escape(episode.podcast.title)}</strong> on Radiator.</p>
    <p>#{call_to_action(new_account?)}</p>
    <p><a href="#{url}">#{url}</a></p>
    <p>#{InvitationEmail.validity_note()}</p>
    """
  end

  defp call_to_action(true),
    do: "An account has been created for you. Click this link to sign in and open the episode:"

  defp call_to_action(false), do: "Click this link to sign in and open the episode:"
end
