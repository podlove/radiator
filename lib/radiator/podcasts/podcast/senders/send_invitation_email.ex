defmodule Radiator.Podcasts.Podcast.Senders.SendInvitationEmail do
  @moduledoc """
  Tells a user they were added to a podcast, with a magic link that signs them
  in and lands on the podcast's edit page.

  The link lives longer than a regular sign-in link, since an invitation may
  sit in an inbox for a while. It is single use all the same.
  """

  use RadiatorWeb, :verified_routes

  import Swoosh.Email

  alias AshAuthentication.Jwt
  alias Radiator.Mailer

  @token_lifetime {7, :days}

  def deliver(user, podcast, inviter) do
    strategy = AshAuthentication.Info.strategy!(user.__struct__, :magic_link)

    {:ok, token, _claims} =
      Jwt.token_for_user(
        user,
        %{"act" => to_string(strategy.sign_in_action_name), "identity" => to_string(user.email)},
        token_lifetime: @token_lifetime,
        purpose: :magic_link
      )

    new()
    |> from({"Radiator: No Reply", "noreply@radiator.metaebene.net"})
    |> to(to_string(user.email))
    |> subject("You have been added to #{podcast.title}")
    |> html_body(body(token, podcast, inviter))
    |> Mailer.deliver!()
  end

  defp body(token, podcast, inviter) do
    url = url(~p"/magic_link/#{token}?#{[return_to: ~p"/admin/podcasts/#{podcast.id}/edit"]}")

    """
    <p>Hello!</p>
    <p>#{html(inviter_name(inviter))} added you to the podcast <strong>#{html(podcast.title)}</strong> on Radiator.</p>
    <p>Click this link to sign in and open the podcast:</p>
    <p><a href="#{url}">#{url}</a></p>
    <p>The link can be used once and is valid for 7 days.</p>
    """
  end

  defp inviter_name(%{email: email}), do: to_string(email)
  defp inviter_name(_nobody), do: "Somebody"

  defp html(text),
    do: text |> to_string() |> Phoenix.HTML.html_escape() |> Phoenix.HTML.safe_to_string()
end
