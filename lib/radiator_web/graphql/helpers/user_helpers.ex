defmodule RadiatorWeb.GraphQL.Helpers.UserHelpers do
  alias Radiator.Auth

  @doc """
  Construct session result type for user with newly created session.
  """
  def new_session_for_valid_user(user) do
    token = Auth.Guardian.api_session_token(user)

    {:ok,
     %{
       username: user.name,
       token: token,
       expires_at: Auth.Guardian.get_expiry_datetime(token)
     }}
  end

  @doc """
  Resend the verification email for a user
  """
  def resend_verification_email_for_user(user, resolution_context) do
    case user.status do
      :unverified ->
        user
        |> Auth.Email.email_verification_email(
          RadiatorWeb.LoginController.email_configuration_url(
            resolution_context.context_conn,
            user
          )
        )
        |> Radiator.Mailer.deliver_later()

        :sent

      _ ->
        :not_sent
    end
  end
end
