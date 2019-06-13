defmodule RadiatorWeb.GraphQL.Admin.Resolvers.Session do
  alias RadiatorWeb.GraphQL.Helpers.UserHelpers

  def prolong_authenticated_session(_parent, _params, %{context: %{authenticated_user: user}}) do
    UserHelpers.new_session_for_valid_user(user)
  end
end
