defmodule Radiator.Accounts.MagicLinkSignInTest do
  use Radiator.DataCase, async: true

  alias AshAuthentication.Strategy.MagicLink
  alias Radiator.Accounts.ApiKey
  alias Radiator.Accounts.User
  alias Radiator.Podcasts

  defp register(email) do
    User
    |> Ash.Changeset.for_create(
      :register_with_password,
      %{email: email, password: "secret-password", password_confirmation: "secret-password"},
      authorize?: false
    )
    |> Ash.create!()
  end

  defp sign_in(user) do
    strategy = AshAuthentication.Info.strategy!(User, :magic_link)
    {:ok, token} = MagicLink.request_token_for(strategy, user)

    User
    |> Ash.Changeset.for_create(:sign_in_with_magic_link, %{token: token},
      context: %{private: %{ash_authentication?: true}}
    )
    |> Ash.create()
  end

  defp reload(user), do: Ash.get!(User, user.id, authorize?: false)

  test "an unconfirmed user invited to a podcast can sign in and is confirmed" do
    alice = generate(user())
    podcast = Podcasts.create_podcast!(%{title: "Alice's"}, actor: alice)

    bob = register("bob@example.com")
    assert is_nil(bob.confirmed_at)

    Podcasts.update_podcast!(
      podcast,
      %{
        memberships: [
          %{"id" => hd(Ash.load!(podcast, :memberships, authorize?: false).memberships).id},
          %{"email" => "bob@example.com"}
        ]
      },
      actor: alice
    )

    assert {:ok, signed_in} = sign_in(bob)
    assert signed_in.id == bob.id
    assert reload(bob).confirmed_at
    assert Ash.get!(Podcasts.Podcast, podcast.id, actor: signed_in).id == podcast.id
  end

  test "claiming an unconfirmed account drops the password and api keys set before" do
    bob = register("bob@example.com")

    Ash.create!(ApiKey, %{user_id: bob.id, expires_at: DateTime.add(DateTime.utc_now(), 3600)},
      authorize?: false
    )

    assert {:ok, _signed_in} = sign_in(bob)

    claimed = reload(bob)
    assert is_nil(claimed.hashed_password)
    assert [] = Ash.read!(ApiKey, authorize?: false)
  end

  test "a confirmed user keeps password and api keys" do
    bob = "bob@example.com" |> register() |> Ash.Seed.update!(%{confirmed_at: DateTime.utc_now()})
    password = bob.hashed_password
    assert password

    Ash.create!(ApiKey, %{user_id: bob.id, expires_at: DateTime.add(DateTime.utc_now(), 3600)},
      authorize?: false
    )

    assert {:ok, _signed_in} = sign_in(bob)
    assert reload(bob).hashed_password == password
    assert [_key] = Ash.read!(ApiKey, authorize?: false)
  end

  test "a new address registers through the magic link" do
    strategy = AshAuthentication.Info.strategy!(User, :magic_link)
    {:ok, token} = MagicLink.request_token_for_identity(strategy, "new@example.com")

    assert {:ok, user} =
             User
             |> Ash.Changeset.for_create(:sign_in_with_magic_link, %{token: token},
               context: %{private: %{ash_authentication?: true}}
             )
             |> Ash.create()

    assert to_string(user.email) == "new@example.com"
    assert user.confirmed_at
  end
end
