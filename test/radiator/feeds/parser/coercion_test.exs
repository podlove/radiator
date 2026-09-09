defmodule Radiator.Feeds.Parser.CoercionTest do
  use ExUnit.Case, async: true

  alias Radiator.Feeds.Parser.Coercion

  describe "datetime/1" do
    test "reads RFC 2822 with a numeric zone" do
      assert Coercion.datetime("Fri, 28 Aug 2026 17:14:26 +0000") ==
               ~U[2026-08-28 17:14:26Z]
    end

    test "converts a zone offset to UTC" do
      assert Coercion.datetime("Thu, 27 Aug 2026 10:00:00 +0200") ==
               ~U[2026-08-27 08:00:00Z]
    end

    test "handles a negative zone offset" do
      assert Coercion.datetime("Thu, 27 Aug 2026 10:00:00 -0530") ==
               ~U[2026-08-27 15:30:00Z]
    end

    test "handles a missing day of the week" do
      assert Coercion.datetime("27 Aug 2026 10:00:00 +0000") == ~U[2026-08-27 10:00:00Z]
    end

    test "reads the zone abbreviations GMT and UT as UTC" do
      assert Coercion.datetime("Thu, 27 Aug 2026 10:00:00 GMT") == ~U[2026-08-27 10:00:00Z]
      assert Coercion.datetime("Thu, 27 Aug 2026 10:00:00 UT") == ~U[2026-08-27 10:00:00Z]
    end

    test "expands an obsolete two-digit year the way RFC 5322 prescribes" do
      assert Coercion.datetime("Fri, 28 Aug 26 17:14:26 +0000") == ~U[2026-08-28 17:14:26Z]
      assert Coercion.datetime("Wed, 15 Mar 95 10:00:00 +0000") == ~U[1995-03-15 10:00:00Z]
      assert Coercion.datetime("Wed, 15 Mar 995 10:00:00 +0000") == ~U[2895-03-15 10:00:00Z]
    end

    test "reads the north american zone abbreviations" do
      assert Coercion.datetime("Fri, 28 Aug 2026 17:14:26 EST") == ~U[2026-08-28 22:14:26Z]
      assert Coercion.datetime("Fri, 28 Aug 2026 17:14:26 PDT") == ~U[2026-08-29 00:14:26Z]
    end

    test "reads the central european zone abbreviations" do
      assert Coercion.datetime("Fri, 28 Aug 2026 17:14:26 CET") == ~U[2026-08-28 16:14:26Z]
      assert Coercion.datetime("Fri, 28 Aug 2026 17:14:26 CEST") == ~U[2026-08-28 15:14:26Z]
    end

    test "falls back to UTC for an unknown alphabetic zone rather than dropping the date" do
      assert Coercion.datetime("Fri, 28 Aug 2026 17:14:26 XYZ") == ~U[2026-08-28 17:14:26Z]
    end

    test "returns nil for nonsense and for nil" do
      assert Coercion.datetime("gestern") == nil
      assert Coercion.datetime("") == nil
      assert Coercion.datetime(nil) == nil
      assert Coercion.datetime("Fri, 28 Aug 2026 17:14:26 +2") == nil
    end
  end

  describe "duration_seconds/1" do
    test "reads plain seconds" do
      assert Coercion.duration_seconds("3600") == 3600
    end

    test "reads H:MM:SS" do
      assert Coercion.duration_seconds("1:02:03") == 3723
    end

    test "reads HH:MM:SS with a leading zero" do
      assert Coercion.duration_seconds("01:02:03") == 3723
    end

    test "reads MM:SS" do
      assert Coercion.duration_seconds("02:03") == 123
    end

    test "truncates fractional seconds" do
      assert Coercion.duration_seconds("1:00:00.500") == 3600
    end

    test "returns nil for nonsense and for nil" do
      assert Coercion.duration_seconds("lang") == nil
      assert Coercion.duration_seconds(nil) == nil
    end
  end

  describe "npt_ms/1" do
    test "reads milliseconds from an NPT time" do
      assert Coercion.npt_ms("00:12:34.567") == 754_567
    end

    test "handles a missing fraction" do
      assert Coercion.npt_ms("00:00:10") == 10_000
    end

    test "handles a two-digit fraction" do
      assert Coercion.npt_ms("00:00:01.25") == 1250
    end

    test "returns nil for nonsense and for nil" do
      assert Coercion.npt_ms("anfang") == nil
      assert Coercion.npt_ms(nil) == nil
    end
  end

  describe "boolean/1" do
    test "recognises every truthy spelling" do
      for value <- ~w(yes Yes YES true True TRUE) do
        assert Coercion.boolean(value) == true, "#{value} should be true"
      end
    end

    test "recognises every falsy spelling" do
      for value <- ~w(no No NO false False FALSE) do
        assert Coercion.boolean(value) == false, "#{value} should be false"
      end
    end

    test "returns nil for unknown values and for nil" do
      assert Coercion.boolean("vielleicht") == nil
      assert Coercion.boolean(nil) == nil
    end
  end

  describe "integer/1" do
    test "reads a number and ignores surrounding whitespace" do
      assert Coercion.integer(" 42 ") == 42
    end

    test "returns nil for nonsense and for nil" do
      assert Coercion.integer("zwölf") == nil
      assert Coercion.integer(nil) == nil
    end
  end
end
