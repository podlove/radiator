defmodule RadiatorWeb.Admin.Episodes.AvailabilityHelpersTest do
  use ExUnit.Case, async: true

  alias Radiator.Podcasts.Episode.Scheduling
  alias RadiatorWeb.Admin.Episodes.AvailabilityHelpers

  describe "can_vote?/3" do
    test "returns false when user is nil" do
      scheduling = %Scheduling{status: :open}

      refute AvailabilityHelpers.can_vote?(scheduling, nil, ["any"])
    end

    test "returns false when scheduling is nil" do
      refute AvailabilityHelpers.can_vote?(nil, %{id: "any"}, ["any"])
    end

    test "returns true when scheduling is :open and user is a participant" do
      scheduling = %Scheduling{status: :open}

      assert AvailabilityHelpers.can_vote?(scheduling, %{id: "bob-id"}, ["bob-id", "alice-id"])
    end

    test "returns false when scheduling is :open and user is not a participant" do
      scheduling = %Scheduling{status: :open}

      refute AvailabilityHelpers.can_vote?(scheduling, %{id: "bob-id"}, ["alice-id"])
    end

    test "returns false when scheduling is :closed even if user is a participant" do
      scheduling = %Scheduling{status: :closed}

      refute AvailabilityHelpers.can_vote?(scheduling, %{id: "bob-id"}, ["bob-id"])
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

  describe "owner?/2" do
    test "returns false when scheduling is nil" do
      refute AvailabilityHelpers.owner?(nil, %{id: "u1"})
    end

    test "returns false when user is nil" do
      refute AvailabilityHelpers.owner?(%Scheduling{owner_user_id: "u1"}, nil)
    end

    test "returns true when the user id matches owner_user_id" do
      assert AvailabilityHelpers.owner?(%Scheduling{owner_user_id: "u1"}, %{id: "u1"})
    end

    test "returns false when the user id differs from owner_user_id" do
      refute AvailabilityHelpers.owner?(%Scheduling{owner_user_id: "u1"}, %{id: "u2"})
    end
  end

  describe "format_datetime_de/1 and proposal_option_label/1" do
    test "formats a datetime as German weekday + date + time" do
      assert AvailabilityHelpers.format_datetime_de(~U[2026-04-18 22:00:00Z]) ==
               "Sa 18.04.2026, 22:00"
    end

    test "proposal_option_label uses the German datetime format" do
      proposal = %{datetime: ~U[2026-04-18 22:00:00Z]}
      assert AvailabilityHelpers.proposal_option_label(proposal) == "Sa 18.04.2026, 22:00"
    end
  end
end
