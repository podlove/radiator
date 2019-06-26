alias Radiator.Auth
alias RadiatorWeb.GraphQL.Helpers.UserHelpers

defmodule RadiatorWeb.GraphQL.Public.Resolvers.User do
  def user_signup(
        _parent,
        %{username: username, email: email, password: password},
        %{context: context}
      ) do
    case Auth.Register.create_user(%{
           name: username,
           email: email,
           password: password
         }) do
      {:ok, user} ->
        with current_user = %Auth.User{} <- context[:current_user],
             :active <- current_user.status do
          # activate user immediatly when created by an already authenticated user
          Auth.Register.activate_user(user)
        else
          _ ->
            UserHelpers.resend_verification_email_for_user(user, context)
        end

        UserHelpers.new_session_for_valid_user(user)

      {:error, _changeset} ->
        {:error, "Failed to create #{username} <#{email}>"}
    end
  end
end
