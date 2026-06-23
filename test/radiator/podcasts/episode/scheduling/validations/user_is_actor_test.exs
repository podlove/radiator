defmodule Radiator.Podcasts.Episode.Scheduling.Validations.UserIsActorTest do
  @moduledoc """
  Tests for the `UserIsActor` validation.

  These tests exercise the validation end-to-end via the `:vote` action, which
  is the realistic call site. The validation checks that the `user_id` argument
  equals the current actor's id.
  """
  use Radiator.DataCase, async: true

  alias Radiator.Podcasts.Episode.Scheduling

  defp setup_scheduling_with_voter do
    voter = build_user()
    other_participants = Enum.map(1..2, fn _ -> build_user() end)
    owner = build_user()
    episode = generate(episode())

    relate_participants!(episode, [voter | other_participants])

    {:ok, scheduling} =
      Scheduling
      |> Ash.Changeset.for_create(:create, %{
        episode_id: episode.id,
        owner_user_id: owner.id,
        proposed_datetimes: [~U[2026-04-15 10:00:00Z]]
      })
      |> Ash.create(authorize?: false)

    [proposal | _] = scheduling.proposals

    %{scheduling: scheduling, voter: voter, proposal: proposal}
  end

  defp build_user do
    generate(user())
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

  describe "UserIsActor via :vote action" do
    test "passes when user_id matches actor.id" do
      %{scheduling: scheduling, voter: voter, proposal: proposal} = setup_scheduling_with_voter()

      assert {:ok, updated} =
               Scheduling.vote(scheduling, proposal.id, voter.id, 1, actor: voter)

      [updated_proposal | _] = updated.proposals
      assert [%{user_id: uid, score: 1}] = updated_proposal.votes
      assert uid == voter.id
    end

    test "fails when actor is a different user than user_id" do
      other = build_user()
      %{scheduling: scheduling, voter: voter, proposal: proposal} = setup_scheduling_with_voter()

      assert {:error, %Ash.Error.Invalid{} = error} =
               Scheduling.vote(scheduling, proposal.id, voter.id, 1, actor: other)

      assert Exception.message(error) =~ "user does not match current actor"
    end

    test "fails when no actor is provided" do
      %{scheduling: scheduling, voter: voter, proposal: proposal} = setup_scheduling_with_voter()

      assert {:error, %Ash.Error.Invalid{} = error} =
               Scheduling.vote(scheduling, proposal.id, voter.id, 1)

      assert Exception.message(error) =~ "user does not match current actor"
    end

    test "fails when actor is something other than a User" do
      %{scheduling: scheduling, voter: voter, proposal: proposal} = setup_scheduling_with_voter()

      not_a_user = %{id: voter.id}

      assert {:error, %Ash.Error.Invalid{} = error} =
               Scheduling.vote(scheduling, proposal.id, voter.id, 1, actor: not_a_user)

      assert Exception.message(error) =~ "user does not match current actor"
    end
  end
end
