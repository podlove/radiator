defmodule Radiator.Outline.Validations do
  @moduledoc """
    Collection of consistency validations for the outline tree.
  """
  alias Radiator.Outline
  alias Radiator.Outline.Node
  alias Radiator.Outline.NodeRepository

  def validate_consistency_for_move(
        %{prev_id: new_prev_id, parent_id: new_parent_id},
        new_prev_id,
        new_parent_id,
        _parent_node
      ) do
    {:error, :noop}
  end

  # when prev is nil, every parent is allowed
  def validate_consistency_for_move(
        node,
        nil,
        _new_parent_id,
        _parent_node
      ) do
    {:ok, node}
  end

  # when prev is not nil, parent and prev must be consistent
  def validate_consistency_for_move(
        node,
        new_prev_id,
        new_parent_id,
        _parent_node
      ) do
    if NodeRepository.get_node(new_prev_id).parent_id == new_parent_id do
      {:ok, node}
    else
      {:error, :parent_and_prev_not_consistent}
    end
  end

  @doc """
  Validates a tree for an episode.
  Returns :ok if the tree is valid
  """
  def validate_tree_for_episode(episode_id) do
    {:ok, tree_nodes} = Outline.get_node_tree(episode_id)

    if Enum.count(tree_nodes) == NodeRepository.count_nodes_by_episode(episode_id) do
      validate_tree_nodes(tree_nodes)
    else
      {:error, :node_count_not_consistent}
    end
  end

  # iterate through the levels of the tree
  # every level has 1 node with prev_id nil
  # all other nodes in level have prev_id set and are connected to the previous node
  # should be used in dev and test only
  # might crash if the tree is not consistent
  defp validate_tree_nodes(tree_nodes) do
    tree_nodes
    |> Enum.group_by(& &1.parent_id)
    |> Enum.map(fn {_level, nodes} ->
      validate_sub_tree(nodes)
    end)
    |> Enum.reject(&(&1 == :ok))
    |> first_error()
  end

  defp first_error([]), do: :ok
  defp first_error([err | _]), do: err

  defp validate_sub_tree(nodes) do
    # get the node with prev_id nil
    first_node = Enum.find(nodes, &(&1.prev_id == nil))
    # get the rest of the nodes
    rest_nodes = Enum.reject(nodes, &(&1.prev_id == nil))

    if Enum.count(rest_nodes) + 1 != Enum.count(nodes) do
      {:error, :prev_id_not_consistent}
    else
      validate_prev_node(first_node, rest_nodes)
    end
  end

  def validate_prev_node(node, rest_nodes, searched_nodes \\ [])

  def validate_prev_node(
        %Node{uuid: id},
        [%Node{prev_id: id} = node | rest_nodes],
        searched_nodes
      ) do
    validate_prev_node(node, rest_nodes ++ searched_nodes, [])
  end

  def validate_prev_node(%Node{}, [], []), do: :ok

  def validate_prev_node(%Node{} = prev_node, [node | rest_nodes], search_nodes) do
    validate_prev_node(prev_node, rest_nodes, search_nodes ++ [node])
  end

  def validate_prev_node(%Node{}, [], _search_nodes), do: {:error, :prev_id_not_consistent}
end
