defmodule Radiator.EpisodeSchedulingTest do
  use Radiator.DataCase, async: true

  alias Radiator.People
  alias Radiator.Podcasts

  alias Radiator.Podcasts.Episode.Scheduling

  describe "start_scheduling" do
    setup do
      episode = generate(episode(%{title: "Test Episode"}))
      owner = generate(persona(%{public_name: "Owner", handle: "owner"}))
      guest1 = generate(persona(%{public_name: "Guest 1", handle: "guest1"}))
      guest2 = generate(persona(%{public_name: "Guest 2", handle: "guest2"}))

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

      assert {:ok, scheduling} =
               Radiator.Podcasts.start_scheduling(%{
                 episode_id: episode.id,
                 owner_persona_id: owner.id,
                 participant_persona_ids: participant_ids,
                 proposed_datetimes: [
                   ~U[2024-03-15 14:00:00Z],
                   ~U[2024-03-16 10:00:00Z]
                 ]
               })

      assert scheduling.episode_id == episode.id
      assert scheduling.owner_persona_id == owner.id
      assert scheduling.participant_persona_ids == participant_ids
      assert scheduling.status == :open
      assert length(scheduling.proposals) == 2
      assert scheduling.published_at != nil
    end

    test "requires at least one proposed datetime", %{
      episode: episode,
      owner: owner,
      participants: participants
    } do
      assert {:error, changeset} =
               Radiator.Podcasts.start_scheduling(%{
                 episode_id: episode.id,
                 owner_persona_id: owner.id,
                 participant_persona_ids: Enum.map(participants, & &1.id),
                 proposed_datetimes: []
               })

      assert changeset.errors != []
    end

    test "sets status to open by default", %{
      episode: episode,
      owner: owner,
      participants: participants
    } do
      {:ok, scheduling} =
        Radiator.Podcasts.start_scheduling(%{
          episode_id: episode.id,
          owner_persona_id: owner.id,
          participant_persona_ids: Enum.map(participants, & &1.id),
          proposed_datetimes: [~U[2024-03-15 14:00:00Z]]
        })

      assert scheduling.status == :open
    end

    test "creates proposals with correct structure", %{
      episode: episode,
      owner: owner,
      participants: participants
    } do
      {:ok, scheduling} =
        Radiator.Podcasts.start_scheduling(%{
          episode_id: episode.id,
          owner_persona_id: owner.id,
          participant_persona_ids: Enum.map(participants, & &1.id),
          proposed_datetimes: [~U[2024-03-15 14:00:00Z]]
        })

      [proposal] = scheduling.proposals

      assert proposal["id"] != nil
      assert proposal["datetime"] == "2024-03-15T14:00:00Z"
      assert proposal["created_by_persona_id"] == owner.id
      assert proposal["votes"] == []
      assert proposal["inserted_at"] != nil
      assert proposal["updated_at"] != nil
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
          proposal["id"],
          participant.id,
          5
        )

      [updated_proposal | _] = updated_scheduling.proposals
      assert length(updated_proposal["votes"]) == 1

      [vote] = updated_proposal["votes"]
      assert vote["persona_id"] == participant.id
      assert vote["score"] == 5
      assert vote["voted_at"] != nil
    end

    test "allows voting with a comment", %{
      scheduling: scheduling,
      proposal: proposal,
      participant: participant
    } do
      {:ok, updated_scheduling} =
        scheduling
        |> Ash.Changeset.for_update(:vote, %{
          proposal_id: proposal["id"],
          persona_id: participant.id,
          score: 4,
          comment: "This time works for me"
        })
        |> Ash.update()

      [updated_proposal | _] = updated_scheduling.proposals
      [vote] = updated_proposal["votes"]
      assert vote["comment"] == "This time works for me"
    end

    test "updates existing vote from same persona", %{
      scheduling: scheduling,
      proposal: proposal,
      participant: participant
    } do
      # First vote
      {:ok, scheduling} =
        Scheduling.vote(
          scheduling,
          proposal["id"],
          participant.id,
          3
        )

      # Second vote from same persona
      {:ok, updated_scheduling} =
        Scheduling.vote(
          scheduling,
          proposal["id"],
          participant.id,
          5
        )

      [updated_proposal | _] = updated_scheduling.proposals
      assert length(updated_proposal["votes"]) == 1

      [vote] = updated_proposal["votes"]
      assert vote["score"] == 5
    end

    test "validates score is between 1 and 5", %{
      scheduling: scheduling,
      proposal: proposal,
      participant: participant
    } do
      assert {:error, changeset} =
               Scheduling.vote(
                 scheduling,
                 proposal["id"],
                 participant.id,
                 6
               )

      assert changeset.errors != []
    end

    test "prevents non-participants from voting", %{scheduling: scheduling, proposal: proposal} do
      {:ok, non_participant} = People.create_persona(%{public_name: "Non", handle: "non"})

      assert {:error, changeset} =
               Scheduling.vote(
                 scheduling,
                 proposal["id"],
                 non_participant.id,
                 5
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
                 proposal["id"],
                 participant.id,
                 5
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
          persona_id: participant.id
        })
        |> Ash.update()

      assert length(updated_scheduling.proposals) == initial_count + 1

      [new_proposal | _] = updated_scheduling.proposals
      assert new_proposal["datetime"] == "2024-03-18T09:00:00Z"
      assert new_proposal["created_by_persona_id"] == participant.id
      assert new_proposal["votes"] == []
    end

    test "prevents non-participants from adding proposals", %{scheduling: scheduling} do
      {:ok, non_participant} = People.create_persona(%{public_name: "Non", handle: "non"})

      assert {:error, changeset} =
               scheduling
               |> Ash.Changeset.for_update(:add_proposal, %{
                 datetime: ~U[2024-03-18 09:00:00Z],
                 persona_id: non_participant.id
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
                 persona_id: participant.id
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
          proposal_id: proposal["id"],
          persona_id: owner.id
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
          persona_id: participant.id
        })
        |> Ash.update()

      [new_proposal | _] = scheduling.proposals
      initial_count = length(scheduling.proposals)

      {:ok, updated_scheduling} =
        scheduling
        |> Ash.Changeset.for_update(:remove_proposal, %{
          proposal_id: new_proposal["id"],
          persona_id: participant.id
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
                 proposal_id: proposal["id"],
                 persona_id: participant.id
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
                 proposal_id: proposal["id"],
                 persona_id: owner.id
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
        |> Ash.Changeset.for_update(:vote, %{
          proposal_id: proposal["id"],
          persona_id: participant.id,
          score: 5
        })
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
          proposal_id: proposal["id"],
          persona_id: participant.id
        })
        |> Ash.update()

      [updated_proposal | _] = updated_scheduling.proposals
      assert updated_proposal["votes"] == []
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
                 proposal_id: proposal["id"],
                 persona_id: participant.id
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
          chosen_proposal_id: proposal["id"],
          persona_id: owner.id
        })
        |> Ash.update()

      assert finalized_scheduling.status == :closed
      assert finalized_scheduling.chosen_proposal_id == proposal["id"]
      # Parse the JSONB string datetime for comparison
      {:ok, proposal_dt, 0} = DateTime.from_iso8601(proposal["datetime"])
      assert finalized_scheduling.chosen_datetime == proposal_dt
      assert finalized_scheduling.finalized_at != nil
    end

    test "non-owner cannot finalize scheduling", %{scheduling: scheduling, proposal: proposal} do
      {:ok, participant} = get_participant(scheduling)

      assert {:error, changeset} =
               scheduling
               |> Ash.Changeset.for_update(:finalize, %{
                 chosen_proposal_id: proposal["id"],
                 persona_id: participant.id
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
                 persona_id: owner.id
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
                 chosen_proposal_id: proposal["id"],
                 persona_id: owner.id
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
          persona_id: owner.id
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
                 persona_id: participant.id
               })
               |> Ash.update()

      assert changeset.errors != []
    end
  end

  describe "Voting statistics" do
    setup do
      {:ok, scheduling} = create_test_scheduling()
      [proposal1, proposal2 | _] = scheduling.proposals
      [participant1_id, participant2_id | _] = scheduling.participant_persona_ids

      # Add some votes
      {:ok, scheduling} =
        scheduling
        |> Ash.Changeset.for_update(:vote, %{
          proposal_id: proposal1["id"],
          persona_id: participant1_id,
          score: 5
        })
        |> Ash.update()

      {:ok, scheduling} =
        scheduling
        |> Ash.Changeset.for_update(:vote, %{
          proposal_id: proposal1["id"],
          persona_id: participant2_id,
          score: 4
        })
        |> Ash.update()

      {:ok, scheduling} =
        scheduling
        |> Ash.Changeset.for_update(:vote, %{
          proposal_id: proposal2["id"],
          persona_id: participant1_id,
          score: 3
        })
        |> Ash.update()

      %{scheduling: scheduling}
    end

    test "calculates voting statistics correctly", %{scheduling: scheduling} do
      stats = Scheduling.voting_stats(scheduling)

      assert stats.status == :open
      assert stats.participant_count == 3
      assert stats.proposal_count == 3
      assert stats.total_votes == 3
      assert stats.voted_participant_count == 2
      assert stats.all_voted? == false
      assert length(stats.proposal_stats) == 3
    end

    test "identifies top proposal by average score", %{scheduling: scheduling} do
      stats = Scheduling.voting_stats(scheduling)

      assert stats.top_proposal != nil
      assert stats.top_proposal.average_score == 4.5
    end

    test "calculates average scores correctly", %{scheduling: scheduling} do
      stats = Scheduling.voting_stats(scheduling)

      proposal_with_two_votes = Enum.find(stats.proposal_stats, &(&1.vote_count == 2))
      proposal_with_one_vote = Enum.find(stats.proposal_stats, &(&1.vote_count == 1))

      assert proposal_with_two_votes.average_score == 4.5
      assert proposal_with_one_vote.average_score == 3.0
    end

    test "handles proposals with no votes", %{scheduling: scheduling} do
      stats = Scheduling.voting_stats(scheduling)

      proposal_without_votes = Enum.find(stats.proposal_stats, &(&1.vote_count == 0))
      assert proposal_without_votes.average_score == nil
    end
  end

  describe "Helper functions" do
    setup do
      {:ok, scheduling} = create_test_scheduling()
      [proposal | _] = scheduling.proposals
      [participant_id | _] = scheduling.participant_persona_ids

      {:ok, scheduling} =
        scheduling
        |> Ash.Changeset.for_update(:vote, %{
          proposal_id: proposal["id"],
          persona_id: participant_id,
          score: 5
        })
        |> Ash.update()

      %{scheduling: scheduling, proposal: proposal, participant_id: participant_id}
    end

    test "get_proposal returns correct proposal", %{scheduling: scheduling, proposal: proposal} do
      found_proposal = Scheduling.get_proposal(scheduling, proposal["id"])
      assert found_proposal["id"] == proposal["id"]
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
      assert Scheduling.voted_on_proposal?(scheduling, proposal["id"], participant_id) == true
    end

    test "voted_on_proposal? returns false when not voted", %{
      scheduling: scheduling,
      proposal: proposal
    } do
      non_voter_id = Ash.UUID.generate()
      assert Scheduling.voted_on_proposal?(scheduling, proposal["id"], non_voter_id) == false
    end

    test "get_persona_votes returns all votes from participant", %{
      scheduling: scheduling,
      participant_id: participant_id
    } do
      votes = Scheduling.get_persona_votes(scheduling, participant_id)
      assert length(votes) == 1

      [{_proposal_id, vote}] = votes
      assert vote["persona_id"] == participant_id
      assert vote["score"] == 5
    end

    test "get_persona_votes returns empty list for non-voter", %{scheduling: scheduling} do
      non_voter_id = Ash.UUID.generate()
      votes = Scheduling.get_persona_votes(scheduling, non_voter_id)
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

    {:ok, owner} = People.create_persona(%{public_name: "Owner", handle: "test_owner"})

    {:ok, participant1} =
      People.create_persona(%{public_name: "Participant 1", handle: "participant1"})

    {:ok, participant2} =
      People.create_persona(%{public_name: "Participant 2", handle: "participant2"})

    {:ok, participant3} =
      People.create_persona(%{public_name: "Participant 3", handle: "participant3"})

    participant_ids = [participant1.id, participant2.id, participant3.id]

    Scheduling
    |> Ash.Changeset.for_create(:create, %{
      episode_id: episode.id,
      owner_persona_id: owner.id,
      participant_persona_ids: participant_ids,
      proposed_datetimes: [
        ~U[2024-03-15 14:00:00Z],
        ~U[2024-03-16 10:00:00Z],
        ~U[2024-03-17 15:00:00Z]
      ]
    })
    |> Ash.create()
  end

  defp close_scheduling(scheduling) do
    [proposal | _] = scheduling.proposals

    scheduling
    |> Ash.Changeset.for_update(:finalize, %{
      chosen_proposal_id: proposal["id"],
      persona_id: scheduling.owner_persona_id
    })
    |> Ash.update()
  end

  defp get_owner(scheduling) do
    People.Persona
    |> Ash.get!(scheduling.owner_persona_id)
    |> then(&{:ok, &1})
  end

  defp get_participant(scheduling) do
    [participant_id | _] = scheduling.participant_persona_ids

    People.Persona
    |> Ash.get!(participant_id)
    |> then(&{:ok, &1})
  end
end
