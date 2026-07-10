defmodule Radiator.Accounts.UserTest do
  use Radiator.DataCase, async: true
  alias Radiator.Accounts.User

  test "invite_by_email creates a passwordless user" do
    user =
      User
      |> Ash.Changeset.for_create(:invite_by_email, %{email: "guest@example.com"},
        authorize?: false
      )
      |> Ash.create!()

    assert to_string(user.email) == "guest@example.com"
    assert is_nil(user.hashed_password)
  end

  test "display_name falls back handle -> email and prefers linked person" do
    person =
      Radiator.People.create_person!(%{
        first_name: "Harald",
        last_name: "Lesch",
        display_name: "Harald Lesch"
      })

    user =
      User
      |> Ash.Changeset.for_create(:invite_by_email, %{email: "h@example.com", handle: "harry"},
        authorize?: false
      )
      |> Ash.create!()
      |> Ash.Changeset.for_update(:update_profile, %{person_id: person.id}, authorize?: false)
      |> Ash.update!()
      |> Ash.load!(:display_name, authorize?: false)

    assert user.display_name == "Harald Lesch"
  end
end
