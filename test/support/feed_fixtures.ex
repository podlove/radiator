defmodule Radiator.FeedFixtures do
  @moduledoc """
  Access to the XML fixtures under `test/support/fixtures/feeds`.
  """

  @dir Path.join([__DIR__, "fixtures", "feeds"])

  @doc "Contents of a fixture file as a binary."
  def read!(name), do: [@dir, name] |> Path.join() |> File.read!()
end
