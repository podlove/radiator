# Script for populating the database. You can run it as:
#
#     mix run priv/repo/seeds.exs
#
# Inside the script, you can read and write to any of your
# repositories directly:
#
#     Radiator.Repo.insert!(%Radiator.SomeSchema{})
#
# We recommend using the bang functions (`insert!`, `update!`
# and so on) as they will fail if something goes wrong.

password = "9dSeBmBca9fr"
{:ok, hashed_password} = AshAuthentication.BcryptProvider.hash(password)

Ash.Seed.seed!(Radiator.Accounts.User, %{
  email: "alice@example.com",
  hashed_password: hashed_password
})

Ash.Seed.seed!(Radiator.Accounts.User, %{
  email: "bob@example.com",
  hashed_password: hashed_password
})

Ash.Seed.seed!(Radiator.Accounts.User, %{
  email: "carol@example.com",
  hashed_password: hashed_password
})

# A podcast whose next episode is looking for a recording date. Alice owns the
# podcast; she, Bob and Carol contribute and can vote, Dave is a guest
# without an account and is therefore not asked.
alias Radiator.Accounts.User
alias Radiator.Podcasts
alias Radiator.Podcasts.EpisodeContributor
alias Radiator.Podcasts.Person

user = fn email ->
  User
  |> Ash.Query.for_read(:get_by_email, %{email: email}, authorize?: false)
  |> Ash.read_one!()
end

alice = user.("alice@example.com")
bob = user.("bob@example.com")
carol = user.("carol@example.com")

podcast = Podcasts.create_podcast!(%{title: "Radiator Testcast"}, actor: alice)

episode =
  Podcasts.create_episode!(%{podcast_id: podcast.id, number: 1, title: "Die erste Aufnahme"})

contribute = fn name, account, role ->
  person =
    Ash.create!(Person, %{name: name, user_id: alice.id, account_id: account && account.id},
      action: :create,
      authorize?: false
    )

  Ash.create!(EpisodeContributor, %{episode_id: episode.id, person_id: person.id, role: role},
    authorize?: false
  )
end

contribute.("Alice", alice, "host")
contribute.("Bob", bob, "host")
contribute.("Carol", carol, "guest")
contribute.("Dave", nil, "guest")

# Three evenings, 19:00 in Berlin, starting a week from today.
evening = fn days ->
  Date.utc_today()
  |> Date.add(days)
  |> DateTime.new!(~T[19:00:00], "Europe/Berlin")
  |> DateTime.shift_zone!("Etc/UTC")
end

scheduling =
  Podcasts.start_scheduling!(episode.id, [evening.(7), evening.(8), evening.(9)], actor: alice)

[first, second, third] = Enum.sort_by(scheduling.proposals, & &1.datetime, DateTime)

[
  {first, alice, 1},
  {first, bob, 1},
  {first, carol, 0},
  {second, alice, 1},
  {second, bob, 0},
  {third, carol, 1}
]
|> Enum.reduce(scheduling, fn {proposal, voter, score}, scheduling ->
  Podcasts.vote_on_proposal!(scheduling, proposal.id, score, actor: voter)
end)
