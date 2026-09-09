defmodule Radiator.Podcasts.PersonTest do
  use Radiator.DataCase, async: true

  alias Radiator.Podcasts

  setup do
    user = generate(user())
    podcast = Podcasts.create_podcast!(%{title: "Test Show"}, actor: user)
    episode = Podcasts.create_episode!(%{podcast_id: podcast.id, guid: "item-1", title: "Erste"})

    %{user: user, podcast: podcast, episode: episode}
  end

  test "creates a person under the owner", %{user: user} do
    person =
      Podcasts.create_person!(%{
        user_id: user.id,
        name: "Alice Example",
        uri: "https://alice.example",
        image_url: "https://example.com/alice.jpg"
      })

    assert person.user_id == user.id
    assert person.normalized_name == "alice example"
  end

  test "derives the normalized name and refuses to take one from the caller", %{user: user} do
    assert Podcasts.create_person!(%{user_id: user.id, name: "  Alice EXAMPLE "}).normalized_name ==
             "alice example"

    assert {:error, %Ash.Error.Invalid{}} =
             Podcasts.create_person(%{
               user_id: user.id,
               name: "Bob",
               normalized_name: "somebody else"
             })
  end

  test "keeps the normalized name in step when the name is updated", %{user: user} do
    person = Podcasts.create_person!(%{user_id: user.id, name: "Alice"})

    assert Ash.update!(person, %{name: "Alice Example"}).normalized_name == "alice example"
  end

  test "rejects the same normalized name twice per owner", %{user: user} do
    Podcasts.create_person!(%{user_id: user.id, name: "Alice Example"})

    assert {:error, %Ash.Error.Invalid{}} =
             Podcasts.create_person(%{user_id: user.id, name: " ALICE EXAMPLE "})
  end

  test "allows the same name under different owners", %{user: user} do
    other = generate(user())

    Podcasts.create_person!(%{user_id: user.id, name: "Alice"})

    assert %{name: "Alice"} = Podcasts.create_person!(%{user_id: other.id, name: "Alice"})
  end

  test "links a person to an episode with a role", %{user: user, episode: episode} do
    person = Podcasts.create_person!(%{user_id: user.id, name: "Alice"})

    link =
      Podcasts.create_episode_contributor!(%{
        episode_id: episode.id,
        person_id: person.id,
        role: "host"
      })

    assert link.role == "host"
  end

  test "the generators produce usable records", %{user: user} do
    podcast = generate(podcast(user_id: user.id))
    episode = generate(episode(podcast_id: podcast.id))
    person = generate(person(user_id: user.id))

    assert podcast.user_id == user.id
    assert episode.podcast_id == podcast.id
    assert person.user_id == user.id
  end
end
