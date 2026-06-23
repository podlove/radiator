defmodule RadiatorWeb.Admin.Episodes.AvailabilityHelpersTest do
  use ExUnit.Case, async: true

  alias Radiator.Podcasts.Episode.Scheduling
  alias RadiatorWeb.Admin.Episodes.AvailabilityHelpers

  describe "can_vote?/2" do
    test "returns false when user is nil" do
      scheduling = %Scheduling{status: :open, participant_user_ids: ["any"]}

      refute AvailabilityHelpers.can_vote?(scheduling, nil)
    end

    test "returns false when scheduling is nil" do
      refute AvailabilityHelpers.can_vote?(nil, %{id: "any"})
    end

    test "returns true when scheduling is :open and user is a participant" do
      scheduling = %Scheduling{
        status: :open,
        participant_user_ids: ["bob-id", "alice-id"]
      }

      assert AvailabilityHelpers.can_vote?(scheduling, %{id: "bob-id"})
    end

    test "returns false when scheduling is :open and user is not a participant" do
      scheduling = %Scheduling{
        status: :open,
        participant_user_ids: ["alice-id"]
      }

      refute AvailabilityHelpers.can_vote?(scheduling, %{id: "bob-id"})
    end

    test "returns false when scheduling is :closed even if user is a participant" do
      scheduling = %Scheduling{
        status: :closed,
        participant_user_ids: ["bob-id"]
      }

      refute AvailabilityHelpers.can_vote?(scheduling, %{id: "bob-id"})
    end
  end

  describe "winner_proposal_id/2" do
    test "returns top_proposal_id when scheduling is :open" do
      scheduling = %Scheduling{status: :open, chosen_proposal_id: nil}

      assert AvailabilityHelpers.winner_proposal_id(scheduling, "top-id") == "top-id"
    end

    test "returns top_proposal_id when :open even if chosen_proposal_id is set" do
      scheduling = %Scheduling{status: :open, chosen_proposal_id: "ignored-id"}

      assert AvailabilityHelpers.winner_proposal_id(scheduling, "top-id") == "top-id"
    end

    test "returns chosen_proposal_id when :closed and chosen_proposal_id is set" do
      scheduling = %Scheduling{status: :closed, chosen_proposal_id: "chosen-id"}

      assert AvailabilityHelpers.winner_proposal_id(scheduling, "top-id") == "chosen-id"
    end

    test "owner's choice beats automatic ranking when :closed" do
      scheduling = %Scheduling{status: :closed, chosen_proposal_id: "chosen-id"}

      assert AvailabilityHelpers.winner_proposal_id(scheduling, "different-top-id") ==
               "chosen-id"
    end

    test "returns nil when :closed without chosen_proposal_id" do
      scheduling = %Scheduling{status: :closed, chosen_proposal_id: nil}

      assert AvailabilityHelpers.winner_proposal_id(scheduling, nil) == nil
    end

    test "returns nil when :closed without chosen_proposal_id even if top_proposal_id is set" do
      scheduling = %Scheduling{status: :closed, chosen_proposal_id: nil}

      assert AvailabilityHelpers.winner_proposal_id(scheduling, "some-top-id") == nil
    end

    test "returns nil when scheduling is nil" do
      assert AvailabilityHelpers.winner_proposal_id(nil, "top-id") == nil
    end
  end
end
