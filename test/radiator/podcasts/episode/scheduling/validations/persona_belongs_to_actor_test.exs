defmodule Radiator.Podcasts.Episode.Scheduling.Validations.PersonaBelongsToActorTest do
  @moduledoc """
  Tests for the `PersonaBelongsToActor` validation.

  These tests exercise the validation end-to-end via the `:vote` action, which
  is the realistic call site. The validation performs a database lookup so
  testing through the action covers the actor / persona / db_lookup loop.
  """
  use Radiator.DataCase, async: true

  alias Radiator.Accounts.User
  alias Radiator.Podcasts.Episode.Scheduling

  defp create_user do
    email = "user_#{System.unique_integer([:positive])}@example.com"
    {:ok, hashed_password} = AshAuthentication.BcryptProvider.hash("supersupersecret")
    Ash.Seed.seed!(User, %{email: email, hashed_password: hashed_password})
  end

  defp setup_scheduling_with_voter(opts) do
    voter_user_id = Keyword.get(opts, :voter_user_id, nil)

    voter =
      generate(persona(%{user_id: voter_user_id}))

    other_participants =
      Enum.map(1..2, fn _ -> generate(persona()) end)

    owner = generate(persona())
    episode = generate(episode())

    {:ok, scheduling} =
      Scheduling
      |> Ash.Changeset.for_create(:create, %{
        episode_id: episode.id,
        owner_persona_id: owner.id,
        participant_persona_ids: [voter.id | Enum.map(other_participants, & &1.id)],
        proposed_datetimes: [~U[2026-04-15 10:00:00Z]]
      })
      |> Ash.create(authorize?: false)

    [proposal | _] = scheduling.proposals

    %{scheduling: scheduling, voter: voter, proposal: proposal}
  end

  describe "PersonaBelongsToActor via :vote action" do
    test "passes when persona.user_id matches actor.id" do
      user = create_user()

      %{scheduling: scheduling, voter: voter, proposal: proposal} =
        setup_scheduling_with_voter(voter_user_id: user.id)

      assert {:ok, updated} =
               Scheduling.vote(scheduling, proposal.id, voter.id, 1, actor: user)

      [updated_proposal | _] = updated.proposals
      assert [%{persona_id: pid, score: 1}] = updated_proposal.votes
      assert pid == voter.id
    end

    test "fails when actor is a different user than persona.user_id" do
      user_a = create_user()
      user_b = create_user()

      %{scheduling: scheduling, voter: voter, proposal: proposal} =
        setup_scheduling_with_voter(voter_user_id: user_a.id)

      assert {:error, %Ash.Error.Invalid{} = error} =
               Scheduling.vote(scheduling, proposal.id, voter.id, 1, actor: user_b)

      assert Exception.message(error) =~ "persona does not belong to current user"
    end

    test "fails when persona has no linked user (user_id is nil)" do
      user = create_user()

      %{scheduling: scheduling, voter: voter, proposal: proposal} =
        setup_scheduling_with_voter(voter_user_id: nil)

      assert {:error, %Ash.Error.Invalid{} = error} =
               Scheduling.vote(scheduling, proposal.id, voter.id, 1, actor: user)

      assert Exception.message(error) =~ "persona does not belong to current user"
    end

    test "fails when no actor is provided" do
      %{scheduling: scheduling, voter: voter, proposal: proposal} =
        setup_scheduling_with_voter(voter_user_id: nil)

      assert {:error, %Ash.Error.Invalid{} = error} =
               Scheduling.vote(scheduling, proposal.id, voter.id, 1)

      assert Exception.message(error) =~ "persona does not belong to current user"
    end

    test "fails when actor is something other than a User" do
      user = create_user()

      %{scheduling: scheduling, voter: voter, proposal: proposal} =
        setup_scheduling_with_voter(voter_user_id: user.id)

      not_a_user = %{id: user.id}

      assert {:error, %Ash.Error.Invalid{} = error} =
               Scheduling.vote(scheduling, proposal.id, voter.id, 1, actor: not_a_user)

      assert Exception.message(error) =~ "persona does not belong to current user"
    end
  end
end
