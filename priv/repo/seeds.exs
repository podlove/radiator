Radiator.Accounts.User
|> Ash.Changeset.for_create(:register_with_password, %{
  email: "bob@radiator.de",
  password: "supersupersecret",
  password_confirmation: "supersupersecret"
})
|> Ash.create!(authorize?: false)

Radiator.Accounts.User
|> Ash.Changeset.for_create(:register_with_password, %{
  email: "jim@radiator.de",
  password: "supersupersecret",
  password_confirmation: "supersupersecret"
})
|> Ash.create!(authorize?: false)

{:ok, _podcast} =
  Radiator.Podcasts.create_podcast(%{
    title: "Dev Cafe",
    summary: "Campfire chat between seasoned developers."
  })

{:ok, podcast} =
  Radiator.Podcasts.create_podcast(%{
    title: "Tech Weekly",
    summary: "Weekly discussion on latest topic out of the tech sphere."
  })

{:ok, _episode} =
  Radiator.Podcasts.create_episode(%{
    title: "Episode 1",
    summary: "First episode of Tech Weekly",
    podcast_id: podcast.id
  })

{:ok, _episode} =
  Radiator.Podcasts.create_episode(%{
    title: "Episode 2",
    summary: "Second episode of Tech Weekly",
    podcast_id: podcast.id
  })

{:ok, future_episode} =
  Radiator.Podcasts.create_episode(%{
    title: "Episode 3",
    summary: "Future episode of Tech Weekly",
    podcast_id: podcast.id
  })

{:ok, person} =
  Radiator.Podcasts.create_person(%{
    real_name: "John Doe",
    nickname: "JD",
    email: "john.doe@example.com",
    telephone: "+1234567890"
  })

{:ok, owner} =
  Radiator.Podcasts.create_persona(%{
    person_id: person.id,
    public_name: "mr podcast",
    handle: "mr_podcast",
    description: "A person that loves podcasts",
    avatar_png: "https://podcast.com/mr_podcast.png"
  })

participant_ids =
  Enum.reduce(1..5, [], fn _, acc ->
    {:ok, person} =
      Radiator.Podcasts.create_person(%{
        real_name: "Test Person #{System.unique_integer([:positive])}",
        nickname: "TestNick#{System.unique_integer([:positive])}",
        email: "test#{System.unique_integer([:positive])}@example.com",
        telephone: "+44123456#{System.unique_integer([:positive])}"
      })

    {:ok, persona} =
      Radiator.Podcasts.create_persona(%{
        person_id: person.id,
        public_name: "Test Persona #{System.unique_integer([:positive])}",
        handle: "test_handle_#{System.unique_integer([:positive])}",
        description: "Test description for persona",
        avatar_png: "https://example.com/avatar#{System.unique_integer([:positive])}.png"
      })

    [persona.id | acc]
  end)

{:ok, scheduling} =
  Radiator.Podcasts.Episode.Scheduling
  |> Ash.Changeset.for_create(:create, %{
    episode_id: future_episode.id,
    owner_persona_id: owner.id,
    participant_persona_ids: participant_ids,
    proposed_datetimes: [
      ~U[2024-03-15 14:00:00Z],
      ~U[2024-03-16 10:00:00Z],
      ~U[2024-03-17 15:00:00Z]
    ]
  })
  |> Ash.create()

[proposal1, proposal2, _proposal3] = scheduling.proposals

{:ok, scheduling} =
  scheduling
  |> Ash.Changeset.for_update(:vote, %{
    proposal_id: proposal1["id"],
    persona_id: Enum.at(participant_ids, 0),
    score: 5,
    comment: "Perfect time for me!"
  })
  |> Ash.update()

{:ok, _scheduling} =
  scheduling
  |> Ash.Changeset.for_update(:vote, %{
    proposal_id: proposal1["id"],
    persona_id: Enum.at(participant_ids, 1),
    score: 4
  })
  |> Ash.update()

{:ok, _scheduling} =
  scheduling
  |> Ash.Changeset.for_update(:vote, %{
    proposal_id: proposal2["id"],
    persona_id: Enum.at(participant_ids, 2),
    score: 5
  })
  |> Ash.update()
