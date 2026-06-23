alias Radiator.Accounts.User

create_user = fn email, attrs ->
  user =
    User
    |> Ash.Changeset.for_create(
      :register_with_password,
      %{email: email, password: "supersupersecret", password_confirmation: "supersupersecret"},
      authorize?: false
    )
    |> Ash.create!()

  if map_size(attrs) > 0 do
    user
    |> Ash.Changeset.for_update(:update_profile, attrs, authorize?: false)
    |> Ash.update!()
  else
    user
  end
end

{:ok, bob_person} =
  Radiator.People.create_person(%{
    first_name: "Bob",
    last_name: "the Builder",
    display_name: "Bob the Builder",
    homepage_url: "https://bob.example.com",
    bio: "Can we fix it?"
  })

bob = create_user.("bob@radiator.de", %{handle: "bob", person_id: bob_person.id})

_jim = create_user.("jim@radiator.de", %{handle: "jim"})

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

{:ok, owner_person} =
  Radiator.People.create_person(%{
    first_name: "John",
    last_name: "Doe",
    display_name: "mr podcast",
    homepage_url: "https://podcast.com",
    bio: "A person that loves podcasts"
  })

owner =
  create_user.("mr_podcast@radiator.de", %{handle: "mr_podcast", person_id: owner_person.id})

participants =
  Enum.map(1..5, fn i ->
    {:ok, person} =
      Radiator.People.create_person(%{
        first_name: "Test",
        last_name: "Person #{i}",
        display_name: "Test Person #{i}"
      })

    create_user.("test#{i}@radiator.de", %{handle: "test_handle_#{i}", person_id: person.id})
  end)

participant_ids = Enum.map(participants, & &1.id)

{:ok, scheduling} =
  Radiator.Podcasts.Episode.Scheduling
  |> Ash.Changeset.for_create(:create, %{
    episode_id: future_episode.id,
    owner_user_id: owner.id,
    participant_user_ids: [bob.id | participant_ids],
    proposed_datetimes: [
      ~U[2024-03-15 14:00:00Z],
      ~U[2024-03-16 10:00:00Z],
      ~U[2024-03-17 15:00:00Z]
    ]
  })
  |> Ash.create()

[proposal1, proposal2, _proposal3] = scheduling.proposals

cast_vote = fn scheduling, proposal_id, index, score, extra ->
  actor = Enum.at(participants, index)
  args = Map.merge(%{proposal_id: proposal_id, user_id: actor.id, score: score}, extra)

  scheduling
  |> Ash.Changeset.for_update(:vote, args, actor: actor)
  |> Ash.update!()
end

scheduling = cast_vote.(scheduling, proposal1.id, 0, 1, %{comment: "Perfect time for me!"})
scheduling = cast_vote.(scheduling, proposal1.id, 1, 1, %{})
scheduling = cast_vote.(scheduling, proposal2.id, 2, 1, %{})
_scheduling = cast_vote.(scheduling, proposal2.id, 3, -1, %{})
