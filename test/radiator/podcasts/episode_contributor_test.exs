defmodule Radiator.Podcasts.EpisodeContributorTest do
  use Radiator.DataCase, async: true

  require Ash.Query

  alias Radiator.Accounts.User
  alias Radiator.Podcasts
  alias Radiator.Podcasts.EpisodeContributor
  alias Radiator.Podcasts.Person

  setup do
    owner = generate(user())
    podcast = Podcasts.create_podcast!(%{title: "Show"}, actor: owner)
    episode = Podcasts.create_episode!(%{podcast_id: podcast.id, title: "One"})

    %{owner: owner, podcast: podcast, episode: episode}
  end

  defp add(episode, attrs) do
    Ash.create(EpisodeContributor, Map.put(attrs, :episode_id, episode.id), action: :create)
  end

  defp person!(contributor), do: Ash.get!(Person, contributor.person_id)

  test "an unknown email creates a user and a person filed under the owner", %{
    owner: owner,
    episode: episode
  } do
    assert {:ok, contributor} = add(episode, %{email: "bob@example.com", role: "guest"})

    assert [bob] =
             User |> Ash.Query.filter(email == "bob@example.com") |> Ash.read!(authorize?: false)

    assert %Person{name: "bob@example.com", user_id: user_id, account_id: account_id} =
             person!(contributor)

    assert user_id == owner.id
    assert account_id == bob.id
    assert contributor.role == "guest"
  end

  test "a known email reuses the user and their person", %{episode: episode, owner: owner} do
    bob = generate(user(email: "bob@example.com"))

    known =
      Ash.create!(Person, %{name: "Bob", user_id: owner.id, account_id: bob.id}, action: :create)

    assert {:ok, contributor} = add(episode, %{email: "Bob@Example.com"})
    assert contributor.person_id == known.id
    assert User |> Ash.read!(authorize?: false) |> length() == 2
  end

  test "a person named like the address gets the account linked", %{
    episode: episode,
    owner: owner
  } do
    named = Ash.create!(Person, %{name: "bob@example.com", user_id: owner.id}, action: :create)

    assert {:ok, contributor} = add(episode, %{email: "bob@example.com"})
    assert contributor.person_id == named.id
    refute is_nil(person!(contributor).account_id)
  end

  test "needs exactly one of person and email", %{episode: episode, owner: owner} do
    person = Ash.create!(Person, %{name: "Anna", user_id: owner.id}, action: :create)

    assert {:error, %Ash.Error.Invalid{}} = add(episode, %{})

    assert {:error, %Ash.Error.Invalid{}} =
             add(episode, %{person_id: person.id, email: "bob@example.com"})
  end

  test "rejects something that is not an email address", %{episode: episode} do
    assert {:error, %Ash.Error.Invalid{errors: errors}} = add(episode, %{email: "Anna"})
    assert Enum.any?(errors, &(Map.get(&1, :field) == :email))
  end

  test "a podcast without owner gives an error instead of crashing" do
    podcast = generate(podcast())
    episode = generate(episode(podcast_id: podcast.id))

    assert {:error, %Ash.Error.Invalid{errors: errors}} =
             add(episode, %{email: "bob@example.com"})

    assert Enum.any?(errors, &(Map.get(&1, :field) == :email))
  end
end
