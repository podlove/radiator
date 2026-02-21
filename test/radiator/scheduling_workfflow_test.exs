defmodule Radiator.SchedulingWorkflowTest do
  use Radiator.DataCase, async: true
  # @moduledoc """
  # Examples and usage patterns for the Episode Scheduling system.

  # This module provides practical examples of how to use the scheduling
  # functionality for coordinating episode recording times with participants.
  # """

  alias Radiator.Podcasts
  alias Radiator.Podcasts.Episode
  alias Radiator.Podcasts.Episode.Scheduling

  describe "Scheduling integration roudtrip (mostly generated)" do
    setup do
      {:ok, podcast} = Podcasts.create_podcast(%{title: "Test Podcast"})
      {:ok, episode} = Podcasts.create_episode(%{title: "Test Episode", podcast_id: podcast.id})

      {:ok, owner} = Podcasts.create_persona(%{public_name: "Owner", handle: "owner"})
      {:ok, guest1} = Podcasts.create_persona(%{public_name: "Guest 1", handle: "guest1"})
      {:ok, guest2} = Podcasts.create_persona(%{public_name: "Guest 2", handle: "guest2"})
      {:ok, guest3} = Podcasts.create_persona(%{public_name: "Guest 3", handle: "guest3"})

      %{
        episode: episode,
        owner: owner,
        participants: [guest1, guest2, guest3]
      }
    end

    @doc """
    Example 1: Basic scheduling workflow

    Creates a scheduling, participants vote, and owner finalizes.
    """

    test "basic_workflow_example", %{
      episode: episode,
      owner: owner,
      participants: participants
    } do
      owner_id = get_owner_persona_id()
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
      IO.inspect(stats, label: "Voting Statistics")

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

    @doc """
    Example 2:
    """

    test "Participant adds a new proposal during voting", %{
      episode: episode,
      owner: owner,
      participants: participants
    } do
    end

    @doc """
    Example 3: Monitoring voting progress

    Shows how to check if all participants have voted and display
    current voting status.
    """
    def monitor_voting_progress(scheduling) do
      stats = Scheduling.voting_stats(scheduling)

      # IO.puts("\n=== Voting Progress ===")
      # IO.puts("Status: #{stats.status}")
      # IO.puts("Participants: #{stats.voted_participant_count}/#{stats.participant_count}")
      # IO.puts("All voted?: #{stats.all_voted?}")
      # IO.puts("Total votes: #{stats.total_votes}")
      # IO.puts("\n=== Proposal Rankings ===")

      stats.proposal_stats
      |> Enum.with_index(1)
      |> Enum.each(fn {proposal, rank} ->
        # IO.puts("#{rank}. #{Calendar.strftime(proposal.datetime, "%B %d, %Y at %I:%M %p UTC")}")

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

    @doc """
    Example 4: Change vote (participant changes their mind)

    A participant can change their vote by voting again with a different score.
    """
    def change_vote_example(scheduling, proposal_id, persona_id, new_score) do
      # Check if persona has already voted
      existing_vote =
        scheduling
        |> Scheduling.voted_on_proposal?(proposal_id, persona_id)

      if existing_vote do
        IO.puts("Changing existing vote to score: #{new_score}")
      else
        IO.puts("Casting new vote with score: #{new_score}")
      end

      {:ok, updated_scheduling} =
        scheduling
        |> Ash.Changeset.for_update(:vote, %{
          proposal_id: proposal_id,
          persona_id: persona_id,
          score: new_score,
          comment: "Changed my mind after checking my calendar"
        })
        |> Ash.update()

      {:ok, updated_scheduling}
    end

    @doc """
    Example 5: Participant removes their vote
    """
    def remove_vote_example(scheduling, proposal_id, persona_id) do
      {:ok, updated_scheduling} =
        scheduling
        |> Ash.Changeset.for_update(:remove_vote, %{
          proposal_id: proposal_id,
          persona_id: persona_id
        })
        |> Ash.update()

      IO.puts("Vote removed successfully")
      {:ok, updated_scheduling}
    end

    @doc """
    Example 6: Owner removes a proposal (e.g., no longer viable)
    """
    def remove_proposal_example(scheduling, proposal_id, owner_id) do
      {:ok, updated_scheduling} =
        scheduling
        |> Ash.Changeset.for_update(:remove_proposal, %{
          proposal_id: proposal_id,
          persona_id: owner_id
        })
        |> Ash.update()

      IO.puts("Proposal removed successfully")
      {:ok, updated_scheduling}
    end

    @doc """
    Example 7: Reopen a closed scheduling

    If the chosen time no longer works, the owner can reopen voting.
    """
    def reopen_scheduling_example(scheduling, owner_id) do
      {:ok, reopened_scheduling} =
        scheduling
        |> Ash.Changeset.for_update(:reopen, %{
          persona_id: owner_id
        })
        |> Ash.update()

      IO.puts("Scheduling reopened for new votes")

      # Also revert episode back to scheduling state
      episode = Ash.get!(Episode, scheduling.episode_id)

      {:ok, episode} =
        episode
        |> Ash.Changeset.for_update(:back_to_scheduling, %{})
        |> Ash.update()

      {:ok, episode, reopened_scheduling}
    end

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
          proposal = Scheduling.get_proposal(scheduling, proposal_id)
          score = vote["score"] || vote.score
          comment = vote["comment"] || vote.comment

          IO.puts("Proposal: #{Calendar.strftime(proposal["datetime"], "%B %d, %Y at %I:%M %p")}")
          IO.puts("Score: #{score}/5")
          if comment, do: IO.puts("Comment: #{comment}")
          IO.puts("")
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
      owner_id = get_owner_persona_id()
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
          IO.inspect(changeset.errors)
          {:error, changeset}
      end
    end

    # Private helper functions

    # defp create_test_episode do
    #   # This would use actual podcast data in production
    #   Podcasts.create_episode(%{
    #     title: "Test Episode for Scheduling",
    #     podcast_id: get_test_podcast_id()
    #   })
    # end

    # defp get_test_podcast_id do
    #   # Return first podcast or create one
    #   case Podcasts.read_podcasts() do
    #     {:ok, [podcast | _]} -> podcast.id
    #     _ -> raise "No podcasts found. Please create a podcast first."
    #   end
    # end

    defp get_owner_persona_id do
      {:ok, personas} = Radiator.Podcasts.read_personas()
      personas |> List.first() |> Map.get(:id)
    end

    # defp get_participant_persona_ids do
    #   Enum.reduce(1..5, [], fn _, acc ->
    #     {:ok, person} =
    #       Radiator.Podcasts.create_person(%{
    #         real_name: "Test Person #{System.unique_integer([:positive])}",
    #         nickname: "TestNick#{System.unique_integer([:positive])}",
    #         email: "test#{System.unique_integer([:positive])}@example.com",
    #         telephone: "+44123456#{System.unique_integer([:positive])}"
    #       })

    #     {:ok, persona} =
    #       Radiator.Podcasts.create_persona(%{
    #         person_id: person.id,
    #         public_name: "Test Persona #{System.unique_integer([:positive])}",
    #         handle: "test_handle_#{System.unique_integer([:positive])}",
    #         description: "Test description for persona",
    #         avatar_png: "https://example.com/avatar#{System.unique_integer([:positive])}.png"
    #       })

    #     [persona.id | acc]
    #   end)
    # end

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
