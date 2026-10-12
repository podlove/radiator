defmodule Radiator.Accounts.FindOrCreateInvitedUserTest do
  use Radiator.DataCase, async: true

  alias Radiator.Accounts
  alias Radiator.Accounts.User

  test "returns the existing user, whatever the case of the address" do
    user = generate(user(email: "bob@example.com"))

    assert {:ok, %User{id: id}} = Accounts.find_or_create_invited_user("Bob@Example.com")
    assert id == user.id
  end

  # Invited users are confirmed on creation: they can only get in through a
  # link sent to their address.
  test "creates a user for an unknown address" do
    assert {:ok, %User{id: id, email: email}} =
             Accounts.find_or_create_invited_user("new@example.com")

    assert to_string(email) == "new@example.com"
    assert Ash.get!(User, id, authorize?: false)
  end
end
