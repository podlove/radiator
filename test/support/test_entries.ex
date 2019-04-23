defmodule Radiator.TestEntries do
  alias Radiator.Auth

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
          {:ok, user} -> user
        end

      user ->
        user
    end
  end
end
