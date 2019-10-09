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
end
