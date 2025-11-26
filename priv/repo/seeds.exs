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
