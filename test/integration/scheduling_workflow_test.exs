defmodule Radiator.SchedulingWorkflowTest do
  use Radiator.DataCase, async: true
  # @moduledoc """
  # Examples and usage patterns for the Episode Scheduling system.

  # This module provides practical examples of how to use the scheduling
  # functionality for coordinating episode recording times with participants.
  # """

  alias Radiator.Accounts.User
  alias Radiator.Podcasts
  alias Radiator.Podcasts.Episode
  alias Radiator.Podcasts.Episode.Scheduling

  describe "Scheduling integration roudtrip" do
    setup do
      {:ok, podcast} = Podcasts.create_podcast(%{title: "Test Podcast"})
      {:ok, episode} = Podcasts.create_episode(%{title: "Test Episode", podcast_id: podcast.id})

      owner = generate(user(%{handle: "owner"}))
      guest1 = generate(user(%{handle: "guest1"}))
      guest2 = generate(user(%{handle: "guest2"}))
      guest3 = generate(user(%{handle: "guest3"}))

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

      relate_participants!(episode, [owner | participants])

      # Step 1: Create scheduling with proposed datetimes
      {:ok, scheduling} =
        Scheduling
        |> Ash.Changeset.for_create(:create, %{
          episode_id: episode.id,
          owner_user_id: owner_id,
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
        do_vote(scheduling, proposal1.id, Enum.at(participant_ids, 0), 1, %{
          comment: "Perfect time for me!"
        })

      # Second participant votes
      {:ok, scheduling} =
        do_vote(scheduling, proposal1.id, Enum.at(participant_ids, 1), 1)

      # Third participant prefers another time
      {:ok, scheduling} =
        do_vote(scheduling, proposal2.id, Enum.at(participant_ids, 2), 1)

      # Step 3: Check voting statistics
      stats = Scheduling.voting_stats(scheduling, participant_ids)
      # IO.inspect(stats, label: "Voting Statistics")

      # Step 4: Owner finalizes with the winning proposal
      top_proposal = List.first(stats.proposal_stats)

      {:ok, scheduling} =
        scheduling
        |> Ash.Changeset.for_update(
          :finalize,
          %{
            chosen_proposal_id: top_proposal.proposal_id,
            user_id: owner_id
          },
          actor: owner
        )
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
      {:ok, podcast} = Podcasts.create_podcast(%{title: "Test Podcast"})
      {:ok, episode} = Podcasts.create_episode(%{title: "Test Episode", podcast_id: podcast.id})

      owner = generate(user(%{handle: "owner"}))
      guest1 = generate(user(%{handle: "guest1"}))
      guest2 = generate(user(%{handle: "guest2"}))
      guest3 = generate(user(%{handle: "guest3"}))

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

      orig_score = 1
      new_score = -1

      relate_participants!(episode, [owner | participants])

      # SETUP
      # Step 1: Create scheduling with proposed datetimes
      {:ok, scheduling} =
        Scheduling
        |> Ash.Changeset.for_create(:create, %{
          episode_id: episode.id,
          owner_user_id: owner_id,
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
        do_vote(scheduling, proposal1.id, Enum.at(participant_ids, 0), orig_score, %{
          comment: "Perfect time for me!"
        })

      # Second participant votes
      {:ok, scheduling} =
        do_vote(scheduling, proposal1.id, Enum.at(participant_ids, 1), 1)

      # Third participant prefers another time
      {:ok, scheduling} =
        do_vote(scheduling, proposal2.id, Enum.at(participant_ids, 2), 1)

      # Example 4: Change vote (participant changes their mind)
      # A participant can change their vote by voting again with a different score.

      proposal_id = proposal1.id
      user_id = Enum.at(participant_ids, 0)

      # Check if user has already voted
      assert Scheduling.voted_on_proposal?(scheduling, proposal_id, user_id)

      {:ok, updated_scheduling} =
        do_vote(scheduling, proposal_id, user_id, new_score, %{
          comment: "Changed my mind after checking my calendar"
        })

      assert Enum.count(scheduling.proposals) == Enum.count(updated_scheduling.proposals)
    end

    test "Participant removes their vote", %{
      episode: episode,
      owner: owner,
      participants: participants
    } do
      # SETUP
      # Step 1: Create scheduling with proposed datetimes
      owner_id = owner.id
      participant_ids = Enum.map(participants, & &1.id)

      relate_participants!(episode, [owner | participants])

      {:ok, scheduling} =
        Scheduling
        |> Ash.Changeset.for_create(:create, %{
          episode_id: episode.id,
          owner_user_id: owner_id,
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
        do_vote(scheduling, proposal1.id, Enum.at(participant_ids, 0), 1, %{
          comment: "Perfect time for me!"
        })

      # Second participant votes
      {:ok, scheduling} =
        do_vote(scheduling, proposal1.id, Enum.at(participant_ids, 1), 1)

      # Third participant prefers another time
      {:ok, scheduling} =
        do_vote(scheduling, proposal2.id, Enum.at(participant_ids, 2), 1)

      # Example 5: Participant removes their vote
      proposal_id = proposal1.id
      user_id = Enum.at(participant_ids, 0)

      [{_id, vote}] = Scheduling.get_user_votes(scheduling, user_id)
      assert user_id == vote.user_id

      {:ok, updated_scheduling} =
        scheduling
        |> Ash.Changeset.for_update(
          :remove_vote,
          %{
            proposal_id: proposal_id,
            user_id: user_id
          },
          actor: actor_for_user_id(user_id)
        )
        |> Ash.update()

      assert [] == Scheduling.get_user_votes(updated_scheduling, user_id)
    end

    test "Owner removes a proposal (e.g., no longer viable)", %{
      episode: episode,
      owner: owner,
      participants: participants
    } do
      # SETUP
      # Step 1: Create scheduling with proposed datetimes
      owner_id = owner.id
      participant_ids = Enum.map(participants, & &1.id)

      relate_participants!(episode, [owner | participants])

      {:ok, scheduling} =
        Scheduling
        |> Ash.Changeset.for_create(:create, %{
          episode_id: episode.id,
          owner_user_id: owner_id,
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
        do_vote(scheduling, proposal1.id, Enum.at(participant_ids, 0), 1, %{
          comment: "Perfect time for me!"
        })

      # Second participant votes
      {:ok, scheduling} =
        do_vote(scheduling, proposal1.id, Enum.at(participant_ids, 1), 1)

      # Third participant prefers another time
      {:ok, scheduling} =
        do_vote(scheduling, proposal2.id, Enum.at(participant_ids, 2), 1)

      proposal_id = proposal1.id

      assert %{id: ^proposal_id} = Scheduling.get_proposal(scheduling, proposal_id)

      {:ok, updated_scheduling} =
        scheduling
        |> Ash.Changeset.for_update(
          :remove_proposal,
          %{
            proposal_id: proposal_id,
            user_id: owner_id
          },
          actor: owner
        )
        |> Ash.update()

      assert is_nil(Scheduling.get_proposal(updated_scheduling, proposal_id))
    end

    test "If the chosen time no longer works, the owner can reopen voting", %{
      episode: episode,
      owner: owner,
      participants: participants
    } do
      # SETUP
      # Step 1: Create scheduling with proposed datetimes
      owner_id = owner.id
      participant_ids = Enum.map(participants, & &1.id)

      relate_participants!(episode, [owner | participants])

      {:ok, scheduling} =
        Scheduling
        |> Ash.Changeset.for_create(:create, %{
          episode_id: episode.id,
          owner_user_id: owner_id,
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
        do_vote(scheduling, proposal1.id, Enum.at(participant_ids, 0), 1, %{
          comment: "Perfect time for me!"
        })

      # Second participant votes
      {:ok, scheduling} =
        do_vote(scheduling, proposal1.id, Enum.at(participant_ids, 1), 1)

      # Third participant prefers another time
      {:ok, scheduling} =
        do_vote(scheduling, proposal2.id, Enum.at(participant_ids, 2), 1)

      # Example 7: Reopen a closed scheduling
      # If the chosen time no longer works, the owner can reopen voting.

      stats = Scheduling.voting_stats(scheduling, participant_ids)
      top_proposal = List.first(stats.proposal_stats)

      {:ok, scheduling} =
        scheduling
        |> Ash.Changeset.for_update(
          :finalize,
          %{
            chosen_proposal_id: top_proposal.proposal_id,
            user_id: owner_id
          },
          actor: owner
        )
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
        |> Ash.Changeset.for_update(
          :reopen,
          %{
            user_id: owner_id
          },
          actor: owner
        )
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

    test "Complete workflow with error handling", %{
      episode: episode,
      owner: owner,
      participants: participants
    } do
      owner_id = owner.id
      participant_ids = Enum.map(participants, & &1.id)

      relate_participants!(episode, [owner | participants])

      # Start scheduling
      result =
        Scheduling
        |> Ash.Changeset.for_create(:create, %{
          episode_id: episode.id,
          owner_user_id: owner_id,
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
          stats = monitor_voting_progress(scheduling, participant_ids)

          # Finalize if all voted
          if stats.all_voted? do
            finalize_scheduling(scheduling, owner, episode, participant_ids)
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
    defp monitor_voting_progress(scheduling, participant_ids) do
      stats = Scheduling.voting_stats(scheduling, participant_ids)

      # IO.puts("\n=== Voting Progress ===")
      # IO.puts("Status: #{stats.status}")
      # IO.puts("Participants: #{stats.voted_participant_count}/#{stats.participant_count}")
      # IO.puts("All voted?: #{stats.all_voted?}")
      # IO.puts("Total votes: #{stats.total_votes}")
      # IO.puts("\n=== Proposal Rankings ===")

      stats.proposal_stats
      |> Enum.with_index(1)
      |> Enum.each(fn {proposal, _rank} ->
        assert is_integer(proposal.total_score)
        assert is_integer(proposal.pending_count)
      end)

      # if stats.all_voted? do
      #   IO.puts("\n✓ All participants have voted! Ready to finalize.")
      # else
      #   IO.puts(
      #     "\n⏳ Waiting for #{stats.participant_count - stats.voted_participant_count} more vote(s)."
      #   )
      # end

      stats
    end

    defp simulate_voting(scheduling, participant_ids) do
      # Each participant votes on a random proposal
      Enum.reduce(participant_ids, scheduling, fn user_id, acc ->
        proposal = Enum.random(acc.proposals)
        # Pick any of the three valid availability states
        score = Enum.random([-1, 0, 1])

        {:ok, updated} = do_vote(acc, proposal.id, user_id, score)
        updated
      end)
    end

    defp finalize_scheduling(scheduling, owner, episode, participant_ids) do
      stats = Scheduling.voting_stats(scheduling, participant_ids)
      top_proposal = List.first(stats.proposal_stats)

      {:ok, scheduling} =
        scheduling
        |> Ash.Changeset.for_update(
          :finalize,
          %{
            chosen_proposal_id: top_proposal.proposal_id,
            user_id: owner.id
          },
          actor: owner
        )
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

  defp actor_for_user_id(user_id) do
    Ash.get!(User, user_id, authorize?: false)
  end

  defp relate_participants!(episode, users) do
    episode
    |> Ash.Changeset.for_update(
      :update,
      %{participants: Enum.map(users, &%{email: to_string(&1.email)})},
      authorize?: false
    )
    |> Ash.update!()
  end

  defp do_vote(scheduling, proposal_id, user_id, score, extra \\ %{}) do
    args = Map.merge(%{proposal_id: proposal_id, user_id: user_id, score: score}, extra)

    scheduling
    |> Ash.Changeset.for_update(:vote, args, actor: actor_for_user_id(user_id))
    |> Ash.update()
  end
end
