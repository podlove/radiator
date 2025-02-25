defmodule Radiator.OutlineFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `Radiator.Outline` context.
  """
  alias Radiator.Outline.Node
  alias Radiator.Outline.NodeRepository
  alias Radiator.Podcast
  alias Radiator.PodcastFixtures
  alias Radiator.Repo

  @doc """
  Generate a node.
  """
  def node_fixture(attrs \\ %{}) do
    episode = get_episode(attrs)

    {:ok, node} =
      attrs
      |> Enum.into(%{
        content: "some content",
        container_id: episode.outline_node_container_id
      })
      |> NodeRepository.create_node()

    Node
    |> Repo.get!(node.uuid)
  end

  defp get_episode(%{episode_id: id}), do: Podcast.get_episode!(id)
  defp get_episode(_), do: PodcastFixtures.episode_fixture()

  @doc """
  Generate a tree of nodes based on a human readable pseudo syntax.
  [
    "node-1",
    {"node-2", [
      "node-2_1",
      {"node-2_2", [
        "node-2_2_1"
      ]}
    ]},
    "node-3"
  ]
  |> node_tree_fixture(%{show_id: show.id})
  """
  def node_tree_fixture(content, attrs \\ %{})

  def node_tree_fixture([content], attrs) do
    [node_tree_fixture(content, attrs)]
  end

  def node_tree_fixture([content | tail], attrs) do
    nodes = node_tree_fixture(content, attrs)

    %{uuid: prev_uuid} = nodes |> List.wrap() |> List.first()
    child_attrs = Map.merge(attrs, %{parent_id: nil, prev_id: prev_uuid})

    List.flatten([nodes | node_tree_fixture(tail, child_attrs)])
  end

  def node_tree_fixture({content, list}, attrs) do
    node = node_tree_fixture(content, attrs)
    child_attrs = Map.merge(attrs, %{parent_id: node.uuid, prev_id: nil})

    [node, [node_tree_fixture(list, child_attrs)]]
  end

  def node_tree_fixture(content, attrs) when is_bitstring(content) do
    attrs
    |> Map.merge(%{content: content})
    |> node_fixture()
  end

  @doc """
  Generate a node_container.
  """
  def node_container_fixture(_attrs \\ %{}) do
    {:ok, node_container} =
      Radiator.Outline.create_node_container()

    node_container
  end
end
