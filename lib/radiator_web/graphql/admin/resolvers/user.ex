defmodule RadiatorWeb.GraphQL.Admin.Resolvers.User do
  alias RadiatorWeb.GraphQL.Helpers.UserHelpers
  alias Radiator.Auth

  def resend_verification_email(_parent, _params, %{
        context: context
      }) do
    case Map.get(context, :authenticated_user) do
      %Auth.User{status: :unverified} = user ->
        case UserHelpers.resend_verification_email_for_user(user, context) do
          :sent ->
            {:ok, true}

          # Consideration: Maybe make it an error instead?
          _ ->
            {:ok, false}
        end

      _ ->
        {
          :error,
          "Authenticiation: Needs authenticated unverified user."
        }
    end
  end
end
