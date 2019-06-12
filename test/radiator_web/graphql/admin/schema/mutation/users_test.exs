defmodule RadiatorWeb.GraphQL.Schema.Mutation.UsersTest do
  use RadiatorWeb.ConnCase, async: true

  @request_session_query """
  mutation ($username: String!, $password: String!) {
    authenticatedSession(usernameOrEmail: $username, password: $password) {
      token
      username
      expiresAt
    }
  }
  """

  @prolong_session_query """
  mutation ($username: String!) {
    prolongSession(usernameOrEmail: $username) {
      token
      username
      expiresAt
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
                 "token" => token,
                 "expiresAt" => expires_at
               }
             }
           } = json_response(conn, 200)

    {:ok, expiry_date, _} = DateTime.from_iso8601(expires_at)

    assert :lt == DateTime.compare(DateTime.utc_now(), expiry_date)
    assert {:ok, _tokenmap} = Radiator.Auth.Guardian.decode_and_verify(token)
  end

  test "prolongSession returns a refreshed session for a valid user", %{conn: conn} do
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

    conn =
      conn
      |> recycle()
      |> Plug.Conn.put_req_header("authorization", "Bearer #{token}")
      |> post("/api/graphql",
        query: @prolong_session_query,
        variables: %{
          "username" => username
        }
      )

    assert %{"data" => %{"prolongSession" => %{"token" => token2, "expiresAt" => expires_at}}} =
             json_response(conn, 200)

    {:ok, expiry_date, _} = DateTime.from_iso8601(expires_at)

    assert :lt == DateTime.compare(DateTime.utc_now(), expiry_date)

    assert {:ok, _tokenmap} = Radiator.Auth.Guardian.decode_and_verify(token2)
  end
end
