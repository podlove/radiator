defmodule Radiator.FeedFixtures do
  @moduledoc """
  Access to the XML fixtures under `test/support/fixtures/feeds`.
  """

  @dir Path.join([__DIR__, "fixtures", "feeds"])

  @doc "Absolute path to a fixture file."
  def path(name), do: Path.join(@dir, name)

  @doc "Contents of a fixture file as a binary."
  def read!(name), do: name |> path() |> File.read!()
end
