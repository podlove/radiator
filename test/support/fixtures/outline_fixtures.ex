defmodule Radiator.OutlineFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `Radiator.Outline` context.
  """

  @doc """
  Generate a node.
  """
  def node_fixture(attrs \\ %{}) do
    {:ok, node} =
      attrs
      |> Enum.into(%{content: "some content"})
      |> Radiator.Outline.create_node()

    node
  end
end
