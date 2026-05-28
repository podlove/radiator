bob =
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

{:ok, bob_person} =
  Radiator.People.create_person(%{
    real_name: "Bob the Builder",
    nickname: "bob",
    email: "bob@radiator.de",
    telephone: "+49123456789"
  })

{:ok, bob_persona} =
  Radiator.People.create_persona(%{
    person_id: bob_person.id,
    public_name: "Bob",
    handle: "bob",
    description: "Bob's public persona",
    user_id: bob.id
  })

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
  Radiator.People.create_person(%{
    real_name: "John Doe",
    nickname: "JD",
    email: "john.doe@example.com",
    telephone: "+1234567890"
  })

{:ok, owner} =
  Radiator.People.create_persona(%{
    person_id: person.id,
    public_name: "mr podcast",
    handle: "mr_podcast",
    description: "A person that loves podcasts",
    avatar_png: "https://podcast.com/mr_podcast.png"
  })

participants =
  Enum.map(1..5, fn _ ->
    {:ok, person} =
      Radiator.People.create_person(%{
        real_name: "Test Person #{System.unique_integer([:positive])}",
        nickname: "TestNick#{System.unique_integer([:positive])}",
        email: "test#{System.unique_integer([:positive])}@example.com",
        telephone: "+44123456#{System.unique_integer([:positive])}"
      })

    user =
      Radiator.Accounts.User
      |> Ash.Changeset.for_create(:register_with_password, %{
        email: "test#{System.unique_integer([:positive])}@radiator.de",
        password: "supersupersecret",
        password_confirmation: "supersupersecret"
      })
      |> Ash.create!(authorize?: false)

    {:ok, persona} =
      Radiator.People.create_persona(%{
        person_id: person.id,
        public_name: "Test Persona #{System.unique_integer([:positive])}",
        handle: "test_handle_#{System.unique_integer([:positive])}",
        description: "Test description for persona",
        avatar_png: "https://example.com/avatar#{System.unique_integer([:positive])}.png",
        user_id: user.id
      })

    %{persona: persona, user: user}
  end)

participant_ids = Enum.map(participants, & &1.persona.id)

{:ok, scheduling} =
  Radiator.Podcasts.Episode.Scheduling
  |> Ash.Changeset.for_create(:create, %{
    episode_id: future_episode.id,
    owner_persona_id: owner.id,
    participant_persona_ids: [bob_persona.id | participant_ids],
    proposed_datetimes: [
      ~U[2024-03-15 14:00:00Z],
      ~U[2024-03-16 10:00:00Z],
      ~U[2024-03-17 15:00:00Z]
    ]
  })
  |> Ash.create()

[proposal1, proposal2, _proposal3] = scheduling.proposals

cast_vote = fn scheduling, proposal_id, index, score, extra ->
  %{persona: persona, user: actor} = Enum.at(participants, index)
  args = Map.merge(%{proposal_id: proposal_id, persona_id: persona.id, score: score}, extra)

  scheduling
  |> Ash.Changeset.for_update(:vote, args, actor: actor)
  |> Ash.update!()
end

scheduling = cast_vote.(scheduling, proposal1.id, 0, 1, %{comment: "Perfect time for me!"})
scheduling = cast_vote.(scheduling, proposal1.id, 1, 1, %{})
scheduling = cast_vote.(scheduling, proposal2.id, 2, 1, %{})
_scheduling = cast_vote.(scheduling, proposal2.id, 3, -1, %{})
