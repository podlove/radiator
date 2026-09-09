defmodule Radiator.Feeds.FullFeedTest do
  @moduledoc false
  use ExUnit.Case, async: true

  alias Radiator.Feeds.Parser

  @path Path.join(File.cwd!(), "feed.xml")

  # The sample feed is gitignored, so it is absent on a fresh clone and in CI.
  # Reporting that as skipped rather than failed keeps `mix test --include slow`
  # honest: it says the check did not run instead of pretending it broke.
  if File.exists?(@path) do
    @moduletag :slow
  else
    @moduletag skip: "feed.xml is not in the project root; download it to run this test"
  end

  test "reads the complete sample feed" do
    {microseconds, {:ok, feed}} = :timer.tc(fn -> @path |> File.read!() |> Parser.parse() end)

    assert feed.channel.title == "Freak Show"
    assert length(feed.items) == 312
    assert Enum.count(feed.items, &(&1.chapters != [])) == 238
    assert Enum.all?(feed.items, &(&1.guid not in [nil, ""]))
    assert microseconds < 15_000_000
  end
end
