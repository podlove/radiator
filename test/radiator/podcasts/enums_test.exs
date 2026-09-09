defmodule Radiator.Podcasts.EnumsTest do
  use ExUnit.Case, async: true

  alias Radiator.Podcasts.EpisodeType
  alias Radiator.Podcasts.PodcastType
  alias Radiator.Podcasts.SyncStatus
  alias Radiator.Podcasts.SyncStrategy

  test "SyncStrategy knows exactly two values" do
    assert SyncStrategy.values() == [:manual, :scheduled]
  end

  test "SyncStatus starts out at idle" do
    assert SyncStatus.values() == [:idle, :pending, :succeeded, :failed]
  end

  test "PodcastType and EpisodeType mirror the itunes values" do
    assert PodcastType.values() == [:episodic, :serial]
    assert EpisodeType.values() == [:full, :trailer, :bonus]
  end

  test "options/0 returns label/value pairs for form selects" do
    assert SyncStrategy.options() == [
             {"Nur einmaliger Import", :manual},
             {"Regelmäßiger Sync", :scheduled}
           ]
  end

  test "known values cast, unknown ones do not" do
    assert {:ok, :scheduled} = Ash.Type.cast_input(SyncStrategy, "scheduled")
    assert {:error, _} = Ash.Type.cast_input(SyncStrategy, "sometimes")
  end
end
