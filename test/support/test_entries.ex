defmodule Radiator.TestEntries do
  alias Radiator.Auth

  import Plug.Conn

  @testusername "TestUser1"
  @testuserpassword "Pass"

  def user_password do
    @testuserpassword
  end

  def user do
    case Auth.Register.get_user_by_name(@testusername) do
      nil ->
        Auth.Register.create_user(%{
          name: @testusername,
          email: "#{@testusername}@test.local",
          password: "#{@testuserpassword}"
        })
        |> case do
          {:ok, user} ->
            Auth.Register.activate_user(user)
            user
        end

      user ->
        user
    end
  end

  def put_current_user(conn, user \\ user()) do
    conn
    |> put_req_header(
      "authorization",
      "Bearer " <> Radiator.Auth.Guardian.api_session_token(user)
    )
  end
end
