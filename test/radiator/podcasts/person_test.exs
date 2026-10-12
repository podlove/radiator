defmodule Radiator.Podcasts.PersonTest do
  use Radiator.DataCase, async: true

  alias Radiator.Podcasts
  alias Radiator.Podcasts.EpisodeContributor
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

  describe "account" do
    test "a person can be linked to an account", %{user: user} do
      account = generate(user())

      assert %{account_id: account_id} = create!(user, %{name: "Bob", account_id: account.id})
      assert account_id == account.id
    end

    test "an account is linked to at most one person per owner", %{user: user} do
      account = generate(user())
      create!(user, %{name: "Bob", account_id: account.id})

      assert {:error, %Ash.Error.Invalid{}} =
               create(user, %{name: "Robert", account_id: account.id})
    end

    test "a feed upsert keeps the linked account", %{user: user} do
      account = generate(user())
      create!(user, %{name: "Bob", account_id: account.id})

      [person] =
        [%{name: "Bob", uri: "https://bob.example", user_id: user.id}]
        |> Ash.bulk_create!(Person, :upsert_from_feed, return_records?: true, authorize?: false)
        |> Map.fetch!(:records)

      assert Ash.get!(Person, person.id).account_id == account.id
    end
  end

  describe "contributed_to_podcast" do
    test "lists each contributor of the podcast once, sorted by name", %{user: user} do
      podcast = Podcasts.create_podcast!(%{title: "Show"}, actor: user)
      other = Podcasts.create_podcast!(%{title: "Other"}, actor: user)
      first = Podcasts.create_episode!(%{podcast_id: podcast.id, title: "One"})
      second = Podcasts.create_episode!(%{podcast_id: podcast.id, title: "Two"})
      elsewhere = Podcasts.create_episode!(%{podcast_id: other.id, title: "Else"})

      zoe = create!(user, %{name: "Zoe"})
      anna = create!(user, %{name: "Anna"})
      stranger = create!(user, %{name: "Stranger"})
      create!(user, %{name: "Nobody"})

      for {episode, person} <- [{first, zoe}, {second, zoe}, {first, anna}, {elsewhere, stranger}] do
        Ash.create!(EpisodeContributor, %{episode_id: episode.id, person_id: person.id})
      end

      assert ["Anna", "Zoe"] =
               podcast.id |> Podcasts.read_podcast_contributors!() |> Enum.map(& &1.name)
    end
  end
end
