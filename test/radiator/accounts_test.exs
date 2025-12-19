defmodule Radiator.AccountsTest do
  use Radiator.DataCase, async: true

  alias Radiator.Accounts.User

  describe "User" do
    test "can be registered with email and password" do
      assert {:ok, user} =
               User
               |> Ash.Changeset.for_create(:register_with_password, %{
                 email: "test@example.com",
                 password: "password123",
                 password_confirmation: "password123"
               })
               |> Ash.create(authorize?: false)

      assert to_string(user.email) == "test@example.com"
      assert user.hashed_password != nil
    end

    test "registration requires matching password confirmation" do
      assert {:error, changeset} =
               User
               |> Ash.Changeset.for_create(:register_with_password, %{
                 email: "test@example.com",
                 password: "password123",
                 password_confirmation: "different_password"
               })
               |> Ash.create(authorize?: false)

      assert changeset.errors != []
    end

    test "registration requires minimum password length" do
      assert {:error, changeset} =
               User
               |> Ash.Changeset.for_create(:register_with_password, %{
                 email: "test@example.com",
                 password: "short",
                 password_confirmation: "short"
               })
               |> Ash.create(authorize?: false)

      assert changeset.errors != []
    end

    test "can be retrieved by email" do
      {:ok, user} =
        User
        |> Ash.Changeset.for_create(:register_with_password, %{
          email: "findme@example.com",
          password: "password123",
          password_confirmation: "password123"
        })
        |> Ash.create(authorize?: false)

      assert {:ok, found_user} =
               User
               |> Ash.Query.for_read(:get_by_email, %{email: "findme@example.com"})
               |> Ash.read_one(authorize?: false)

      assert found_user.id == user.id
      assert to_string(found_user.email) == "findme@example.com"
    end

    test "can sign in with valid email and password" do
      {:ok, user} =
        User
        |> Ash.Changeset.for_create(:register_with_password, %{
          email: "signin@example.com",
          password: "password123",
          password_confirmation: "password123"
        })
        |> Ash.create(authorize?: false)

      assert {:ok, signed_in_user} =
               User
               |> Ash.Query.for_read(:sign_in_with_password, %{
                 email: "signin@example.com",
                 password: "password123"
               })
               |> Ash.read_one(authorize?: false)

      assert signed_in_user.id == user.id
      assert signed_in_user.__metadata__.token != nil
    end

    test "cannot sign in with invalid password" do
      {:ok, _user} =
        User
        |> Ash.Changeset.for_create(:register_with_password, %{
          email: "secure@example.com",
          password: "password123",
          password_confirmation: "password123"
        })
        |> Ash.create(authorize?: false)

      assert {:error, _error} =
               User
               |> Ash.Query.for_read(:sign_in_with_password, %{
                 email: "secure@example.com",
                 password: "wrong_password"
               })
               |> Ash.read_one(authorize?: false)
    end

    test "email must be unique" do
      {:ok, _user} =
        User
        |> Ash.Changeset.for_create(:register_with_password, %{
          email: "unique@example.com",
          password: "password123",
          password_confirmation: "password123"
        })
        |> Ash.create(authorize?: false)

      assert {:error, changeset} =
               User
               |> Ash.Changeset.for_create(:register_with_password, %{
                 email: "unique@example.com",
                 password: "password456",
                 password_confirmation: "password456"
               })
               |> Ash.create(authorize?: false)

      assert changeset.errors != []
    end

    test "can read all users" do
      {:ok, _user1} =
        User
        |> Ash.Changeset.for_create(:register_with_password, %{
          email: "user1@example.com",
          password: "password123",
          password_confirmation: "password123"
        })
        |> Ash.create(authorize?: false)

      {:ok, _user2} =
        User
        |> Ash.Changeset.for_create(:register_with_password, %{
          email: "user2@example.com",
          password: "password123",
          password_confirmation: "password123"
        })
        |> Ash.create(authorize?: false)

      assert {:ok, users} = Ash.read(User, authorize?: false)
      assert length(users) >= 2
    end
  end
end
