defmodule Radiator.Outline.Validations do
  @moduledoc """
    Collection of consistency validations for the outline tree.
  """

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

  def validate_tree(episode_id) do
    tree_nodes = get_node_tree
    all_nodes_by_episode = NodeRepository.list_nodes_by_episode(episode_id)
    # tree_nodes
    # every level has 1 node with prev_id nil
    # all other nodes in level have prev_id set and are connected to the previous node
    Enum.size(tree_nodes) == Enum.size(all_nodes_by_episode)
  end
end
