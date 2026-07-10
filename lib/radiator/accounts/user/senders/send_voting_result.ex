defmodule Radiator.Accounts.User.Senders.SendVotingResult do
  @moduledoc """
  Sends a magic-link email announcing the finalized (winning) datetime of an
  episode's scheduling.

  Like `SendVotingInvitation`, the link signs the recipient in via magic link
  and, on success, redirects to the episode's page (via the `return_to` query
  parameter), so it works for passwordless, not-yet-onboarded participants too.
  """

  use RadiatorWeb, :verified_routes

  import Swoosh.Email

  alias AshAuthentication.Strategy.MagicLink
  alias Radiator.Accounts.User
  alias Radiator.Mailer

  # German weekday short labels keyed by `Date.day_of_week/1` (1 = Monday).
  @weekday_labels %{1 => "Mo", 2 => "Di", 3 => "Mi", 4 => "Do", 5 => "Fr", 6 => "Sa", 7 => "So"}

  @doc """
  Build and deliver the "winner is decided" email for `user` and `episode`.

  `episode` must be loaded with its `:scheduling`; the winning datetime is read
  from `episode.scheduling.chosen_datetime`.
  """
  def send(user, episode) do
    {:ok, token} = magic_link_token(user)
    return_to = ~p"/admin/podcasts/#{episode.podcast_id}/episodes/#{episode.id}"
    sign_in_url = url(~p"/auth/user/magic_link?#{[token: token, return_to: return_to]}")
    chosen = format_datetime(episode.scheduling.chosen_datetime)
    title = episode.title |> Phoenix.HTML.html_escape() |> Phoenix.HTML.safe_to_string()

    new()
    |> to(to_string(user.email))
    |> from({"Radiator: No Reply", "noreply@radiator.metaebene.net"})
    |> subject("Der Termin steht fest")
    |> html_body("""
      <p>Der Termin für die Episode „#{title}“ steht fest:</p>
      <p><strong>#{chosen}</strong></p>
      <p><a href="#{sign_in_url}">Zur Episode</a></p>
    """)
    |> Mailer.deliver()
  end

  defp magic_link_token(user) do
    User
    |> AshAuthentication.Info.strategy!(:magic_link)
    |> MagicLink.request_token_for(user)
  end

  defp format_datetime(%DateTime{} = datetime) do
    weekday = Map.fetch!(@weekday_labels, Date.day_of_week(datetime))
    "#{weekday} #{Calendar.strftime(datetime, "%d.%m.%Y, %H:%M")}"
  end
end
