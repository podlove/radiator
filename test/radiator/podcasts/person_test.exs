defmodule Radiator.Podcasts.PersonTest do
  use Radiator.DataCase, async: true

  alias Radiator.Podcasts.Person

  setup do
    %{user: generate(user())}
  end

  defp create(user, attrs) do
    Ash.create(Person, Map.put(attrs, :user_id, user.id), action: :create)
  end

  defp create!(user, attrs) do
    Ash.create!(Person, Map.put(attrs, :user_id, user.id), action: :create)
  end

  test "derives the normalized name and refuses to take one from the caller", %{user: user} do
    assert %{normalized_name: "alice example"} = create!(user, %{name: "  Alice EXAMPLE "})

    assert {:error, %Ash.Error.Invalid{}} =
             create(user, %{name: "Bob", normalized_name: "somebody else"})
  end

  test "rejects the same normalized name twice per owner", %{user: user} do
    create!(user, %{name: "Alice Example"})

    assert {:error, %Ash.Error.Invalid{}} = create(user, %{name: " ALICE EXAMPLE "})
  end

  test "allows the same name under different owners", %{user: user} do
    create!(user, %{name: "Alice"})

    assert %{name: "Alice"} = create!(generate(user()), %{name: "Alice"})
  end
end
