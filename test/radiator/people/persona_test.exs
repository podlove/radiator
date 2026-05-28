defmodule Radiator.People.PersonaTest do
  use Radiator.DataCase, async: true

  alias Radiator.Accounts.User
  alias Radiator.People
  alias Radiator.People.Persona

  describe "get_by_user/1" do
    test "returns the persona linked to a given user" do
      user = create_user("alice@radiator.de")
      persona = generate(persona(%{user_id: user.id}))

      assert {:ok, found} = Persona.get_by_user(user.id)
      assert found.id == persona.id
      assert found.user_id == user.id
    end

    test "returns NotFound error for a user without a linked persona" do
      user = create_user("nobody@radiator.de")

      assert {:error, %Ash.Error.Invalid{errors: [%Ash.Error.Query.NotFound{}]}} =
               Persona.get_by_user(user.id)
    end

    test "returns NotFound error for an unknown user id" do
      assert {:error, %Ash.Error.Invalid{errors: [%Ash.Error.Query.NotFound{}]}} =
               Persona.get_by_user(Ash.UUID.generate())
    end
  end

  describe "unique_user identity" do
    test "prevents linking two personas to the same user" do
      user = create_user("eve@radiator.de")
      _first = generate(persona(%{user_id: user.id}))

      assert {:error, %Ash.Error.Invalid{} = error} =
               Persona
               |> Ash.Changeset.for_create(:create, %{
                 public_name: "Second Persona",
                 handle: "second_persona_#{System.unique_integer([:positive])}",
                 user_id: user.id
               })
               |> Ash.create(authorize?: false)

      assert Exception.message(error) =~ "user_id"
    end

    test "allows creating multiple personas without a user_id" do
      first = generate(persona())
      second = generate(persona())

      assert first.id != second.id
      assert is_nil(first.user_id)
      assert is_nil(second.user_id)
    end
  end

  describe "create action" do
    test "accepts a user_id on create" do
      user = create_user("carol@radiator.de")

      assert {:ok, persona} =
               People.create_persona(%{
                 public_name: "Carol",
                 handle: "carol_#{System.unique_integer([:positive])}",
                 user_id: user.id
               })

      assert persona.user_id == user.id
    end

    test "still allows creating personas without a user_id (external guests)" do
      assert {:ok, persona} =
               People.create_persona(%{
                 public_name: "External Guest",
                 handle: "guest_#{System.unique_integer([:positive])}"
               })

      assert is_nil(persona.user_id)
    end
  end

  defp create_user(email) do
    {:ok, hashed_password} = AshAuthentication.BcryptProvider.hash("supersupersecret")
    Ash.Seed.seed!(User, %{email: email, hashed_password: hashed_password})
  end
end
