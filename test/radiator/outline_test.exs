defmodule Radiator.OutlineTest do
  alias Radiator.Outline.NodeRepoResult
  use Radiator.DataCase

  alias Radiator.Outline
  alias Radiator.Outline.Node
  alias Radiator.Outline.NodeRepository
  alias Radiator.PodcastFixtures

  import Radiator.OutlineFixtures
  import Ecto.Query, warn: false

  describe "update_node_content/2" do
    test "with valid data updates the node" do
      node = node_fixture()
      updated_content = "some updated content"

      assert {:ok, %Node{} = node} = Outline.update_node_content(node.uuid, updated_content)
      assert node.content == updated_content
    end

    test "with invalid data returns error changeset" do
      node = node_fixture()

      assert {:error, %Ecto.Changeset{}} =
               Outline.update_node_content(node.uuid, %{"content" => nil})

      assert node == NodeRepository.get_node!(node.uuid)
    end
  end

  describe "get_prev_node/1" do
    setup :complex_node_fixture

    test "returns the previous node", %{node_2: node_2, node_3: node_3} do
      assert Outline.get_prev_node(node_3) == node_2
    end

    test "returns nil if there is no previous node", %{node_1: node_1} do
      assert Outline.get_prev_node(node_1) == nil
    end
  end

  describe "get_all_child_nodes/1" do
    setup :complex_node_fixture

    test "returns all child nodes", %{
      node_3: node_3,
      nested_node_1: nested_node_1,
      nested_node_2: nested_node_2
    } do
      assert Outline.get_all_child_nodes(node_3) == [nested_node_1, nested_node_2]
    end

    test "returns an empty list if there are no child nodes", %{node_1: node_1} do
      assert Outline.get_all_child_nodes(node_1) == []
    end
  end

  describe "insert_node/1" do
    setup :complex_node_fixture

    test "node can be inserted after another node", %{node_3: node_3, node_4: node_4} do
      node_attrs = %{
        "content" => "node 3.1",
        "episode_id" => node_3.episode_id,
        "parent_id" => node_3.parent_id,
        "prev_id" => node_3.uuid
      }

      assert {:ok, %{node: %Node{uuid: node3_1_uuid} = node}} = Outline.insert_node(node_attrs)

      assert node.parent_id == node_3.parent_id
      assert node.prev_id == node_3.uuid

      node4 = Repo.reload!(node_4)

      assert node4.prev_id == node3_1_uuid
    end

    test "the moved node gets moved to its right place", %{
      node_3: node_3,
      nested_node_1: nested_node_1,
      nested_node_2: nested_node_2
    } do
      node_attrs = %{
        "content" => "new node",
        "episode_id" => node_3.episode_id,
        "parent_id" => node_3.uuid,
        "prev_id" => nested_node_1.uuid
      }

      {:ok, %{node: new_node}} = Outline.insert_node(node_attrs)
      nested_node_2 = Repo.reload!(nested_node_2)
      assert nested_node_2.prev_id == new_node.uuid
      assert nested_node_2.parent_id == node_3.uuid
    end

    test "creates a new node in the tree", %{
      node_3: node_3,
      nested_node_1: nested_node_1
    } do
      count_nodes = NodeRepository.count_nodes_by_episode(node_3.episode_id)

      node_attrs = %{
        "content" => "new node",
        "episode_id" => node_3.episode_id,
        "parent_id" => node_3.uuid,
        "prev_id" => nested_node_1.uuid
      }

      Outline.insert_node(node_attrs)
      new_count_nodes = NodeRepository.count_nodes_by_episode(node_3.episode_id)
      assert new_count_nodes == count_nodes + 1
    end

    test "the parent gets set", %{
      node_3: node_3,
      nested_node_1: nested_node_1
    } do
      node_attrs = %{
        "content" => "new node",
        "episode_id" => node_3.episode_id,
        "parent_id" => node_3.uuid,
        "prev_id" => nested_node_1.uuid
      }

      {:ok, %{node: new_node}} = Outline.insert_node(node_attrs)
      assert new_node.parent_id == node_3.uuid
    end

    test "the prev gets set", %{
      node_3: node_3,
      nested_node_1: nested_node_1
    } do
      node_attrs = %{
        "content" => "new node",
        "episode_id" => node_3.episode_id,
        "parent_id" => node_3.uuid,
        "prev_id" => nested_node_1.uuid
      }

      {:ok, %{node: new_node}} = Outline.insert_node(node_attrs)
      assert new_node.prev_id == nested_node_1.uuid
    end

    test "all nodes in same level are correctly connected", %{
      node_3: node_3,
      nested_node_1: nested_node_1,
      nested_node_2: nested_node_2
    } do
      node_attrs = %{
        "content" => "new node",
        "episode_id" => node_3.episode_id,
        "parent_id" => node_3.uuid,
        "prev_id" => nested_node_1.uuid
      }

      {:ok, %{node: new_node}} = Outline.insert_node(node_attrs)

      assert NodeRepository.get_node!(nested_node_2.uuid).prev_id == new_node.uuid
      assert new_node.prev_id == nested_node_1.uuid
      assert NodeRepository.get_node!(nested_node_1.uuid).prev_id == nil
    end

    test "inserted node can be inserted at the end", %{
      node_3: node_3,
      nested_node_1: nested_node_1,
      nested_node_2: nested_node_2
    } do
      node_attrs = %{
        "content" => "new node",
        "episode_id" => node_3.episode_id,
        "parent_id" => node_3.uuid,
        "prev_id" => nested_node_2.uuid
      }

      {:ok, %{node: new_node}} = Outline.insert_node(node_attrs)

      assert NodeRepository.get_node!(nested_node_2.uuid).prev_id == nested_node_1.uuid
      assert new_node.prev_id == nested_node_2.uuid
      assert NodeRepository.get_node!(nested_node_1.uuid).prev_id == nil
    end

    test "without a prev node inserted node will be first in list", %{
      node_3: node_3,
      nested_node_1: nested_node_1,
      nested_node_2: nested_node_2
    } do
      node_attrs = %{
        "content" => "new node",
        "episode_id" => node_3.episode_id,
        "parent_id" => node_3.uuid
      }

      {:ok, %{node: new_node}} = Outline.insert_node(node_attrs)

      assert new_node.prev_id == nil
      assert NodeRepository.get_node!(nested_node_1.uuid).prev_id == new_node.uuid
      assert NodeRepository.get_node!(nested_node_2.uuid).prev_id == nested_node_1.uuid
    end

    test "without a parent node the inserted node will be put at the top", %{
      parent_node: parent_node
    } do
      # another node in another episode without parent and prev node
      node_fixture(parent_id: nil, prev_id: nil)
      node_attrs = %{"content" => "new node", "episode_id" => parent_node.episode_id}
      {:ok, %{node: new_node}} = Outline.insert_node(node_attrs)

      assert new_node.prev_id == nil
      assert new_node.parent_id == nil
      assert NodeRepository.get_node!(parent_node.uuid).prev_id == new_node.uuid
    end

    test "parent node and prev node need to be consistent", %{
      parent_node: parent_node,
      nested_node_1: nested_node_1
    } do
      # new node cannot be inserted at level 1 and wants the lined in level 2
      node_attrs = %{
        "content" => "new node",
        "episode_id" => parent_node.episode_id,
        "parent_id" => parent_node.uuid,
        "prev_id" => nested_node_1.uuid
      }

      {:error, "Insert node failed. Parent and prev node are not consistent."} =
        Outline.insert_node(node_attrs)
    end

    test "parent node and prev node need to be consistent (2)", %{
      parent_node: parent_node
    } do
      bad_parent_node =
        node_fixture(episode_id: parent_node.episode_id, parent_id: nil, prev_id: nil)

      node_attrs = %{
        "content" => "new node",
        "episode_id" => parent_node.episode_id,
        "parent_id" => parent_node.uuid,
        "prev_id" => bad_parent_node.uuid
      }

      {:error, _error_message} =
        Outline.insert_node(node_attrs)
    end

    test "in case of error no node gets inserted", %{
      parent_node: parent_node,
      nested_node_1: nested_node_1
    } do
      count_nodes = NodeRepository.count_nodes_by_episode(parent_node.episode_id)

      node_attrs = %{
        "content" => "new node",
        "episode_id" => parent_node.episode_id,
        "parent_id" => parent_node.uuid,
        "prev_id" => nested_node_1.uuid
      }

      {:error, _error_message} = Outline.insert_node(node_attrs)
      new_count_nodes = NodeRepository.count_nodes_by_episode(parent_node.episode_id)
      # count stays the same
      assert new_count_nodes == count_nodes
    end
  end

  describe "move_node/3 - simple context" do
    setup :simple_node_fixture

    # before 1 2
    # after  2 1
    test "move node on same level", %{
      node_1: node_1,
      node_2: node_2
    } do
      {:ok, _} = Outline.move_node(node_2.uuid, nil, node_2.parent_id)

      # reload nodes
      node_1 = Repo.reload!(node_1)
      node_2 = Repo.reload!(node_2)

      assert node_1.prev_id == node_2.uuid
      assert node_2.prev_id == nil
    end

    # before 1 2
    # after  2 1
    test "move node on same level - move the other node", %{
      node_1: node_1,
      node_2: node_2
    } do
      {:ok, _} = Outline.move_node(node_1.uuid, node_2.uuid, node_1.parent_id)

      # reload nodes
      node_1 = Repo.reload!(node_1)
      node_2 = Repo.reload!(node_2)

      assert node_1.prev_id == node_2.uuid
      assert node_2.prev_id == nil
    end

    test "ignore when nothing should change", %{
      node_1: node_1,
      node_2: node_2
    } do
      {:ok, _} = Outline.move_node(node_2.uuid, node_1.uuid, node_2.parent_id)

      # reload nodes
      node_1 = Repo.reload!(node_1)
      node_2 = Repo.reload!(node_2)

      assert node_2.prev_id == node_1.uuid
      assert node_1.prev_id == nil
    end

    test "ignore when nothing should change - other way around", %{
      node_1: node_1,
      node_2: node_2
    } do
      {:ok, _} = Outline.move_node(node_1.uuid, nil, node_2.parent_id)

      # reload nodes
      node_1 = Repo.reload!(node_1)
      node_2 = Repo.reload!(node_2)

      assert node_2.prev_id == node_1.uuid
      assert node_1.prev_id == nil
    end

    test "move node below other node", %{
      node_1: node_1,
      node_2: node_2
    } do
      {:ok, _} = Outline.move_node(node_2.uuid, nil, node_1.uuid)

      # reload nodes
      node_1 = Repo.reload!(node_1)
      node_2 = Repo.reload!(node_2)

      assert node_1.prev_id == nil
      assert node_2.prev_id == nil

      assert node_1.parent_id == nil
      assert node_2.parent_id == node_1.uuid
    end
  end

  describe "move_node/3" do
    setup :complex_node_fixture

    # before 1 2 3 4 5
    # after  1 2 4 3 5
    test "move node 4 within list to node 2", %{
      node_2: node_2,
      node_3: node_3,
      node_4: node_4,
      node_5: node_5
    } do
      {:ok, _} = Outline.move_node(node_4.uuid, node_2.uuid, node_4.parent_id)

      # reload nodes
      node_5 = Repo.reload!(node_5)
      node_4 = Repo.reload!(node_4)
      node_3 = Repo.reload!(node_3)
      node_2 = Repo.reload!(node_2)

      assert node_4.prev_id == node_2.uuid
      assert node_3.prev_id == node_4.uuid
      assert node_5.prev_id == node_3.uuid
    end

    # before 1 2 3 4 5
    # after  4 1 2 3 5
    test "move node 4 to the top of the list", %{
      node_1: node_1,
      node_2: node_2,
      node_3: node_3,
      node_4: node_4,
      node_5: node_5
    } do
      {:ok, _} = Outline.move_node(node_4.uuid, nil, node_4.parent_id)

      # reload nodes
      node_5 = Repo.reload!(node_5)
      node_4 = Repo.reload!(node_4)
      node_3 = Repo.reload!(node_3)
      node_2 = Repo.reload!(node_2)
      node_1 = Repo.reload!(node_1)

      assert node_4.prev_id == nil
      assert node_1.prev_id == node_4.uuid
      assert node_2.prev_id == node_1.uuid
      assert node_3.prev_id == node_2.uuid
      assert node_5.prev_id == node_3.uuid
    end

    # before 1 2 3 4 5
    # after  1 3 4 5 2
    test "move node 2 to the end of the list", %{
      node_1: node_1,
      node_2: node_2,
      node_3: node_3,
      node_4: node_4,
      node_5: node_5
    } do
      {:ok, _} = Outline.move_node(node_2.uuid, node_5.uuid, node_2.parent_id)

      # reload nodes
      node_5 = Repo.reload!(node_5)
      node_4 = Repo.reload!(node_4)
      node_3 = Repo.reload!(node_3)
      node_2 = Repo.reload!(node_2)
      node_1 = Repo.reload!(node_1)

      assert node_3.prev_id == node_1.uuid
      assert node_4.prev_id == node_3.uuid
      assert node_5.prev_id == node_4.uuid
      assert node_2.prev_id == node_5.uuid
    end

    # before 1 2 3 4 5
    # after  2 3 4 5 1
    test "move first node to the end of the list", %{
      node_1: node_1,
      node_2: node_2,
      node_3: node_3,
      node_4: node_4,
      node_5: node_5
    } do
      {:ok, _} = Outline.move_node(node_1.uuid, node_5.uuid, node_2.parent_id)

      # reload nodes
      node_5 = Repo.reload!(node_5)
      node_4 = Repo.reload!(node_4)
      node_3 = Repo.reload!(node_3)
      node_2 = Repo.reload!(node_2)
      node_1 = Repo.reload!(node_1)

      assert node_1.prev_id == node_5.uuid
      assert node_5.prev_id == node_4.uuid
      assert node_3.prev_id == node_2.uuid
      assert node_2.prev_id == nil
    end

    # before 1 2 3 4 5
    # after  5 1 2 3 4
    test "move last node to the top of the list", %{
      node_1: node_1,
      node_2: node_2,
      node_3: node_3,
      node_4: node_4,
      node_5: node_5
    } do
      {:ok, _} = Outline.move_node(node_5.uuid, nil, node_2.parent_id)

      # reload nodes
      node_5 = Repo.reload!(node_5)
      node_4 = Repo.reload!(node_4)
      node_3 = Repo.reload!(node_3)
      node_2 = Repo.reload!(node_2)
      node_1 = Repo.reload!(node_1)

      assert node_5.prev_id == nil
      assert node_1.prev_id == node_5.uuid
      assert node_2.prev_id == node_1.uuid
      assert node_3.prev_id == node_2.uuid
      assert node_4.prev_id == node_3.uuid
    end

    test "move nested node to a new parent", %{
      node_2: node_2,
      node_3: node_3,
      nested_node_1: nested_node_1,
      nested_node_2: nested_node_2
    } do
      {:ok, _} = Outline.move_node(nested_node_1.uuid, nil, node_2.uuid)

      # reload nodes
      nested_node_1 = Repo.reload!(nested_node_1)
      nested_node_2 = Repo.reload!(nested_node_2)

      assert nested_node_1.parent_id == node_2.uuid
      assert nested_node_2.parent_id == node_3.uuid
      assert nested_node_1.prev_id == nil
      assert nested_node_2.prev_id == nil
    end

    test "move node with child elements to top", %{
      parent_node: parent_node,
      node_3: node_3,
      nested_node_1: nested_node_1,
      nested_node_2: nested_node_2
    } do
      {:ok, _} = Outline.move_node(node_3.uuid, nil, nil)

      # reload nodes
      parent_node = Repo.reload!(parent_node)
      node_3 = Repo.reload!(node_3)
      nested_node_1 = Repo.reload!(nested_node_1)
      nested_node_2 = Repo.reload!(nested_node_2)

      assert node_3.prev_id == nil
      assert node_3.parent_id == nil
      assert parent_node.prev_id == node_3.uuid
      assert nested_node_1.parent_id == node_3.uuid
      assert nested_node_2.parent_id == node_3.uuid
      assert nested_node_1.prev_id == nil
      assert nested_node_2.prev_id == nested_node_1.uuid
    end

    # before 1 2 3 4 5
    # after  2 3 4 5 1
    test "move first node to the end of the list returns all needed infos", %{
      node_1: node_1,
      node_2: node_2,
      node_5: node_5
    } do
      {:ok, %NodeRepoResult{} = node_result} =
        Outline.move_node(node_1.uuid, node_5.uuid, node_2.parent_id)

      assert node_result.node.uuid == node_1.uuid
      assert node_result.old_prev_id == nil
      assert node_result.old_next_id == node_2.uuid
    end
  end

  describe "remove_node/1" do
    setup :complex_node_fixture

    test "deletes the node" do
      node = node_fixture()
      assert {:ok, %Node{}} = Outline.remove_node(node)
      assert_raise Ecto.NoResultsError, fn -> NodeRepository.get_node!(node.uuid) end
    end

    test "next node must be updated", %{
      node_2: node_2,
      node_3: node_3,
      node_4: node_4
    } do
      assert node_4.prev_id == node_3.uuid

      assert {:ok, %Node{}} = Outline.remove_node(node_3)
      # reload nodes
      node_4 = NodeRepository.get_node!(node_4.uuid)
      node_2 = NodeRepository.get_node!(node_2.uuid)

      assert node_4.prev_id == node_2.uuid
    end

    test "works for last element in list", %{
      node_6: node_6
    } do
      episode_id = node_6.episode_id
      count_nodes = NodeRepository.count_nodes_by_episode(episode_id)
      assert {:ok, %Node{}} = Outline.remove_node(node_6)
      new_count_nodes = NodeRepository.count_nodes_by_episode(episode_id)
      assert new_count_nodes == count_nodes - 1
    end

    test "works for first element in list", %{
      node_1: node_1,
      node_2: node_2
    } do
      episode_id = node_1.episode_id

      count_nodes = NodeRepository.count_nodes_by_episode(episode_id)
      assert {:ok, %Node{}} = Outline.remove_node(node_1)
      new_count_nodes = NodeRepository.count_nodes_by_episode(episode_id)
      assert new_count_nodes == count_nodes - 1

      node_2 = NodeRepository.get_node!(node_2.uuid)
      assert node_2.prev_id == nil
    end

    test "delete also child elements", %{
      node_3: node_3,
      nested_node_1: nested_node_1,
      nested_node_2: nested_node_2
    } do
      assert {:ok, %Node{}} = Outline.remove_node(node_3)

      assert_raise Ecto.NoResultsError, fn -> NodeRepository.get_node!(nested_node_1.uuid) end
      assert_raise Ecto.NoResultsError, fn -> NodeRepository.get_node!(nested_node_2.uuid) end
    end

    test "when top parent gets deleted the whole tree will be gone", %{
      node_1: node_1,
      node_4: node_4,
      node_6: node_6,
      nested_node_2: nested_node_2,
      parent_node: parent_node
    } do
      assert {:ok, %Node{}} = Outline.remove_node(parent_node)

      # test some of elements in the tree
      assert_raise Ecto.NoResultsError, fn -> NodeRepository.get_node!(node_1.uuid) end
      assert_raise Ecto.NoResultsError, fn -> NodeRepository.get_node!(node_4.uuid) end
      assert_raise Ecto.NoResultsError, fn -> NodeRepository.get_node!(node_6.uuid) end
      assert_raise Ecto.NoResultsError, fn -> NodeRepository.get_node!(nested_node_2.uuid) end
    end
  end

  describe "get_node_tree/1" do
    setup :complex_node_fixture

    test "returns all nodes from a episode", %{parent_node: parent_node} do
      episode_id = parent_node.episode_id
      assert {:ok, tree} = Outline.get_node_tree(episode_id)

      all_nodes = NodeRepository.list_nodes_by_episode(episode_id)

      assert Enum.count(tree) == Enum.count(all_nodes)

      Enum.each(tree, fn node ->
        assert node.uuid ==
                 List.first(Enum.filter(all_nodes, fn n -> n.uuid == node.uuid end)).uuid
      end)
    end

    test "does not return a node from another episode", %{
      parent_node: parent_node
    } do
      episode_id = parent_node.episode_id
      other_node = node_fixture(parent_id: nil, prev_id: nil, content: "other content")
      assert other_node.episode_id != episode_id
      {:ok, tree} = Outline.get_node_tree(episode_id)
      assert Enum.filter(tree, fn n -> n.uuid == other_node.uuid end) == []
    end

    test "returns nodes sorted by level", %{parent_node: parent_node} do
      episode_id = parent_node.episode_id
      {:ok, tree} = Outline.get_node_tree(episode_id)

      Enum.reduce(tree, 0, fn node, current_level ->
        if node.parent_id != nil do
          parent_node = Enum.find(tree, fn n -> n.uuid == node.parent_id end)
          assert parent_node.level + 1 == node.level
        end

        assert node.level >= current_level
        node.level
      end)
    end

    test "associated the correct level", %{
      node_1: node_1,
      node_2: node_2,
      node_3: node_3,
      node_4: node_4,
      node_5: node_5,
      node_6: node_6,
      nested_node_1: nested_node_1,
      nested_node_2: nested_node_2,
      parent_node: parent_node
    } do
      {:ok, tree} = Outline.get_node_tree(parent_node.episode_id)
      assert_level_for_node(tree, parent_node, 0)
      assert_level_for_node(tree, node_1, 1)
      assert_level_for_node(tree, node_2, 1)
      assert_level_for_node(tree, node_3, 1)
      assert_level_for_node(tree, node_4, 1)
      assert_level_for_node(tree, node_5, 1)
      assert_level_for_node(tree, node_6, 1)
      assert_level_for_node(tree, nested_node_1, 2)
      assert_level_for_node(tree, nested_node_2, 2)
    end

    test "tree can have more than one parent node", %{
      parent_node: parent_node
    } do
      episode_id = parent_node.episode_id

      other_parent_node =
        node_fixture(
          parent_id: nil,
          prev_id: parent_node.uuid,
          episode_id: episode_id,
          content: "also a parent"
        )

      third_parent_node =
        node_fixture(
          parent_id: nil,
          prev_id: other_parent_node.uuid,
          episode_id: episode_id,
          content: "even another root element"
        )

      {:ok, tree} = Outline.get_node_tree(parent_node.episode_id)
      assert_level_for_node(tree, parent_node, 0)
      assert_level_for_node(tree, other_parent_node, 0)
      assert_level_for_node(tree, third_parent_node, 0)
    end
  end

  describe "order_child_nodes/1" do
    setup :complex_node_fixture

    test "get child nodes in correct order" do
      episode = PodcastFixtures.episode_fixture()

      node_1 =
        node_fixture(
          episode_id: episode.id,
          parent_id: nil,
          prev_id: nil,
          content: "node_1"
        )

      node_3 =
        node_fixture(
          episode_id: episode.id,
          parent_id: node_1.uuid,
          prev_id: nil,
          content: "node_3"
        )

      node_2 =
        node_fixture(
          episode_id: episode.id,
          parent_id: node_1.uuid,
          prev_id: node_3.uuid,
          content: "node_2"
        )

      {:ok, %NodeRepoResult{} = _result} =
        Outline.move_node(node_3.uuid, node_2.uuid, node_1.uuid)

      assert node_1 |> Outline.order_child_nodes() |> Enum.map(& &1.content) ==
               ["node_2", "node_3"]
    end
  end

  defp assert_level_for_node(tree, node, level) do
    node = Enum.filter(tree, fn n -> n.uuid == node.uuid end) |> List.first()
    assert node.level == level
  end

  defp simple_node_fixture(_) do
    episode = PodcastFixtures.episode_fixture()

    node_1 =
      node_fixture(
        episode_id: episode.id,
        parent_id: nil,
        prev_id: nil,
        content: "node_1"
      )

    node_2 =
      node_fixture(
        episode_id: episode.id,
        parent_id: nil,
        prev_id: node_1.uuid,
        content: "node_2"
      )

    assert node_2.prev_id == node_1.uuid
    assert node_1.prev_id == nil
    assert node_1.parent_id == nil
    assert node_2.parent_id == nil

    %{
      node_1: node_1,
      node_2: node_2
    }
  end

  defp complex_node_fixture(_) do
    episode = PodcastFixtures.episode_fixture()

    parent_node =
      node_fixture(
        episode_id: episode.id,
        parent_id: nil,
        prev_id: nil,
        content: "root of all evil"
      )

    node_1 =
      node_fixture(
        episode_id: episode.id,
        parent_id: parent_node.uuid,
        prev_id: nil,
        content: "node_1"
      )

    node_2 =
      node_fixture(
        episode_id: episode.id,
        parent_id: parent_node.uuid,
        prev_id: node_1.uuid,
        content: "node_2"
      )

    node_3 =
      node_fixture(
        episode_id: episode.id,
        parent_id: parent_node.uuid,
        prev_id: node_2.uuid,
        content: "node_3"
      )

    node_4 =
      node_fixture(
        episode_id: episode.id,
        parent_id: parent_node.uuid,
        prev_id: node_3.uuid,
        content: "node_4"
      )

    node_5 =
      node_fixture(
        episode_id: episode.id,
        parent_id: parent_node.uuid,
        prev_id: node_4.uuid,
        content: "node_5"
      )

    node_6 =
      node_fixture(
        episode_id: episode.id,
        parent_id: parent_node.uuid,
        prev_id: node_5.uuid,
        content: "node_6"
      )

    nested_node_1 =
      node_fixture(
        episode_id: episode.id,
        parent_id: node_3.uuid,
        prev_id: nil,
        content: "nested_node_1"
      )

    nested_node_2 =
      node_fixture(
        episode_id: episode.id,
        parent_id: node_3.uuid,
        prev_id: nested_node_1.uuid,
        content: "nested_node_2"
      )

    assert node_5.prev_id == node_4.uuid
    assert node_4.prev_id == node_3.uuid
    assert node_3.prev_id == node_2.uuid
    assert node_2.prev_id == node_1.uuid
    assert node_1.prev_id == nil

    assert nested_node_1.parent_id == node_3.uuid
    assert nested_node_2.parent_id == node_3.uuid
    assert nested_node_1.prev_id == nil
    assert nested_node_2.prev_id == nested_node_1.uuid

    %{
      node_1: node_1,
      node_2: node_2,
      node_3: node_3,
      node_4: node_4,
      node_5: node_5,
      node_6: node_6,
      nested_node_1: nested_node_1,
      nested_node_2: nested_node_2,
      parent_node: parent_node
    }
  end
end
