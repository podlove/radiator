alias Radiator.Auth

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
        new_session_for_valid_user(valid_user)
    end
  end

  def new_session_for_valid_user(user) do
    token = Auth.Guardian.api_session_token(user)

    {:ok,
     %{
       username: user.name,
       token: token,
       expires_at: Auth.Guardian.get_expiry_datetime(token)
     }}
  end
end
