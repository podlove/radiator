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

# A podcast with two episodes looking for a recording date. Alice and Bob are
# Members; each organizes one Scheduling, so each sees one they decide and one
# they only vote in. Alice, Bob and Carol are Participants of both episodes;
# Dave is a guest without an account and is therefore not asked.
alias Radiator.Accounts.User
alias Radiator.Podcasts
alias Radiator.Podcasts.EpisodeContributor
alias Radiator.Podcasts.Person
alias Radiator.Podcasts.PodcastUserRole

user = fn email ->
  User
  |> Ash.Query.for_read(:get_by_email, %{email: email}, authorize?: false)
  |> Ash.read_one!()
end

alice = user.("alice@example.com")
bob = user.("bob@example.com")
carol = user.("carol@example.com")

podcast = Podcasts.create_podcast!(%{title: "Radiator Testcast"}, actor: alice)

Ash.create!(PodcastUserRole, %{podcast_id: podcast.id, user_id: bob.id, role: :owner},
  authorize?: false
)

# Persons belong to the podcast's owner and are credited on several episodes.
person = fn name, account ->
  Ash.create!(Person, %{name: name, user_id: alice.id, account_id: account && account.id},
    action: :create,
    authorize?: false
  )
end

people = %{
  alice: person.("Alice", alice),
  bob: person.("Bob", bob),
  carol: person.("Carol", carol),
  dave: person.("Dave", nil)
}

contribute = fn episode, credits ->
  Enum.each(credits, fn {who, role} ->
    Ash.create!(
      EpisodeContributor,
      %{episode_id: episode.id, person_id: people[who].id, role: role},
      authorize?: false
    )
  end)
end

# Evenings in Berlin, counted in days from today.
evening = fn days, time ->
  Date.utc_today()
  |> Date.add(days)
  |> DateTime.new!(time, "Europe/Berlin")
  |> DateTime.shift_zone!("Etc/UTC")
end

vote = fn scheduling, votes ->
  Enum.reduce(votes, scheduling, fn {proposal, voter, score}, scheduling ->
    Podcasts.vote_on_proposal!(scheduling, proposal.id, score, actor: voter)
  end)
end

chronological = fn scheduling -> Enum.sort_by(scheduling.proposals, & &1.datetime, DateTime) end

# Episode 1, organized by Alice: three evenings a week from today; Carol
# still has two answers open.
first_episode =
  Podcasts.create_episode!(%{podcast_id: podcast.id, number: 1, title: "Die erste Aufnahme"})

contribute.(first_episode, alice: "host", bob: "host", carol: "guest", dave: "guest")

scheduling =
  Podcasts.start_scheduling!(
    first_episode.id,
    [evening.(7, ~T[19:00:00]), evening.(8, ~T[19:00:00]), evening.(9, ~T[19:00:00])],
    actor: alice
  )

[first, second, third] = chronological.(scheduling)

vote.(scheduling, [
  {first, alice, 1},
  {first, bob, 1},
  {first, carol, 0},
  {second, alice, 1},
  {second, bob, 0},
  {third, carol, 1}
])

# Episode 2, organized by Bob: three evenings two weeks out, plus an
# afternoon Carol proposed. The late evening and Carol's afternoon tie
# at the top, so there is no Best proposal; Alice hasn't answered Carol's
# proposal yet.
second_episode =
  Podcasts.create_episode!(%{
    podcast_id: podcast.id,
    number: 2,
    title: "Wer hat an der Uhr gedreht?"
  })

contribute.(second_episode, bob: "host", alice: "host", carol: "guest")

scheduling =
  Podcasts.start_scheduling!(
    second_episode.id,
    [evening.(14, ~T[20:00:00]), evening.(15, ~T[20:00:00]), evening.(16, ~T[20:00:00])],
    actor: bob
  )

scheduling =
  Podcasts.add_scheduling_proposal!(scheduling, evening.(19, ~T[15:00:00]), actor: carol)

[early, middle, late, carols] = chronological.(scheduling)

vote.(scheduling, [
  {early, bob, 1},
  {early, alice, 1},
  {early, carol, -1},
  {middle, bob, 0},
  {middle, alice, -1},
  {middle, carol, 1},
  {late, bob, 1},
  {late, alice, 0},
  {late, carol, 1},
  {carols, bob, 1},
  {carols, carol, 1}
])
