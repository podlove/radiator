defmodule Radiator.OutlineFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `Radiator.Outline` context.
  """
  alias Radiator.PodcastFixtures

  @doc """
  Generate a node.
  """
  def node_fixture(attrs \\ %{}) do
    episode = PodcastFixtures.episode_fixture()

    {:ok, node} =
      attrs
      |> Enum.into(%{
        content: "some content",
        episode_id: episode.id
      })
      |> Radiator.Outline.create_node()

    node
  end
end
