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

Radiator.Podcasts.Episode.Scheduling.start_scheduling_episode(future_episode.id, [
  %{
    date_time: DateTime.now!("Etc/UTC")
  }
])

# Radiator.Podcasts.Episode.Scheduling.start_scheduling_episode(future_episode.id, %{
#   date_time: DateTime.now!("Etc/UTC"),
#   votes: [
#     %{persona: 23, score: -1},
#     %{persona: 42, score: 2}
#   ]
# })
