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
end
