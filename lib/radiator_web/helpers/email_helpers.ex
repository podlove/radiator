defmodule RadiatorWeb.Helpers.EmailHelpers do
  @moduledoc """
  Helper functions for sending out emails.
  """

  alias Radiator.Auth

  alias RadiatorWeb.Router.Helpers, as: Routes

  @doc """
  Resend the verification email for a user
  """
  def resend_verification_email_for_user(user) do
    case user.status do
      :unverified ->
        user
        |> Auth.Email.email_verification_email(email_verification_token_url(user))
        |> Radiator.Mailer.deliver_later()

        :sent

      _ ->
        :not_sent
    end
  end

  def singup_user(params) do
    with {:ok, user = %Auth.User{}} <- Auth.Register.create_user(params) do
      user
      |> Auth.Email.welcome_email(email_verification_token_url(user))
      |> Radiator.Mailer.deliver_later()

      {:ok, user}
    end
  end

  def email_verification_token_url(user = %Auth.User{}) do
    Routes.login_url(
      RadiatorWeb.Endpoint,
      :verify_email,
      Auth.User.email_verification_token(user)
    )
  end
end
