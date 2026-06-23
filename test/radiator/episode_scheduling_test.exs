defmodule Radiator.EpisodeSchedulingTest do
  use Radiator.DataCase, async: true

  alias Radiator.Accounts.User
  alias Radiator.Podcasts

  alias Radiator.Podcasts.Episode.Scheduling

  describe "start_scheduling" do
    setup do
      episode = generate(episode(%{title: "Test Episode"}))
      owner = generate(user(%{handle: "owner"}))
      guest1 = generate(user(%{handle: "guest1"}))
      guest2 = generate(user(%{handle: "guest2"}))

      %{
        episode: episode,
        owner: owner,
        participants: [guest1, guest2]
      }
    end

    test "creates scheduling with valid attributes", %{
      episode: episode,
      owner: owner,
      participants: participants
    } do
      participant_ids = Enum.map(participants, & &1.id)

      relate_participants!(episode, participants)

      assert {:ok, scheduling} =
               Radiator.Podcasts.start_scheduling(%{
                 episode_id: episode.id,
                 owner_user_id: owner.id,
                 proposed_datetimes: [
                   ~U[2024-03-15 14:00:00Z],
                   ~U[2024-03-16 10:00:00Z]
                 ]
               })

      assert scheduling.episode_id == episode.id
      assert scheduling.owner_user_id == owner.id
      assert scheduling.status == :open
      assert length(scheduling.proposals) == 2
      assert scheduling.published_at != nil

      episode_participant_ids =
        episode
        |> Ash.load!(:participants, authorize?: false)
        |> Map.fetch!(:participants)
        |> MapSet.new(& &1.id)

      assert episode_participant_ids == MapSet.new(participant_ids)
    end

    test "requires at least one proposed datetime", %{
      episode: episode,
      owner: owner
    } do
      assert {:error, changeset} =
               Radiator.Podcasts.start_scheduling(%{
                 episode_id: episode.id,
                 owner_user_id: owner.id,
                 proposed_datetimes: []
               })

      assert changeset.errors != []
    end

    test "sets status to open by default", %{
      episode: episode,
      owner: owner
    } do
      {:ok, scheduling} =
        Radiator.Podcasts.start_scheduling(%{
          episode_id: episode.id,
          owner_user_id: owner.id,
          proposed_datetimes: [~U[2024-03-15 14:00:00Z]]
        })

      assert scheduling.status == :open
    end

    test "creates proposals with correct structure", %{
      episode: episode,
      owner: owner
    } do
      {:ok, scheduling} =
        Radiator.Podcasts.start_scheduling(%{
          episode_id: episode.id,
          owner_user_id: owner.id,
          proposed_datetimes: [~U[2024-03-15 14:00:00Z]]
        })

      [proposal] = scheduling.proposals

      assert proposal.id != nil
      assert proposal.datetime == ~U[2024-03-15 14:00:00Z]
      assert proposal.created_by_user_id == owner.id
      assert proposal.votes == []
      assert proposal.inserted_at != nil
      assert proposal.updated_at != nil
    end
  end

  describe "Voting" do
    setup do
      {:ok, scheduling} = create_test_scheduling()
      [proposal | _] = scheduling.proposals
      {:ok, participant} = get_participant(scheduling)

      %{scheduling: scheduling, proposal: proposal, participant: participant}
    end

    test "allows participants to vote", %{
      scheduling: scheduling,
      proposal: proposal,
      participant: participant
    } do
      {:ok, updated_scheduling} =
        Scheduling.vote(
          scheduling,
          proposal.id,
          participant.id,
          1,
          actor: participant
        )

      [updated_proposal | _] = updated_scheduling.proposals
      assert length(updated_proposal.votes) == 1

      [vote] = updated_proposal.votes
      assert vote.user_id == participant.id
      assert vote.score == 1
      assert vote.voted_at != nil
    end

    test "allows voting with a comment", %{
      scheduling: scheduling,
      proposal: proposal,
      participant: participant
    } do
      {:ok, updated_scheduling} =
        scheduling
        |> Ash.Changeset.for_update(
          :vote,
          %{
            proposal_id: proposal.id,
            user_id: participant.id,
            score: 1,
            comment: "This time works for me"
          },
          actor: participant
        )
        |> Ash.update()

      [updated_proposal | _] = updated_scheduling.proposals
      [vote] = updated_proposal.votes
      assert vote.comment == "This time works for me"
    end

    test "updates existing vote from same user", %{
      scheduling: scheduling,
      proposal: proposal,
      participant: participant
    } do
      # First vote
      {:ok, scheduling} =
        Scheduling.vote(
          scheduling,
          proposal.id,
          participant.id,
          0,
          actor: participant
        )

      # Second vote from same user
      {:ok, updated_scheduling} =
        Scheduling.vote(
          scheduling,
          proposal.id,
          participant.id,
          1,
          actor: participant
        )

      [updated_proposal | _] = updated_scheduling.proposals
      assert length(updated_proposal.votes) == 1

      [vote] = updated_proposal.votes
      assert vote.score == 1
    end

    test "rejects scores outside the -1 / 0 / 1 range", %{
      scheduling: scheduling,
      proposal: proposal,
      participant: participant
    } do
      assert {:error, changeset} =
               Scheduling.vote(
                 scheduling,
                 proposal.id,
                 participant.id,
                 2,
                 actor: participant
               )

      assert changeset.errors != []
    end

    test "prevents non-participants from voting", %{scheduling: scheduling, proposal: proposal} do
      non_participant = create_participant_with_user("Non", "non")

      assert {:error, changeset} =
               Scheduling.vote(
                 scheduling,
                 proposal.id,
                 non_participant.id,
                 1,
                 actor: non_participant
               )

      assert changeset.errors != []
    end

    test "prevents voting on closed scheduling", %{
      scheduling: scheduling,
      proposal: proposal,
      participant: participant
    } do
      # Close the scheduling
      {:ok, closed_scheduling} = close_scheduling(scheduling)

      assert {:error, changeset} =
               Scheduling.vote(
                 closed_scheduling,
                 proposal.id,
                 participant.id,
                 1,
                 actor: participant
               )

      assert changeset.errors != []
    end
  end

  describe "Adding proposals" do
    setup do
      {:ok, scheduling} = create_test_scheduling()
      {:ok, participant} = get_participant(scheduling)

      %{scheduling: scheduling, participant: participant}
    end

    test "allows participants to add proposals", %{
      scheduling: scheduling,
      participant: participant
    } do
      initial_count = length(scheduling.proposals)

      {:ok, updated_scheduling} =
        scheduling
        |> Ash.Changeset.for_update(:add_proposal, %{
          datetime: ~U[2024-03-18 09:00:00Z],
          user_id: participant.id
        })
        |> Ash.update()

      assert length(updated_scheduling.proposals) == initial_count + 1

      [new_proposal | _] = updated_scheduling.proposals
      assert new_proposal.datetime == ~U[2024-03-18 09:00:00Z]
      assert new_proposal.created_by_user_id == participant.id
      assert new_proposal.votes == []
    end

    test "prevents non-participants from adding proposals", %{scheduling: scheduling} do
      non_participant = generate(user(%{handle: "non"}))

      assert {:error, changeset} =
               scheduling
               |> Ash.Changeset.for_update(:add_proposal, %{
                 datetime: ~U[2024-03-18 09:00:00Z],
                 user_id: non_participant.id
               })
               |> Ash.update()

      assert changeset.errors != []
    end

    test "prevents adding proposals to closed scheduling", %{
      scheduling: scheduling,
      participant: participant
    } do
      {:ok, closed_scheduling} = close_scheduling(scheduling)

      assert {:error, changeset} =
               closed_scheduling
               |> Ash.Changeset.for_update(:add_proposal, %{
                 datetime: ~U[2024-03-18 09:00:00Z],
                 user_id: participant.id
               })
               |> Ash.update()

      assert changeset.errors != []
    end
  end

  describe "Removing proposals" do
    setup do
      {:ok, scheduling} = create_test_scheduling()
      [proposal | _] = scheduling.proposals
      {:ok, owner} = get_owner(scheduling)

      %{scheduling: scheduling, proposal: proposal, owner: owner}
    end

    test "owner can remove any proposal", %{
      scheduling: scheduling,
      proposal: proposal,
      owner: owner
    } do
      initial_count = length(scheduling.proposals)

      {:ok, updated_scheduling} =
        scheduling
        |> Ash.Changeset.for_update(:remove_proposal, %{
          proposal_id: proposal.id,
          user_id: owner.id
        })
        |> Ash.update()

      assert length(updated_scheduling.proposals) == initial_count - 1
    end

    test "creator can remove their own proposal", %{scheduling: scheduling} do
      {:ok, participant} = get_participant(scheduling)

      # Add a new proposal
      {:ok, scheduling} =
        scheduling
        |> Ash.Changeset.for_update(:add_proposal, %{
          datetime: ~U[2024-03-18 09:00:00Z],
          user_id: participant.id
        })
        |> Ash.update()

      [new_proposal | _] = scheduling.proposals
      initial_count = length(scheduling.proposals)

      {:ok, updated_scheduling} =
        scheduling
        |> Ash.Changeset.for_update(:remove_proposal, %{
          proposal_id: new_proposal.id,
          user_id: participant.id
        })
        |> Ash.update()

      assert length(updated_scheduling.proposals) == initial_count - 1
    end

    test "prevents non-owner from removing others' proposals", %{
      scheduling: scheduling,
      proposal: proposal
    } do
      {:ok, participant} = get_participant(scheduling)

      assert {:error, changeset} =
               scheduling
               |> Ash.Changeset.for_update(:remove_proposal, %{
                 proposal_id: proposal.id,
                 user_id: participant.id
               })
               |> Ash.update()

      assert changeset.errors != []
    end

    test "prevents removing proposals from closed scheduling", %{
      scheduling: scheduling,
      proposal: proposal,
      owner: owner
    } do
      {:ok, closed_scheduling} = close_scheduling(scheduling)

      assert {:error, changeset} =
               closed_scheduling
               |> Ash.Changeset.for_update(:remove_proposal, %{
                 proposal_id: proposal.id,
                 user_id: owner.id
               })
               |> Ash.update()

      assert changeset.errors != []
    end
  end

  describe "Removing votes" do
    setup do
      {:ok, scheduling} = create_test_scheduling()
      [proposal | _] = scheduling.proposals
      {:ok, participant} = get_participant(scheduling)

      # Cast a vote
      {:ok, scheduling} =
        scheduling
        |> Ash.Changeset.for_update(
          :vote,
          %{
            proposal_id: proposal.id,
            user_id: participant.id,
            score: 1
          },
          actor: participant
        )
        |> Ash.update()

      %{scheduling: scheduling, proposal: proposal, participant: participant}
    end

    test "allows removing own vote", %{
      scheduling: scheduling,
      proposal: proposal,
      participant: participant
    } do
      {:ok, updated_scheduling} =
        scheduling
        |> Ash.Changeset.for_update(:remove_vote, %{
          proposal_id: proposal.id,
          user_id: participant.id
        })
        |> Ash.update()

      [updated_proposal | _] = updated_scheduling.proposals
      assert updated_proposal.votes == []
    end

    test "prevents removing votes from closed scheduling", %{
      scheduling: scheduling,
      proposal: proposal,
      participant: participant
    } do
      {:ok, closed_scheduling} = close_scheduling(scheduling)

      assert {:error, changeset} =
               closed_scheduling
               |> Ash.Changeset.for_update(:remove_vote, %{
                 proposal_id: proposal.id,
                 user_id: participant.id
               })
               |> Ash.update()

      assert changeset.errors != []
    end
  end

  describe "Finalizing scheduling" do
    setup do
      {:ok, scheduling} = create_test_scheduling()
      [proposal | _] = scheduling.proposals
      {:ok, owner} = get_owner(scheduling)

      %{scheduling: scheduling, proposal: proposal, owner: owner}
    end

    test "owner can finalize scheduling", %{
      scheduling: scheduling,
      proposal: proposal,
      owner: owner
    } do
      {:ok, finalized_scheduling} =
        scheduling
        |> Ash.Changeset.for_update(:finalize, %{
          chosen_proposal_id: proposal.id,
          user_id: owner.id
        })
        |> Ash.update()

      assert finalized_scheduling.status == :closed
      assert finalized_scheduling.chosen_proposal_id == proposal.id
      assert finalized_scheduling.chosen_datetime == proposal.datetime
      assert finalized_scheduling.finalized_at != nil
    end

    test "non-owner cannot finalize scheduling", %{scheduling: scheduling, proposal: proposal} do
      {:ok, participant} = get_participant(scheduling)

      assert {:error, changeset} =
               scheduling
               |> Ash.Changeset.for_update(:finalize, %{
                 chosen_proposal_id: proposal.id,
                 user_id: participant.id
               })
               |> Ash.update()

      assert changeset.errors != []
    end

    test "cannot finalize with non-existent proposal", %{scheduling: scheduling, owner: owner} do
      fake_proposal_id = Ash.UUID.generate()

      assert {:error, changeset} =
               scheduling
               |> Ash.Changeset.for_update(:finalize, %{
                 chosen_proposal_id: fake_proposal_id,
                 user_id: owner.id
               })
               |> Ash.update()

      assert changeset.errors != []
    end

    test "cannot finalize already closed scheduling", %{
      scheduling: scheduling,
      proposal: proposal,
      owner: owner
    } do
      {:ok, closed_scheduling} = close_scheduling(scheduling)

      assert {:error, changeset} =
               closed_scheduling
               |> Ash.Changeset.for_update(:finalize, %{
                 chosen_proposal_id: proposal.id,
                 user_id: owner.id
               })
               |> Ash.update()

      assert changeset.errors != []
    end
  end

  describe "Reopening scheduling" do
    setup do
      {:ok, scheduling} = create_test_scheduling()
      {:ok, closed_scheduling} = close_scheduling(scheduling)
      {:ok, owner} = get_owner(closed_scheduling)

      %{scheduling: closed_scheduling, owner: owner}
    end

    test "owner can reopen closed scheduling", %{scheduling: scheduling, owner: owner} do
      {:ok, reopened_scheduling} =
        scheduling
        |> Ash.Changeset.for_update(:reopen, %{
          user_id: owner.id
        })
        |> Ash.update()

      assert reopened_scheduling.status == :open
      assert reopened_scheduling.chosen_proposal_id == nil
      assert reopened_scheduling.chosen_datetime == nil
      assert reopened_scheduling.finalized_at == nil
    end

    test "non-owner cannot reopen scheduling", %{scheduling: scheduling} do
      {:ok, participant} = get_participant(scheduling)

      assert {:error, changeset} =
               scheduling
               |> Ash.Changeset.for_update(:reopen, %{
                 user_id: participant.id
               })
               |> Ash.update()

      assert changeset.errors != []
    end
  end

  describe "Voting statistics" do
    setup do
      {:ok, scheduling} = create_test_scheduling()
      [proposal1, proposal2 | _] = scheduling.proposals
      participant_ids = participant_ids_for(scheduling)
      [participant1_id, participant2_id | _] = participant_ids
      actor1 = Ash.get!(User, participant1_id, authorize?: false)
      actor2 = Ash.get!(User, participant2_id, authorize?: false)

      # Add some votes
      {:ok, scheduling} =
        scheduling
        |> Ash.Changeset.for_update(
          :vote,
          %{
            proposal_id: proposal1.id,
            user_id: participant1_id,
            score: 1
          },
          actor: actor1
        )
        |> Ash.update()

      {:ok, scheduling} =
        scheduling
        |> Ash.Changeset.for_update(
          :vote,
          %{
            proposal_id: proposal1.id,
            user_id: participant2_id,
            score: 1
          },
          actor: actor2
        )
        |> Ash.update()

      {:ok, scheduling} =
        scheduling
        |> Ash.Changeset.for_update(
          :vote,
          %{
            proposal_id: proposal2.id,
            user_id: participant1_id,
            score: 0
          },
          actor: actor1
        )
        |> Ash.update()

      %{
        scheduling: scheduling,
        proposal1: proposal1,
        proposal2: proposal2,
        participant_ids: participant_ids
      }
    end

    test "calculates voting statistics correctly", %{
      scheduling: scheduling,
      participant_ids: participant_ids
    } do
      stats = Scheduling.voting_stats(scheduling, participant_ids)

      assert stats.status == :open
      assert stats.participant_count == 3
      assert stats.proposal_count == 3
      assert stats.total_votes == 3
      assert stats.voted_participant_count == 2
      assert stats.all_voted? == false
      assert length(stats.proposal_stats) == 3
    end

    test "identifies top proposal by total score", %{
      scheduling: scheduling,
      proposal1: proposal1,
      participant_ids: participant_ids
    } do
      stats = Scheduling.voting_stats(scheduling, participant_ids)

      assert stats.top_proposal != nil
      assert stats.top_proposal.proposal_id == proposal1.id
      assert stats.top_proposal.total_score == 2
      assert stats.top_proposal_id == proposal1.id
    end

    test "exposes total_score, yes/maybe/no counts per proposal", %{
      scheduling: scheduling,
      proposal1: proposal1,
      proposal2: proposal2,
      participant_ids: participant_ids
    } do
      stats = Scheduling.voting_stats(scheduling, participant_ids)

      stat1 = Enum.find(stats.proposal_stats, &(&1.proposal_id == proposal1.id))
      stat2 = Enum.find(stats.proposal_stats, &(&1.proposal_id == proposal2.id))

      assert stat1.total_score == 2
      assert stat1.yes_count == 2
      assert stat1.maybe_count == 0
      assert stat1.no_count == 0
      assert stat1.pending_count == 1

      assert stat2.total_score == 0
      assert stat2.yes_count == 0
      assert stat2.maybe_count == 1
      assert stat2.no_count == 0
      assert stat2.pending_count == 2
    end

    test "handles proposals with no votes", %{
      scheduling: scheduling,
      participant_ids: participant_ids
    } do
      stats = Scheduling.voting_stats(scheduling, participant_ids)

      proposal_without_votes = Enum.find(stats.proposal_stats, &(&1.votes == []))

      assert proposal_without_votes.total_score == 0
      assert proposal_without_votes.pending_count == 3
    end
  end

  describe "Helper functions" do
    setup do
      {:ok, scheduling} = create_test_scheduling()
      [proposal | _] = scheduling.proposals
      [participant_id | _] = participant_ids_for(scheduling)

      {:ok, scheduling} =
        scheduling
        |> Ash.Changeset.for_update(
          :vote,
          %{
            proposal_id: proposal.id,
            user_id: participant_id,
            score: 1
          },
          actor: Ash.get!(User, participant_id, authorize?: false)
        )
        |> Ash.update()

      %{scheduling: scheduling, proposal: proposal, participant_id: participant_id}
    end

    test "get_proposal returns correct proposal", %{scheduling: scheduling, proposal: proposal} do
      found_proposal = Scheduling.get_proposal(scheduling, proposal.id)
      assert found_proposal.id == proposal.id
    end

    test "get_proposal returns nil for non-existent proposal", %{scheduling: scheduling} do
      fake_id = Ash.UUID.generate()
      result = Scheduling.get_proposal(scheduling, fake_id)
      assert is_nil(result)
    end

    test "voted_on_proposal? returns true when voted", %{
      scheduling: scheduling,
      proposal: proposal,
      participant_id: participant_id
    } do
      assert Scheduling.voted_on_proposal?(scheduling, proposal.id, participant_id) == true
    end

    test "voted_on_proposal? returns false when not voted", %{
      scheduling: scheduling,
      proposal: proposal
    } do
      non_voter_id = Ash.UUID.generate()
      assert Scheduling.voted_on_proposal?(scheduling, proposal.id, non_voter_id) == false
    end

    test "get_user_votes returns all votes from participant", %{
      scheduling: scheduling,
      participant_id: participant_id
    } do
      votes = Scheduling.get_user_votes(scheduling, participant_id)
      assert length(votes) == 1

      [{_proposal_id, vote}] = votes
      assert vote.user_id == participant_id
      assert vote.score == 1
    end

    test "get_user_votes returns empty list for non-voter", %{scheduling: scheduling} do
      non_voter_id = Ash.UUID.generate()
      votes = Scheduling.get_user_votes(scheduling, non_voter_id)
      assert votes == []
    end
  end

  describe "Episode state integration" do
    setup do
      {:ok, podcast} = Podcasts.create_podcast(%{title: "Test Podcast"})
      {:ok, episode} = Podcasts.create_episode(%{title: "Test Episode", podcast_id: podcast.id})

      %{episode: episode}
    end

    test "episode starts in scheduling state by default", %{episode: episode} do
      assert episode.state == :scheduling
    end

    test "episode can transition to scheduled state", %{episode: episode} do
      {:ok, updated_episode} =
        episode
        |> Ash.Changeset.for_update(:finalize_scheduling, %{
          publication_date: ~U[2024-03-15 14:00:00Z]
        })
        |> Ash.update()

      assert updated_episode.state == :scheduled
      # Parse for comparison since it might be stored differently
      expected_dt = ~U[2024-03-15 14:00:00Z]
      assert DateTime.compare(updated_episode.publication_date, expected_dt) == :eq
    end

    test "episode can go back to scheduling state", %{episode: episode} do
      # First finalize
      {:ok, scheduled_episode} =
        episode
        |> Ash.Changeset.for_update(:finalize_scheduling, %{
          publication_date: ~U[2024-03-15 14:00:00Z]
        })
        |> Ash.update()

      # Then go back
      {:ok, back_to_scheduling} =
        scheduled_episode
        |> Ash.Changeset.for_update(:back_to_scheduling, %{})
        |> Ash.update()

      assert back_to_scheduling.state == :scheduling
    end
  end

  # Helper functions for tests

  defp create_test_scheduling do
    {:ok, podcast} = Podcasts.create_podcast(%{title: "Test Podcast"})
    {:ok, episode} = Podcasts.create_episode(%{title: "Test Episode", podcast_id: podcast.id})

    owner = generate(user(%{handle: "test_owner"}))

    participant1 = create_participant_with_user("Participant 1", "participant1")
    participant2 = create_participant_with_user("Participant 2", "participant2")
    participant3 = create_participant_with_user("Participant 3", "participant3")

    participants = [participant1, participant2, participant3]

    relate_participants!(episode, participants)

    Scheduling
    |> Ash.Changeset.for_create(:create, %{
      episode_id: episode.id,
      owner_user_id: owner.id,
      proposed_datetimes: [
        ~U[2024-03-15 14:00:00Z],
        ~U[2024-03-16 10:00:00Z],
        ~U[2024-03-17 15:00:00Z]
      ]
    })
    |> Ash.create()
  end

  defp create_participant_with_user(_name, _handle), do: build_user()

  defp relate_participants!(episode, users) do
    episode
    |> Ash.Changeset.for_update(
      :update,
      %{participants: Enum.map(users, &%{email: to_string(&1.email)})},
      authorize?: false
    )
    |> Ash.update!()
  end

  # Returns the list of participant user ids for a scheduling's episode.
  defp participant_ids_for(scheduling) do
    scheduling.episode_id
    |> then(&Ash.get!(Radiator.Podcasts.Episode, &1, authorize?: false))
    |> Ash.load!(:participants, authorize?: false)
    |> Map.fetch!(:participants)
    |> Enum.map(& &1.id)
  end

  defp build_user do
    email = "user_#{System.unique_integer([:positive])}@example.com"
    {:ok, hashed_password} = AshAuthentication.BcryptProvider.hash("supersupersecret")
    Ash.Seed.seed!(User, %{email: email, hashed_password: hashed_password})
  end

  defp close_scheduling(scheduling) do
    [proposal | _] = scheduling.proposals

    scheduling
    |> Ash.Changeset.for_update(:finalize, %{
      chosen_proposal_id: proposal.id,
      user_id: scheduling.owner_user_id
    })
    |> Ash.update()
  end

  defp get_owner(scheduling) do
    User
    |> Ash.get!(scheduling.owner_user_id, authorize?: false)
    |> then(&{:ok, &1})
  end

  defp get_participant(scheduling) do
    [participant_id | _] = participant_ids_for(scheduling)

    User
    |> Ash.get!(participant_id, authorize?: false)
    |> then(&{:ok, &1})
  end
end
