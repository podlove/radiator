defmodule Radiator.Podcasts.Episode.SchedulingTest do
  use Radiator.DataCase, async: true

  alias Radiator.Podcasts
  alias Radiator.Podcasts.Episode
  alias Radiator.Podcasts.Episode.Scheduling.Proposal
  alias Radiator.Podcasts.EpisodeContributor
  alias Radiator.Podcasts.Person

  @fri ~U[2026-11-06 19:00:00Z]
  @sat ~U[2026-11-07 10:00:00Z]
  @sun ~U[2026-11-08 19:00:00Z]

  setup do
    owner = generate(user())
    podcast = Podcasts.create_podcast!(%{title: "Show"}, actor: owner)
    episode = Podcasts.create_episode!(%{podcast_id: podcast.id, title: "One"})

    alice = generate(user())
    bob = generate(user())
    alice_person = contribute!(episode, owner, "Alice", alice)
    bob_person = contribute!(episode, owner, "Bob", bob)

    %{
      owner: owner,
      podcast: podcast,
      episode: episode,
      alice: alice,
      bob: bob,
      alice_person: alice_person,
      bob_person: bob_person
    }
  end

  defp contribute!(episode, owner, name, account) do
    person =
      Ash.create!(
        Person,
        %{name: name, user_id: owner.id, account_id: account && account.id},
        action: :create
      )

    Ash.create!(EpisodeContributor, %{episode_id: episode.id, person_id: person.id})
    person
  end

  defp start!(episode, actor, datetimes \\ [@fri, @sat, @sun]),
    do: Podcasts.start_scheduling!(episode.id, datetimes, actor: actor)

  defp proposal_at(scheduling, datetime),
    do: Enum.find(scheduling.proposals, &(&1.datetime == datetime))

  defp votes_of(scheduling, datetime),
    do:
      scheduling
      |> proposal_at(datetime)
      |> Map.fetch!(:votes)
      |> Map.new(&{&1.person_id, &1.score})

  defp reload_episode(episode), do: Ash.get!(Episode, episode.id)

  describe "start" do
    test "opens a scheduling with one proposal per date by the actor", %{
      episode: episode,
      owner: owner
    } do
      scheduling = start!(episode, owner)

      assert scheduling.status == :open
      assert scheduling.published_at
      assert scheduling.created_by_id == owner.id

      assert scheduling.proposals |> Enum.map(& &1.datetime) |> Enum.sort(DateTime) == [
               @fri,
               @sat,
               @sun
             ]

      assert Enum.all?(
               scheduling.proposals,
               &(&1.created_by_user_id == owner.id and &1.votes == [])
             )
    end

    test "a date given twice becomes one proposal", %{episode: episode, owner: owner} do
      assert [_one] = start!(episode, owner, [@fri, @fri]).proposals
    end

    test "needs at least one date", %{episode: episode, owner: owner} do
      assert {:error, _} = Podcasts.start_scheduling(episode.id, [], actor: owner)
    end

    test "an episode has at most one scheduling", %{episode: episode, owner: owner} do
      start!(episode, owner)

      assert {:error, _} = Podcasts.start_scheduling(episode.id, [@fri], actor: owner)
    end

    test "only an episode that is still looking for a date", %{episode: episode, owner: owner} do
      Ash.update!(episode, %{}, action: :finalize_scheduling)

      assert {:error, error} = Podcasts.start_scheduling(episode.id, [@fri], actor: owner)
      assert Exception.message(error) =~ "is not looking for a date"
    end
  end

  describe "proposals" do
    setup %{episode: episode, owner: owner}, do: %{scheduling: start!(episode, owner, [@fri])}

    test "a contributor proposes a date", %{scheduling: scheduling, alice: alice} do
      scheduling = Podcasts.add_scheduling_proposal!(scheduling, @sat, actor: alice)

      assert %Proposal{created_by_user_id: created_by, votes: []} = proposal_at(scheduling, @sat)
      assert created_by == alice.id
    end

    test "a date cannot be proposed twice", %{scheduling: scheduling, alice: alice} do
      assert {:error, error} = Podcasts.add_scheduling_proposal(scheduling, @fri, actor: alice)
      assert Exception.message(error) =~ "has already been proposed"
    end

    test "whoever proposed a date can remove it", %{scheduling: scheduling, alice: alice} do
      scheduling = Podcasts.add_scheduling_proposal!(scheduling, @sat, actor: alice)
      proposal = proposal_at(scheduling, @sat)

      scheduling = Podcasts.remove_scheduling_proposal!(scheduling, proposal.id, actor: alice)

      refute proposal_at(scheduling, @sat)
    end

    test "a member can remove any proposal", %{scheduling: scheduling, alice: alice, owner: owner} do
      scheduling = Podcasts.add_scheduling_proposal!(scheduling, @sat, actor: alice)
      proposal = proposal_at(scheduling, @sat)

      assert {:ok, _} = Podcasts.remove_scheduling_proposal(scheduling, proposal.id, actor: owner)
    end

    test "a contributor cannot remove someone else's proposal", %{
      scheduling: scheduling,
      alice: alice
    } do
      proposal = proposal_at(scheduling, @fri)

      assert {:error, error} =
               Podcasts.remove_scheduling_proposal(scheduling, proposal.id, actor: alice)

      assert Exception.message(error) =~ "only its creator or a podcast member"
    end

    test "an unknown proposal cannot be removed", %{scheduling: scheduling, owner: owner} do
      assert {:error, error} =
               Podcasts.remove_scheduling_proposal(scheduling, Ash.UUID.generate(), actor: owner)

      assert Exception.message(error) =~ "proposal not found"
    end
  end

  describe "vote" do
    setup %{episode: episode, owner: owner}, do: %{scheduling: start!(episode, owner)}

    test "a contributor votes yes, maybe or no as their own person", %{
      scheduling: scheduling,
      alice: alice,
      alice_person: alice_person
    } do
      for {datetime, score} <- [{@fri, 1}, {@sat, 0}, {@sun, -1}] do
        scheduling =
          Podcasts.vote_on_proposal!(scheduling, proposal_at(scheduling, datetime).id, score,
            actor: alice
          )

        assert votes_of(scheduling, datetime) == %{alice_person.id => score}
      end
    end

    test "a second vote replaces the first and leaves other proposals alone", %{
      scheduling: scheduling,
      alice: alice,
      alice_person: alice_person
    } do
      fri = proposal_at(scheduling, @fri).id
      sat = proposal_at(scheduling, @sat).id

      scheduling = Podcasts.vote_on_proposal!(scheduling, sat, 1, actor: alice)
      scheduling = Podcasts.vote_on_proposal!(scheduling, fri, 1, actor: alice)
      scheduling = Podcasts.vote_on_proposal!(scheduling, fri, -1, actor: alice)

      assert votes_of(scheduling, @fri) == %{alice_person.id => -1}
      assert votes_of(scheduling, @sat) == %{alice_person.id => 1}
    end

    test "a comment is kept with the vote", %{scheduling: scheduling, alice: alice} do
      proposal = proposal_at(scheduling, @fri)

      scheduling =
        Podcasts.vote_on_proposal!(scheduling, proposal.id, 0, %{comment: "only after 8"},
          actor: alice
        )

      assert [%{comment: "only after 8"}] = proposal_at(scheduling, @fri).votes
    end

    test "scores other than -1, 0 and 1 are rejected", %{scheduling: scheduling, alice: alice} do
      proposal = proposal_at(scheduling, @fri)

      for score <- [2, -2, 5] do
        assert {:error, _} =
                 Podcasts.vote_on_proposal(scheduling, proposal.id, score, actor: alice)
      end
    end

    test "somebody who is not a contributor cannot vote", %{
      scheduling: scheduling,
      owner: owner
    } do
      proposal = proposal_at(scheduling, @fri)

      assert {:error, error} = Podcasts.vote_on_proposal(scheduling, proposal.id, 1, actor: owner)
      assert Exception.message(error) =~ "only contributors of the episode can vote"
    end

    test "an unknown proposal cannot be voted on", %{scheduling: scheduling, alice: alice} do
      assert {:error, error} =
               Podcasts.vote_on_proposal(scheduling, Ash.UUID.generate(), 1, actor: alice)

      assert Exception.message(error) =~ "proposal not found"
    end

    test "a voter takes back only their own vote", %{
      scheduling: scheduling,
      alice: alice,
      bob: bob,
      bob_person: bob_person
    } do
      proposal = proposal_at(scheduling, @fri)
      scheduling = Podcasts.vote_on_proposal!(scheduling, proposal.id, 1, actor: alice)
      scheduling = Podcasts.vote_on_proposal!(scheduling, proposal.id, -1, actor: bob)

      scheduling = Podcasts.remove_vote!(scheduling, proposal.id, actor: alice)

      assert votes_of(scheduling, @fri) == %{bob_person.id => -1}
    end
  end

  describe "finalize and reopen" do
    setup %{episode: episode, owner: owner, alice: alice} do
      scheduling = start!(episode, owner)

      scheduling =
        Podcasts.vote_on_proposal!(scheduling, proposal_at(scheduling, @sat).id, 1, actor: alice)

      %{scheduling: scheduling}
    end

    test "finalizing closes on the chosen date and schedules the episode", %{
      scheduling: scheduling,
      episode: episode,
      owner: owner
    } do
      chosen = proposal_at(scheduling, @fri)

      scheduling = Podcasts.finalize_scheduling!(scheduling, chosen.id, actor: owner)

      assert scheduling.status == :closed
      assert scheduling.chosen_proposal_id == chosen.id
      assert scheduling.chosen_datetime == @fri
      assert scheduling.finalized_at
      assert reload_episode(episode).state == :scheduled
    end

    test "an unknown proposal cannot be chosen", %{scheduling: scheduling, owner: owner} do
      assert {:error, error} =
               Podcasts.finalize_scheduling(scheduling, Ash.UUID.generate(), actor: owner)

      assert Exception.message(error) =~ "proposal not found"
    end

    test "a closed scheduling takes no votes, proposals or second choice", %{
      scheduling: scheduling,
      owner: owner,
      alice: alice
    } do
      fri = proposal_at(scheduling, @fri).id
      scheduling = Podcasts.finalize_scheduling!(scheduling, fri, actor: owner)

      assert {:error, _} = Podcasts.vote_on_proposal(scheduling, fri, 1, actor: alice)
      assert {:error, _} = Podcasts.remove_vote(scheduling, fri, actor: alice)

      assert {:error, _} =
               Podcasts.add_scheduling_proposal(scheduling, ~U[2026-11-09 19:00:00Z],
                 actor: alice
               )

      assert {:error, _} = Podcasts.remove_scheduling_proposal(scheduling, fri, actor: owner)
      assert {:error, _} = Podcasts.finalize_scheduling(scheduling, fri, actor: owner)
    end

    test "reopening clears the choice, keeps the votes and reschedules the episode", %{
      scheduling: scheduling,
      episode: episode,
      owner: owner,
      alice_person: alice_person
    } do
      scheduling =
        Podcasts.finalize_scheduling!(scheduling, proposal_at(scheduling, @fri).id, actor: owner)

      scheduling = Podcasts.reopen_scheduling!(scheduling, actor: owner)

      assert scheduling.status == :open
      refute scheduling.chosen_proposal_id
      refute scheduling.chosen_datetime
      refute scheduling.finalized_at
      assert votes_of(scheduling, @sat) == %{alice_person.id => 1}
      assert reload_episode(episode).state == :scheduling
    end

    test "an open scheduling cannot be reopened", %{scheduling: scheduling, owner: owner} do
      assert {:error, _} = Podcasts.reopen_scheduling(scheduling, actor: owner)
    end

    test "when the episode cannot be scheduled, the scheduling stays open", %{
      scheduling: scheduling,
      episode: episode,
      owner: owner
    } do
      Ash.update!(episode, %{}, action: :finalize_scheduling)

      assert {:error, _} =
               Podcasts.finalize_scheduling(scheduling, proposal_at(scheduling, @fri).id,
                 actor: owner
               )

      assert Podcasts.get_scheduling_by_episode!(episode.id, actor: owner).status == :open
    end
  end

  describe "participants" do
    test "are the episode's contributors who can sign in, by name", %{
      episode: episode,
      owner: owner,
      alice_person: alice_person,
      bob_person: bob_person
    } do
      contribute!(episode, owner, "Feed Person", nil)
      Ash.create!(EpisodeContributor, %{episode_id: episode.id, person_id: alice_person.id})

      assert episode.id |> Podcasts.read_scheduling_participants!() |> Enum.map(& &1.id) ==
               [alice_person.id, bob_person.id]
    end
  end
end
