defmodule RadiatorWeb.GraphQL.Schema.Mutation.UsersTest do
  use RadiatorWeb.ConnCase, async: true

  @request_session_query """
  mutation ($username: String!, $password: String!) {
    authenticatedSession(usernameOrEmail: $username, password: $password) {
      token
      username
    }
  }
  """
  test "autenticatedSession returns a session token for a valid user by name", %{conn: conn} do
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

  test "autenticatedSession returns a session token for a valid user by email", %{conn: conn} do
    username = Radiator.TestEntries.user().name

    conn =
      post conn, "/api/graphql",
        query: @request_session_query,
        variables: %{
          "username" => Radiator.TestEntries.user().email,
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

  test "autenticatedSession is case insensitive for name", %{conn: conn} do
    username = Radiator.TestEntries.user().name

    conn =
      post conn, "/api/graphql",
        query: @request_session_query,
        variables: %{
          "username" => username |> String.upcase(),
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

  test "autenticatedSession is case insensitive for email", %{conn: conn} do
    username = Radiator.TestEntries.user().name

    conn =
      post conn, "/api/graphql",
        query: @request_session_query,
        variables: %{
          "username" => Radiator.TestEntries.user().email |> String.upcase(),
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
