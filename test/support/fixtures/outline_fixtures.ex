defmodule Radiator.OutlineFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `Radiator.Outline` context.
  """

  alias Radiator.Outline.NodeRepository
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
      |> NodeRepository.create_node()

    node
  end

  defp get_episode(%{episode_id: id}), do: Podcast.get_episode!(id)
  defp get_episode(_), do: PodcastFixtures.episode_fixture()

  @doc """
  Generate a tree of nodes based on a human readable pseudo syntax.
  [
    {"node-1"},
    {"node-2",
      [
        {"node-2_1"},
        {"node-2_2",
        [
          {"node-2_2_1"}
        ]}
      ]}
  ]
  |> node_tree_fixture(%{episode_id: episode.id})

  """
  def node_tree_fixture(content, attrs, siblings \\ [])

  def node_tree_fixture({content}, attrs, []) do
    attrs
    |> Map.merge(%{content: content, parent_id: attrs[:parent_id], prev_id: nil})
    |> node_fixture()
    |> List.wrap()
  end

  def node_tree_fixture({content}, attrs, [%{uuid: prev_id} | _]) do
    attrs
    |> Map.merge(%{content: content, parent_id: nil, prev_id: prev_id})
    |> node_fixture()
    |> List.wrap()
  end

  def node_tree_fixture({content, nodes}, attrs, siblings) when is_list(nodes) do
    [node] = node_tree_fixture({content}, attrs, siblings)

    attrs = Map.put(attrs, :parent_id, node.uuid)

    children =
      Enum.reduce(nodes, [], fn content, acc ->
        acc ++ node_tree_fixture(content, attrs, acc)
      end)

    [node | children]
  end

  def node_tree_fixture(nodes, attrs, _siblings) when is_list(nodes) do
    Enum.reduce(nodes, [], fn content, acc ->
      acc ++ node_tree_fixture(content, attrs, acc)
    end)
  end
end
