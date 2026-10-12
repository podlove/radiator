defmodule Radiator.Accounts.InvitationEmail do
  @moduledoc """
  What every mail to a user someone else added shares: a magic link that signs
  them in, confirms the account if it was never confirmed, and lands on
  `return_to`.

  The link lives longer than a regular sign-in link, since an invitation may
  sit in an inbox for a while. It is single use all the same.
  """

  use RadiatorWeb, :verified_routes

  alias AshAuthentication.Jwt

  @token_lifetime {7, :days}

  def link(user, return_to) do
    strategy = AshAuthentication.Info.strategy!(user.__struct__, :magic_link)

    {:ok, token, _claims} =
      Jwt.token_for_user(
        user,
        %{"act" => to_string(strategy.sign_in_action_name), "identity" => to_string(user.email)},
        token_lifetime: @token_lifetime,
        purpose: :magic_link
      )

    url(~p"/magic_link/#{token}?#{[return_to: return_to]}")
  end

  def validity_note, do: "The link can be used once and is valid for 7 days."

  def inviter_name(%{email: email}), do: to_string(email)
  def inviter_name(_nobody), do: "Somebody"

  def escape(text),
    do: text |> to_string() |> Phoenix.HTML.html_escape() |> Phoenix.HTML.safe_to_string()
end
