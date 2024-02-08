defmodule Radiator.OutlineFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `Radiator.Outline` context.
  """
  alias Radiator.Podcast
  alias Radiator.PodcastFixtures

  @doc """
  Generate a node.
  """
  def node_fixture(attrs \\ %{}) do
    episode = get_episode(attrs)

    {:ok, node} =
      attrs
      |> Enum.into(%{
        content: "some content",
        episode_id: episode.id
      })
      |> Radiator.Outline.create_node()

    node
  end

  defp get_episode(%{episode_id: id}), do: Podcast.get_episode!(id)
  defp get_episode(_), do: PodcastFixtures.episode_fixture()
end
