defmodule RadiatorWeb.GraphQL.Admin.Resolvers.Session do
  def prolong_authenticated_session(_parent, _params, %{context: %{authenticated_user: user}}) do
    RadiatorWeb.GraphQL.Public.Resolvers.Session.new_session_for_valid_user(user)
  end
end
