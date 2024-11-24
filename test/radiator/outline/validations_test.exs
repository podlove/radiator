defmodule Radiator.Outline.ValidationsTest do
  @moduledoc false
  use Radiator.DataCase

  alias Radiator.Outline.Node
  alias Radiator.Outline.NodeRepository
  alias Radiator.Outline.Validations

  import Ecto.Query, warn: false

  describe "validate_tree_for_episode/1" do
    setup :complex_node_fixture

    test "validates a tree", %{
      node_1: %Node{episode_id: episode_id}
    } do
      assert :ok = Validations.validate_tree_for_episode(episode_id)
    end

    test "a level might have different subtrees", %{
      node_1: %Node{episode_id: episode_id, show_id: show_id} = node_1
    } do
      {:ok, %Node{} = _nested_node} =
        %{
          episode_id: episode_id,
          show_id: show_id,
          parent_id: node_1.uuid,
          prev_id: nil,
          content: "child of node 1"
        }
        |> NodeRepository.create_node()

      assert :ok = Validations.validate_tree_for_episode(episode_id)
    end

    test "when two nodes share the same prev_id the tree is invalid", %{
      node_2: %Node{episode_id: episode_id, show_id: show_id} = node_2
    } do
      {:ok, %Node{} = _node_invalid} =
        %{
          episode_id: episode_id,
          show_id: show_id,
          parent_id: node_2.parent_id,
          prev_id: node_2.prev_id
        }
        |> NodeRepository.create_node()

      assert {:error, :prev_id_not_consistent} =
               Validations.validate_tree_for_episode(episode_id)
    end

    test "when a nodes has a non connected prev_id the tree is invalid", %{
      node_2: %Node{episode_id: episode_id, show_id: show_id} = node_2
    } do
      {:ok, %Node{} = _node_invalid} =
        %{
          episode_id: episode_id,
          show_id: show_id,
          parent_id: node_2.parent_id,
          prev_id: node_2.prev_id
        }
        |> NodeRepository.create_node()

      assert {:error, :prev_id_not_consistent} =
               Validations.validate_tree_for_episode(episode_id)
    end

    test "when a parent has two childs with prev_id nil the tree is invalid", %{
      nested_node_1: %Node{episode_id: episode_id, parent_id: parent_id, show_id: show_id}
    } do
      {:ok, %Node{} = _node_invalid} =
        %{
          episode_id: episode_id,
          show_id: show_id,
          parent_id: parent_id,
          prev_id: nil,
          content: "invalid node"
        }
        |> NodeRepository.create_node()

      assert {:error, :prev_id_not_consistent} =
               Validations.validate_tree_for_episode(episode_id)
    end

    test "a tree with a node where parent and prev are not consistent is invalid", %{
      parent_node: %Node{episode_id: episode_id, show_id: show_id} = parent_node,
      nested_node_2: nested_node_2
    } do
      {:ok, %Node{} = _node_invalid} =
        %{
          episode_id: episode_id,
          show_id: show_id,
          parent_id: parent_node.uuid,
          prev_id: nested_node_2.uuid
        }
        |> NodeRepository.create_node()

      result = Validations.validate_tree_for_episode(episode_id)
      assert {:error, :prev_id_not_consistent} = result
    end
  end
end
