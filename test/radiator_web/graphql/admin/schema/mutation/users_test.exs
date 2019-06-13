defmodule RadiatorWeb.GraphQL.Schema.Mutation.UsersTest do
  use RadiatorWeb.ConnCase, async: true

  import Radiator.Factory

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
  mutation {
    prolongSession {
      token
      username
      expiresAt
    }
  }
  """

  @signup_query """
  mutation ($username: String!, $password: String!, $email: String!) {
    userSignup(username: $username, email: $email, password: $password) {
      token
      username
      expiresAt
    }
  }
  """

  test "userSignup returns a session token for a the created user", %{conn: conn} do
    tu = params_for(:testuser)

    username = tu.username
    password = tu.password
    email = tu.email

    conn =
      post(conn, "/api/graphql",
        query: @signup_query,
        variables: %{
          "username" => username,
          "password" => password,
          "email" => email
        }
      )

    assert %{
             "data" => %{
               "userSignup" => %{
                 "username" => ^username,
                 "token" => token,
                 "expiresAt" => expires_at
               }
             }
           } = json_response(conn, 200)

    {:ok, expiry_date, _} = DateTime.from_iso8601(expires_at)

    user = Radiator.Auth.Register.get_user_by_credentials(username, password)
    assert user.status == :unverified

    assert :lt == DateTime.compare(DateTime.utc_now(), expiry_date)
    assert {:ok, _tokenmap} = Radiator.Auth.Guardian.decode_and_verify(token)
  end

  test "authenticated userSignup returns a session token for a the created activated user", %{
    conn: conn
  } do
    tu = params_for(:testuser)

    username = tu.username
    password = tu.password
    email = tu.email

    conn =
      admin_bearing_conn(conn)
      |> post("/api/graphql",
        query: @signup_query,
        variables: %{
          "username" => username,
          "password" => password,
          "email" => email
        }
      )

    assert %{
             "data" => %{
               "userSignup" => %{
                 "username" => ^username,
                 "token" => token,
                 "expiresAt" => expires_at
               }
             }
           } = json_response(conn, 200)

    {:ok, expiry_date, _} = DateTime.from_iso8601(expires_at)

    user = Radiator.Auth.Register.get_user_by_credentials(username, password)
    assert user.status == :active

    assert :lt == DateTime.compare(DateTime.utc_now(), expiry_date)
    assert {:ok, _tokenmap} = Radiator.Auth.Guardian.decode_and_verify(token)
  end

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
    conn =
      admin_bearing_conn(conn)
      |> post("/api/graphql",
        query: @prolong_session_query
      )

    assert %{"data" => %{"prolongSession" => %{"token" => token, "expiresAt" => expires_at}}} =
             json_response(conn, 200)

    {:ok, expiry_date, _} = DateTime.from_iso8601(expires_at)

    assert :lt == DateTime.compare(DateTime.utc_now(), expiry_date)

    assert {:ok, _tokenmap} = Radiator.Auth.Guardian.decode_and_verify(token)
  end

  @resend_verification_email_query """
  mutation { userResendVerificationEmail }
  """

  test "userResendVerificationEmail works for unverified users", %{conn: conn} do
    tu = params_for(:testuser)
    username = tu.username

    conn =
      post(conn, "/api/graphql",
        query: @signup_query,
        variables: %{
          "username" => tu.username,
          "password" => tu.password,
          "email" => tu.email
        }
      )

    assert %{
             "data" => %{
               "userSignup" => %{
                 "username" => ^username,
                 "token" => token
               }
             }
           } = json_response(conn, 200)

    recyled_bearing_conn(conn, token)
    |> post("/api/graphql",
      query: @resend_verification_email_query
    )
  end

  defp recyled_bearing_conn(conn, token) do
    conn
    |> recycle()
    |> Plug.Conn.put_req_header("authorization", "Bearer #{token}")
  end

  defp admin_bearing_conn(conn) do
    conn =
      conn
      |> post("/api/graphql",
        query: @request_session_query,
        variables: %{
          "username" => Radiator.TestEntries.user().name,
          "password" => Radiator.TestEntries.user_password()
        }
      )

    %{
      "data" => %{
        "authenticatedSession" => %{
          "token" => token
        }
      }
    } = json_response(conn, 200)

    conn
    |> recycle()
    |> Plug.Conn.put_req_header("authorization", "Bearer #{token}")
  end
end
