defmodule RadiatorWeb.Schema.Mutation.UsersTest do
  use RadiatorWeb.ConnCase, async: true

  @request_session_query """
  mutation ($username: String!, $password: String!) {
    authenticatedSession(usernameOrEmail: $username, password: $password) {
      token
      username
    }
  }
  """
  test "autenticatedSession returns a session token for a valid user", %{conn: conn} do
    username = Radiator.TestEntries.user().name

    conn =
      post conn, "/api/graphql",
        query: @request_session_query,
        variables: %{
          "username" => username,
          "password" => Radiator.TestEntries.user_password()
        }

    assert %{
             "data" => %{
               "authenticatedSession" => %{
                 "username" => ^username,
                 "token" => token
               }
             }
           } = json_response(conn, 200)

    assert {:ok, _tokenmap} = Radiator.Auth.Guardian.decode_and_verify(token)
  end
end
