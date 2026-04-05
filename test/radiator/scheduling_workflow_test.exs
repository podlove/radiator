defmodule Radiator.SchedulingWorkflowTest do
  use Radiator.DataCase, async: true
  # @moduledoc """
  # Examples and usage patterns for the Episode Scheduling system.

  # This module provides practical examples of how to use the scheduling
  # functionality for coordinating episode recording times with participants.
  # """

  alias Radiator.People
  alias Radiator.Podcasts
  alias Radiator.Podcasts.Episode
  alias Radiator.Podcasts.Episode.Scheduling

  describe "Scheduling integration roudtrip" do
    setup do
      {:ok, podcast} = Podcasts.create_podcast(%{title: "Test Podcast"})
      {:ok, episode} = Podcasts.create_episode(%{title: "Test Episode", podcast_id: podcast.id})

      {:ok, owner} = People.create_persona(%{public_name: "Owner", handle: "owner"})
      {:ok, guest1} = People.create_persona(%{public_name: "Guest 1", handle: "guest1"})
      {:ok, guest2} = People.create_persona(%{public_name: "Guest 2", handle: "guest2"})
      {:ok, guest3} = People.create_persona(%{public_name: "Guest 3", handle: "guest3"})

      %{
        episode: episode,
        owner: owner,
        participants: [guest1, guest2, guest3]
      }
    end

    # Creates a scheduling, participants vote, and owner finalizes.
    test "Basic scheduling workflow", %{
      episode: episode,
      owner: owner,
      participants: participants
    } do
      owner_id = owner.id
      participant_ids = Enum.map(participants, & &1.id)

      # Step 1: Create scheduling with proposed datetimes
      {:ok, scheduling} =
        Scheduling
        |> Ash.Changeset.for_create(:create, %{
          episode_id: episode.id,
          owner_persona_id: owner_id,
          participant_persona_ids: participant_ids,
          proposed_datetimes: [
            ~U[2024-03-15 14:00:00Z],
            ~U[2024-03-16 10:00:00Z],
            ~U[2024-03-17 15:00:00Z]
          ]
        })
        |> Ash.create()

      # Step 2: Participants vote on proposals
      [proposal1, proposal2, _proposal3] = scheduling.proposals

      # First participant votes
      {:ok, scheduling} =
        scheduling
        |> Ash.Changeset.for_update(:vote, %{
          proposal_id: proposal1["id"],
          persona_id: Enum.at(participant_ids, 0),
          score: 5,
          comment: "Perfect time for me!"
        })
        |> Ash.update()

      # Second participant votes
      {:ok, scheduling} =
        scheduling
        |> Ash.Changeset.for_update(:vote, %{
          proposal_id: proposal1["id"],
          persona_id: Enum.at(participant_ids, 1),
          score: 4
        })
        |> Ash.update()

      # Third participant prefers another time
      {:ok, scheduling} =
        scheduling
        |> Ash.Changeset.for_update(:vote, %{
          proposal_id: proposal2["id"],
          persona_id: Enum.at(participant_ids, 2),
          score: 5
        })
        |> Ash.update()

      # Step 3: Check voting statistics
      stats = Scheduling.voting_stats(scheduling)
      # IO.inspect(stats, label: "Voting Statistics")

      # Step 4: Owner finalizes with the winning proposal
      top_proposal = List.first(stats.proposal_stats)

      {:ok, scheduling} =
        scheduling
        |> Ash.Changeset.for_update(:finalize, %{
          chosen_proposal_id: top_proposal.proposal_id,
          persona_id: owner_id
        })
        |> Ash.update()

      # Step 5: Update episode state
      {:ok, episode} =
        episode
        |> Ash.Changeset.for_update(:finalize_scheduling, %{
          publication_date: scheduling.chosen_datetime
        })
        |> Ash.update()

      {:ok, episode, scheduling}
    end
  end

  describe "more workflows" do
    setup do
      # TODO: use generators!!
      {:ok, podcast} = Podcasts.create_podcast(%{title: "Test Podcast"})
      {:ok, episode} = Podcasts.create_episode(%{title: "Test Episode", podcast_id: podcast.id})

      {:ok, owner} = People.create_persona(%{public_name: "Owner", handle: "owner"})
      {:ok, guest1} = People.create_persona(%{public_name: "Guest 1", handle: "guest1"})
      {:ok, guest2} = People.create_persona(%{public_name: "Guest 2", handle: "guest2"})
      {:ok, guest3} = People.create_persona(%{public_name: "Guest 3", handle: "guest3"})

      %{
        episode: episode,
        owner: owner,
        participants: [guest1, guest2, guest3]
      }
    end

    test "A participant can change their vote by voting again with a different score.", %{
      episode: episode,
      owner: owner,
      participants: participants
    } do
      owner_id = owner.id
      participant_ids = Enum.map(participants, & &1.id)

      orig_score = 5
      new_score = 4

      # SETUP (use generators!!)
      # Step 1: Create scheduling with proposed datetimes
      {:ok, scheduling} =
        Scheduling
        |> Ash.Changeset.for_create(:create, %{
          episode_id: episode.id,
          owner_persona_id: owner_id,
          participant_persona_ids: participant_ids,
          proposed_datetimes: [
            ~U[2024-03-15 14:00:00Z],
            ~U[2024-03-16 10:00:00Z],
            ~U[2024-03-17 15:00:00Z]
          ]
        })
        |> Ash.create()

      # Step 2: Participants vote on proposals
      [proposal1, proposal2, _proposal3] = scheduling.proposals

      # First participant votes
      {:ok, scheduling} =
        scheduling
        |> Ash.Changeset.for_update(:vote, %{
          proposal_id: proposal1["id"],
          persona_id: Enum.at(participant_ids, 0),
          score: orig_score,
          comment: "Perfect time for me!"
        })
        |> Ash.update()

      # Second participant votes
      {:ok, scheduling} =
        scheduling
        |> Ash.Changeset.for_update(:vote, %{
          proposal_id: proposal1["id"],
          persona_id: Enum.at(participant_ids, 1),
          score: 4
        })
        |> Ash.update()

      # Third participant prefers another time
      {:ok, scheduling} =
        scheduling
        |> Ash.Changeset.for_update(:vote, %{
          proposal_id: proposal2["id"],
          persona_id: Enum.at(participant_ids, 2),
          score: 5
        })
        |> Ash.update()

      # Example 4: Change vote (participant changes their mind)
      # A participant can change their vote by voting again with a different score.

      proposal_id = proposal1["id"]
      persona_id = Enum.at(participant_ids, 0)

      # Check if persona has already voted
      assert Scheduling.voted_on_proposal?(scheduling, proposal_id, persona_id)

      {:ok, updated_scheduling} =
        scheduling
        |> Ash.Changeset.for_update(:vote, %{
          proposal_id: proposal_id,
          persona_id: persona_id,
          score: new_score,
          comment: "Changed my mind after checking my calendar"
        })
        |> Ash.update()

      assert Enum.count(scheduling.proposals) == Enum.count(updated_scheduling.proposals)
    end

    test "Participant removes their vote", %{
      episode: episode,
      owner: owner,
      participants: participants
    } do
      # SETUP (use generators!!)
      # Step 1: Create scheduling with proposed datetimes
      owner_id = owner.id
      participant_ids = Enum.map(participants, & &1.id)

      {:ok, scheduling} =
        Scheduling
        |> Ash.Changeset.for_create(:create, %{
          episode_id: episode.id,
          owner_persona_id: owner_id,
          participant_persona_ids: participant_ids,
          proposed_datetimes: [
            ~U[2024-03-15 14:00:00Z],
            ~U[2024-03-16 10:00:00Z],
            ~U[2024-03-17 15:00:00Z]
          ]
        })
        |> Ash.create()

      # Step 2: Participants vote on proposals
      [proposal1, proposal2, _proposal3] = scheduling.proposals

      # First participant votes
      {:ok, scheduling} =
        scheduling
        |> Ash.Changeset.for_update(:vote, %{
          proposal_id: proposal1["id"],
          persona_id: Enum.at(participant_ids, 0),
          score: 5,
          comment: "Perfect time for me!"
        })
        |> Ash.update()

      # Second participant votes
      {:ok, scheduling} =
        scheduling
        |> Ash.Changeset.for_update(:vote, %{
          proposal_id: proposal1["id"],
          persona_id: Enum.at(participant_ids, 1),
          score: 4
        })
        |> Ash.update()

      # Third participant prefers another time
      {:ok, scheduling} =
        scheduling
        |> Ash.Changeset.for_update(:vote, %{
          proposal_id: proposal2["id"],
          persona_id: Enum.at(participant_ids, 2),
          score: 5
        })
        |> Ash.update()

      # Example 5: Participant removes their vote
      proposal_id = proposal1["id"]
      persona_id = Enum.at(participant_ids, 0)

      [{_id, vote}] = Scheduling.get_persona_votes(scheduling, persona_id)
      assert persona_id == Map.get(vote, "persona_id")

      {:ok, updated_scheduling} =
        scheduling
        |> Ash.Changeset.for_update(:remove_vote, %{
          proposal_id: proposal_id,
          persona_id: persona_id
        })
        |> Ash.update()

      assert [] == Scheduling.get_persona_votes(updated_scheduling, persona_id)
    end

    test "Owner removes a proposal (e.g., no longer viable)", %{
      episode: episode,
      owner: owner,
      participants: participants
    } do
      # SETUP (use generators!!)
      # Step 1: Create scheduling with proposed datetimes
      owner_id = owner.id
      participant_ids = Enum.map(participants, & &1.id)

      {:ok, scheduling} =
        Scheduling
        |> Ash.Changeset.for_create(:create, %{
          episode_id: episode.id,
          owner_persona_id: owner_id,
          participant_persona_ids: participant_ids,
          proposed_datetimes: [
            ~U[2024-03-15 14:00:00Z],
            ~U[2024-03-16 10:00:00Z],
            ~U[2024-03-17 15:00:00Z]
          ]
        })
        |> Ash.create()

      # Step 2: Participants vote on proposals
      [proposal1, proposal2, _proposal3] = scheduling.proposals

      # First participant votes
      {:ok, scheduling} =
        scheduling
        |> Ash.Changeset.for_update(:vote, %{
          proposal_id: proposal1["id"],
          persona_id: Enum.at(participant_ids, 0),
          score: 5,
          comment: "Perfect time for me!"
        })
        |> Ash.update()

      # Second participant votes
      {:ok, scheduling} =
        scheduling
        |> Ash.Changeset.for_update(:vote, %{
          proposal_id: proposal1["id"],
          persona_id: Enum.at(participant_ids, 1),
          score: 4
        })
        |> Ash.update()

      # Third participant prefers another time
      {:ok, scheduling} =
        scheduling
        |> Ash.Changeset.for_update(:vote, %{
          proposal_id: proposal2["id"],
          persona_id: Enum.at(participant_ids, 2),
          score: 5
        })
        |> Ash.update()

      proposal_id = proposal1["id"]
      # persona_id = Enum.at(participant_ids, 0)

      assert %{"id" => ^proposal_id} = Scheduling.get_proposal(scheduling, proposal_id)

      {:ok, updated_scheduling} =
        scheduling
        |> Ash.Changeset.for_update(:remove_proposal, %{
          proposal_id: proposal_id,
          persona_id: owner_id
        })
        |> Ash.update()

      assert is_nil(Scheduling.get_proposal(updated_scheduling, proposal_id))
    end

    test "If the chosen time no longer works, the owner can reopen voting", %{
      episode: episode,
      owner: owner,
      participants: participants
    } do
      # SETUP (use generators!!)
      # Step 1: Create scheduling with proposed datetimes
      owner_id = owner.id
      participant_ids = Enum.map(participants, & &1.id)

      {:ok, scheduling} =
        Scheduling
        |> Ash.Changeset.for_create(:create, %{
          episode_id: episode.id,
          owner_persona_id: owner_id,
          participant_persona_ids: participant_ids,
          proposed_datetimes: [
            ~U[2024-03-15 14:00:00Z],
            ~U[2024-03-16 10:00:00Z],
            ~U[2024-03-17 15:00:00Z]
          ]
        })
        |> Ash.create()

      # Step 2: Participants vote on proposals
      [proposal1, proposal2, _proposal3] = scheduling.proposals

      # First participant votes
      {:ok, scheduling} =
        scheduling
        |> Ash.Changeset.for_update(:vote, %{
          proposal_id: proposal1["id"],
          persona_id: Enum.at(participant_ids, 0),
          score: 5,
          comment: "Perfect time for me!"
        })
        |> Ash.update()

      # Second participant votes
      {:ok, scheduling} =
        scheduling
        |> Ash.Changeset.for_update(:vote, %{
          proposal_id: proposal1["id"],
          persona_id: Enum.at(participant_ids, 1),
          score: 4
        })
        |> Ash.update()

      # Third participant prefers another time
      {:ok, scheduling} =
        scheduling
        |> Ash.Changeset.for_update(:vote, %{
          proposal_id: proposal2["id"],
          persona_id: Enum.at(participant_ids, 2),
          score: 5
        })
        |> Ash.update()

      # Example 7: Reopen a closed scheduling
      # If the chosen time no longer works, the owner can reopen voting.
      # proposal_id = proposal1["id"]
      # persona_id = Enum.at(participant_ids, 0)

      stats = Scheduling.voting_stats(scheduling)
      top_proposal = List.first(stats.proposal_stats)

      {:ok, scheduling} =
        scheduling
        |> Ash.Changeset.for_update(:finalize, %{
          chosen_proposal_id: top_proposal.proposal_id,
          persona_id: owner_id
        })
        |> Ash.update()

      {:ok, episode} =
        episode
        |> Ash.Changeset.for_update(:finalize_scheduling, %{
          publication_date: scheduling.chosen_datetime
        })
        |> Ash.update()

      assert :closed == scheduling.status
      refute is_nil(scheduling.chosen_proposal_id)
      assert :scheduled == episode.state

      {:ok, reopened_scheduling} =
        scheduling
        |> Ash.Changeset.for_update(:reopen, %{
          persona_id: owner_id
        })
        |> Ash.update()

      # Also revert episode back to scheduling state
      episode = Ash.get!(Episode, scheduling.episode_id)

      {:ok, episode} =
        episode
        |> Ash.Changeset.for_update(:back_to_scheduling, %{})
        |> Ash.update()

      assert :scheduling == episode.state
      assert is_nil(reopened_scheduling.chosen_proposal_id)
      assert :open == reopened_scheduling.status
    end

    # @doc """
    # Example 7: Reopen a closed scheduling

    # If the chosen time no longer works, the owner can reopen voting.
    # """
    # def reopen_scheduling_example(scheduling, owner_id) do
    #   {:ok, reopened_scheduling} =
    #     scheduling
    #     |> Ash.Changeset.for_update(:reopen, %{
    #       persona_id: owner_id
    #     })
    #     |> Ash.update()

    #   IO.puts("Scheduling reopened for new votes")

    #   # Also revert episode back to scheduling state
    #   episode = Ash.get!(Episode, scheduling.episode_id)

    #   {:ok, episode} =
    #     episode
    #     |> Ash.Changeset.for_update(:back_to_scheduling, %{})
    #     |> Ash.update()

    #   {:ok, episode, reopened_scheduling}
    # end

    @doc """
    Example 8: Get all votes from a specific participant

    Shows all the votes a participant has cast across all proposals.
    """
    def get_participant_votes_example(scheduling, persona_id) do
      votes = Scheduling.get_persona_votes(scheduling, persona_id)

      IO.puts("\n=== Votes from Participant ===")

      if Enum.empty?(votes) do
        IO.puts("No votes yet")
      else
        Enum.each(votes, fn {proposal_id, vote} ->
          _proposal = Scheduling.get_proposal(scheduling, proposal_id)
          _score = vote["score"] || vote.score
          _comment = vote["comment"] || vote.comment

          # IO.puts("Proposal: #{Calendar.strftime(proposal["datetime"], "%B %d, %Y at %I:%M %p")}")
          # IO.puts("Score: #{score}/5")
          # if comment, do: IO.puts("Comment: #{comment}")
          # IO.puts("")
        end)
      end

      votes
    end

    @doc """
    Example 9: Find best time slot based on voting

    Returns the proposal with the highest average score.
    """
    def find_best_timeslot(scheduling) do
      stats = Scheduling.voting_stats(scheduling)

      case stats.top_proposal do
        nil ->
          IO.puts("No votes yet, cannot determine best timeslot")
          {:error, :no_votes}

        top_proposal ->
          IO.puts("\n=== Best Timeslot ===")

          IO.puts(
            "DateTime: #{Calendar.strftime(top_proposal.datetime, "%B %d, %Y at %I:%M %p UTC")}"
          )

          IO.puts("Average Score: #{top_proposal.average_score}/5.0")
          IO.puts("Total Votes: #{top_proposal.vote_count}")

          {:ok, top_proposal}
      end
    end

    test "Complete workflow with error handling", %{
      episode: episode,
      owner: owner,
      participants: participants
    } do
      owner_id = owner.id
      participant_ids = Enum.map(participants, & &1.id)
      # Start scheduling
      result =
        Scheduling
        |> Ash.Changeset.for_create(:create, %{
          episode_id: episode.id,
          owner_persona_id: owner_id,
          participant_persona_ids: participant_ids,
          proposed_datetimes: [
            ~U[2024-03-15 14:00:00Z],
            ~U[2024-03-16 10:00:00Z]
          ]
        })
        |> Ash.create()

      case result do
        {:ok, scheduling} ->
          # Simulate voting
          scheduling = simulate_voting(scheduling, participant_ids)

          # Monitor progress
          stats = monitor_voting_progress(scheduling)

          # Finalize if all voted
          if stats.all_voted? do
            finalize_scheduling(scheduling, owner_id, episode)
          else
            {:ok, :waiting_for_votes, scheduling}
          end

        {:error, changeset} ->
          IO.puts("✗ Failed to create scheduling:")
          # IO.inspect(changeset.errors)
          {:error, changeset}
      end
    end

    # Shows how to check if all participants have voted and display
    # current voting status.
    defp monitor_voting_progress(scheduling) do
      stats = Scheduling.voting_stats(scheduling)

      # IO.puts("\n=== Voting Progress ===")
      # IO.puts("Status: #{stats.status}")
      # IO.puts("Participants: #{stats.voted_participant_count}/#{stats.participant_count}")
      # IO.puts("All voted?: #{stats.all_voted?}")
      # IO.puts("Total votes: #{stats.total_votes}")
      # IO.puts("\n=== Proposal Rankings ===")

      stats.proposal_stats
      |> Enum.with_index(1)
      |> Enum.each(fn {proposal, _rank} ->
        IO.puts(
          "   Votes: #{proposal.vote_count}, Average Score: #{proposal.average_score || "N/A"}"
        )
      end)

      if stats.all_voted? do
        IO.puts("\n✓ All participants have voted! Ready to finalize.")
      else
        IO.puts(
          "\n⏳ Waiting for #{stats.participant_count - stats.voted_participant_count} more vote(s)."
        )
      end

      stats
    end

    defp simulate_voting(scheduling, participant_ids) do
      # Each participant votes on a random proposal
      Enum.reduce(participant_ids, scheduling, fn persona_id, acc ->
        proposal = Enum.random(acc.proposals)
        # Simulate positive votes
        score = Enum.random(3..5)

        {:ok, updated} =
          acc
          |> Ash.Changeset.for_update(:vote, %{
            proposal_id: proposal["id"],
            persona_id: persona_id,
            score: score
          })
          |> Ash.update()

        updated
      end)
    end

    defp finalize_scheduling(scheduling, owner_id, episode) do
      stats = Scheduling.voting_stats(scheduling)
      top_proposal = List.first(stats.proposal_stats)

      {:ok, scheduling} =
        scheduling
        |> Ash.Changeset.for_update(:finalize, %{
          chosen_proposal_id: top_proposal.proposal_id,
          persona_id: owner_id
        })
        |> Ash.update()

      {:ok, episode} =
        episode
        |> Ash.Changeset.for_update(:finalize_scheduling, %{
          publication_date: scheduling.chosen_datetime
        })
        |> Ash.update()

      IO.puts("✓ Scheduling finalized!")

      IO.puts(
        "  Chosen datetime: #{Calendar.strftime(scheduling.chosen_datetime, "%B %d, %Y at %I:%M %p UTC")}"
      )

      {:ok, :finalized, episode, scheduling}
    end
  end
end
