defmodule RadiatorWeb.Admin.EpisodeLive.SchedulingHelpersTest do
  use ExUnit.Case, async: true

  import RadiatorWeb.Admin.EpisodeLive.SchedulingHelpers

  alias Radiator.Podcasts.Episode.Scheduling
  alias Radiator.Podcasts.Episode.Scheduling.Proposal

  describe "timezone/1" do
    test "takes a known zone and falls back to Berlin" do
      assert timezone("America/New_York") == "America/New_York"
      assert timezone("Mars/Olympus_Mons") == "Europe/Berlin"
      assert timezone(nil) == "Europe/Berlin"
    end
  end

  describe "parse_local/2" do
    test "reads a datetime-local value in the zone and returns UTC" do
      assert parse_local("2026-11-06T19:00", "Europe/Berlin") == {:ok, ~U[2026-11-06 18:00:00Z]}
      assert parse_local("2026-07-06T19:00", "Europe/Berlin") == {:ok, ~U[2026-07-06 17:00:00Z]}
      assert parse_local("2026-07-06T19:00:30", "Etc/UTC") == {:ok, ~U[2026-07-06 19:00:30Z]}
    end

    test "moves a time skipped by the spring switch past the gap" do
      # 02:30 does not exist on 2026-03-29 in Berlin; 03:00 CEST is 01:00 UTC.
      assert parse_local("2026-03-29T02:30", "Europe/Berlin") == {:ok, ~U[2026-03-29 01:00:00Z]}
    end

    test "takes the first of a time that exists twice in autumn" do
      # 02:30 on 2026-10-25 exists in CEST (00:30 UTC) and CET (01:30 UTC).
      assert parse_local("2026-10-25T02:30", "Europe/Berlin") == {:ok, ~U[2026-10-25 00:30:00Z]}
    end

    test "rejects anything else" do
      assert parse_local("", "Europe/Berlin") == :error
      assert parse_local("tomorrow", "Europe/Berlin") == :error
      assert parse_local(nil, "Europe/Berlin") == :error
    end
  end

  test "local/2, weekday_label/1, weekend?/1, date/1 and time/1 show the zone's view" do
    sunday_night = local(~U[2026-11-08 23:30:00Z], "Europe/Berlin")

    assert weekday_label(sunday_night) == "Mo"
    refute weekend?(sunday_night)
    assert date(sunday_night) == "09.11.2026"
    assert time(sunday_night) == "00:30"
    assert weekend?(local(~U[2026-11-08 12:00:00Z], "Europe/Berlin"))
  end

  test "format_score/1 signs positive scores" do
    assert format_score(2) == "+2"
    assert format_score(0) == "0"
    assert format_score(-1) == "-1"
  end

  test "vote_button_class/2 colours the chosen answer only" do
    assert vote_button_class(1, 1) == "btn-success"
    assert vote_button_class(0, 0) == "btn-warning"
    assert vote_button_class(-1, -1) == "btn-error"
    assert vote_button_class(1, 0) == "btn-ghost"
    assert vote_button_class(nil, 1) == "btn-ghost"
  end

  describe "can_vote?/2 and can_remove?/4" do
    test "voting needs an open scheduling and an own person" do
      assert can_vote?(%Scheduling{status: :open}, "person")
      refute can_vote?(%Scheduling{status: :closed}, "person")
      refute can_vote?(%Scheduling{status: :open}, nil)
      refute can_vote?(nil, "person")
    end

    test "members remove any proposal, others only their own, nobody once closed" do
      open = %Scheduling{status: :open}
      theirs = %Proposal{created_by_user_id: "someone"}
      mine = %Proposal{created_by_user_id: "me"}
      me = %{id: "me"}

      assert can_remove?(open, theirs, me, true)
      assert can_remove?(open, mine, me, false)
      refute can_remove?(open, theirs, me, false)
      refute can_remove?(%Scheduling{status: :closed}, mine, me, true)
    end
  end
end
