alias Radiator.Auth
alias RadiatorWeb.GraphQL.Helpers.UserHelpers

defmodule RadiatorWeb.GraphQL.Public.Resolvers.Session do
  def get_authenticated_session(
        _parent,
        %{username_or_email: username_or_email, password: password},
        _resolution
      ) do
    case Auth.Register.get_user_by_credentials(username_or_email, password) do
      nil ->
        {:error, "Invalid credentials"}

      valid_user ->
        UserHelpers.new_session_for_valid_user(valid_user)
    end
  end

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
