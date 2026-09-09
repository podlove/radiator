defmodule RadiatorWeb.FormattingTest do
  use ExUnit.Case, async: true

  alias RadiatorWeb.Formatting

  @now ~U[2026-09-09 12:00:00Z]

  describe "relative_time/2" do
    test "just now" do
      assert Formatting.relative_time(~U[2026-09-09 11:59:40Z], @now) == "gerade eben"
    end

    test "minutes" do
      assert Formatting.relative_time(~U[2026-09-09 11:55:00Z], @now) == "vor 5 Minuten"
      assert Formatting.relative_time(~U[2026-09-09 11:59:00Z], @now) == "vor 1 Minute"
    end

    test "hours" do
      assert Formatting.relative_time(~U[2026-09-09 10:00:00Z], @now) == "vor 2 Stunden"
      assert Formatting.relative_time(~U[2026-09-09 11:00:00Z], @now) == "vor 1 Stunde"
    end

    test "days" do
      assert Formatting.relative_time(~U[2026-09-06 12:00:00Z], @now) == "vor 3 Tagen"
      assert Formatting.relative_time(~U[2026-09-08 12:00:00Z], @now) == "vor 1 Tag"
    end

    test "older than a week falls back to the date" do
      assert Formatting.relative_time(~U[2026-08-01 12:00:00Z], @now) == "am 01.08.2026"
    end
  end

  describe "duration/1" do
    test "hours, minutes and seconds" do
      assert Formatting.duration(3723) == "1:02:03"
    end

    test "under an hour" do
      assert Formatting.duration(65) == "1:05"
    end

    test "nil stays nil" do
      assert Formatting.duration(nil) == nil
    end
  end
end
