defmodule Radiator.Podcasts.PodcastUserRoleTest do
  use Radiator.DataCase, async: true

  import Swoosh.TestAssertions

  alias AshAuthentication.Strategy.MagicLink
  alias Radiator.Accounts.User
  alias Radiator.Podcasts
  alias Radiator.Podcasts.Podcast
  alias Radiator.Podcasts.PodcastUserRole.Validations.OwnRoleUnchanged

  setup do
    owner = generate(user())
    podcast = Podcasts.create_podcast!(%{title: "Shared"}, actor: owner)

    %{owner: owner, podcast: podcast}
  end

  defp memberships(podcast, actor) do
    podcast
    |> Ash.load!([memberships: [:user]], actor: actor)
    |> Map.fetch!(:memberships)
  end

  defp keep(podcast, actor) do
    podcast
    |> memberships(actor)
    |> Enum.map(&%{"id" => &1.id, "role" => to_string(&1.role)})
  end

  test "the creator becomes the owner", %{owner: owner, podcast: podcast} do
    assert [%{user_id: user_id, role: :owner}] = memberships(podcast, owner)
    assert user_id == owner.id
  end

  test "an import makes the actor owner as well", %{owner: owner} do
    podcast = Podcasts.import_podcast!(%{feed_url: "https://example.com/feed"}, actor: owner)
    assert [%{role: :owner}] = memberships(podcast, owner)
  end

  test "adding an existing user grants access and sends a magic link", %{
    owner: owner,
    podcast: podcast
  } do
    other = generate(user())
    email = to_string(other.email)

    Podcasts.update_podcast!(
      podcast,
      %{memberships: keep(podcast, owner) ++ [%{"email" => email, "role" => "owner"}]},
      actor: owner
    )

    assert_email_sent(to: [{"", email}])
    assert Ash.get!(Podcast, podcast.id, actor: other).id == podcast.id
    assert Podcasts.update_podcast!(podcast, %{title: "Ours"}, actor: other).title == "Ours"
  end

  test "adding an unknown email creates the user and sends a magic link", %{
    owner: owner,
    podcast: podcast
  } do
    Podcasts.update_podcast!(
      podcast,
      %{memberships: keep(podcast, owner) ++ [%{"email" => "new@example.com"}]},
      actor: owner
    )

    assert_email_sent(to: [{"", "new@example.com"}], subject: "Your login link")

    user =
      User
      |> Ash.Query.for_read(:get_by_email, %{email: "new@example.com"})
      |> Ash.read_one!(authorize?: false)

    assert Enum.any?(memberships(podcast, owner), &(&1.user_id == user.id))
  end

  test "existing members are not invited again", %{owner: owner, podcast: podcast} do
    Podcasts.update_podcast!(podcast, %{memberships: keep(podcast, owner)}, actor: owner)

    assert_no_email_sent()
  end

  test "nobody can remove themselves", %{owner: owner, podcast: podcast} do
    other = generate(user())

    podcast =
      Podcasts.update_podcast!(
        podcast,
        %{memberships: keep(podcast, owner) ++ [%{"email" => to_string(other.email)}]},
        actor: owner
      )

    without_owner =
      podcast
      |> keep(owner)
      |> Enum.reject(fn %{"id" => id} ->
        Enum.find(memberships(podcast, owner), &(&1.id == id)).user_id == owner.id
      end)

    assert {:error, %Ash.Error.Forbidden{}} =
             Podcasts.update_podcast(podcast, %{memberships: without_owner}, actor: owner)

    assert length(memberships(podcast, owner)) == 2
  end

  test "another member can be removed", %{owner: owner, podcast: podcast} do
    other = generate(user())
    own = keep(podcast, owner)

    podcast =
      Podcasts.update_podcast!(
        podcast,
        %{memberships: own ++ [%{"email" => to_string(other.email)}]},
        actor: owner
      )

    Podcasts.update_podcast!(podcast, %{memberships: own}, actor: owner)

    assert [%{user_id: user_id}] = memberships(podcast, owner)
    assert user_id == owner.id
    assert {:error, _error} = Ash.get(Podcast, podcast.id, actor: other)
  end

  test "an update without memberships leaves them alone", %{owner: owner, podcast: podcast} do
    Podcasts.update_podcast!(podcast, %{title: "Renamed"}, actor: owner)

    assert [_membership] = memberships(podcast, owner)
  end

  test "an invited user can sign in with the magic link", %{owner: owner, podcast: podcast} do
    Podcasts.update_podcast!(
      podcast,
      %{memberships: keep(podcast, owner) ++ [%{"email" => "invited@example.com"}]},
      actor: owner
    )

    user =
      User
      |> Ash.Query.for_read(:get_by_email, %{email: "invited@example.com"})
      |> Ash.read_one!(authorize?: false)

    strategy = AshAuthentication.Info.strategy!(User, :magic_link)
    {:ok, token} = MagicLink.request_token_for(strategy, user)

    assert {:ok, signed_in} =
             User
             |> Ash.Changeset.for_create(:sign_in_with_magic_link, %{token: token},
               context: %{private: %{ash_authentication?: true}}
             )
             |> Ash.create()

    assert signed_in.id == user.id
  end

  # `:owner` is the only role so far, so a real change cannot be submitted yet.
  test "nobody may change the role of their own membership", %{owner: owner, podcast: podcast} do
    [own] = memberships(podcast, owner)
    other = generate(user())

    # Set directly, a role the enum does not know would not survive casting.
    changed = %{Ash.Changeset.new(own) | attributes: %{role: :editor}}

    assert {:error, [field: :role, message: _message]} =
             OwnRoleUnchanged.validate(changed, [], %{actor: owner})

    assert :ok = OwnRoleUnchanged.validate(changed, [], %{actor: other})
    assert :ok = OwnRoleUnchanged.validate(Ash.Changeset.new(own), [], %{actor: owner})
  end

  describe "creating a podcast with members" do
    test "adds them next to the creator and invites only them", %{owner: owner} do
      podcast =
        Podcasts.create_podcast!(
          %{
            title: "Together",
            memberships: [%{"email" => "cohost@example.com", "role" => "owner"}]
          },
          actor: owner
        )

      emails = podcast |> memberships(owner) |> Enum.map(&to_string(&1.user.email)) |> Enum.sort()
      assert emails == Enum.sort(["cohost@example.com", to_string(owner.email)])

      assert_email_sent(to: [{"", "cohost@example.com"}])
      assert_no_email_sent()
    end

    test "a creator listing their own address is still a single owner", %{owner: owner} do
      podcast =
        Podcasts.create_podcast!(
          %{title: "Me", memberships: [%{"email" => to_string(owner.email)}]},
          actor: owner
        )

      assert [%{role: :owner, user_id: user_id}] = memberships(podcast, owner)
      assert user_id == owner.id
      assert_no_email_sent()
    end

    test "the same address twice is refused", %{owner: owner} do
      assert {:error, error} =
               Podcasts.create_podcast(
                 %{
                   title: "Twice",
                   memberships: [%{"email" => "dup@example.com"}, %{"email" => "dup@example.com"}]
                 },
                 actor: owner
               )

      assert Exception.message(error) =~ "is already a member"
    end
  end
end
