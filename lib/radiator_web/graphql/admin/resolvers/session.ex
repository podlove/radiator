defmodule RadiatorWeb.GraphQL.Admin.Resolvers.Session do
  import Radiator.Auth.Register, only: [get_user_by_credentials: 2]
  import Radiator.Auth.Guardian, only: [api_session_token: 1]

  def get_authenticated_session(
        _parent,
        %{username_or_email: username_or_email, password: password},
        _resolution
      ) do
    case get_user_by_credentials(username_or_email, password) do
      nil ->
        {:error, "Invalid credentials"}

      valid_user ->
        {:ok,
         %{
           username: valid_user.name,
           token: api_session_token(valid_user)
         }}
    end
  end

  def prolong_authenticated_session(_parent, _params, %{context: %{authenticated_user: user}}) do
    {:ok,
     %{
       username: user.name,
       token: api_session_token(user)
     }}
  end
end
