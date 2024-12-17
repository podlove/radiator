defmodule Radiator.Outline.NodeRepositoryTest do
  use Radiator.DataCase

  alias Radiator.Outline.Node
  alias Radiator.Outline.NodeRepository
  alias Radiator.PodcastFixtures

  import Radiator.OutlineFixtures
  import Ecto.Query, warn: false

  @invalid_attrs %{episode_id: nil}

  describe "create_node/1" do
    test "with valid data creates a node" do
      episode = PodcastFixtures.episode_fixture()

      valid_attrs = %{
        content: "some content",
        episode_id: episode.id,
        show_id: episode.show_id,
        outline_node_container_id: episode.outline_node_container_id
      }

      assert {:ok, %Node{} = node} = NodeRepository.create_node(valid_attrs)
      assert node.content == "some content"
    end

    test "can have a creator" do
      episode = PodcastFixtures.episode_fixture()
      user = %{id: 2}

      valid_attrs = %{
        content: "some content",
        episode_id: episode.id,
        show_id: episode.show_id,
        outline_node_container_id: episode.outline_node_container_id,
        creator_id: user.id
      }

      assert {:ok, %Node{} = node} = NodeRepository.create_node(valid_attrs)
      assert node.content == "some content"
      assert node.creator_id == user.id
    end

    @tag :skip
    test "with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = NodeRepository.create_node(@invalid_attrs)
    end
  end

  describe "get_node!/1" do
    test "returns the node with given id" do
      node = node_fixture()
      assert NodeRepository.get_node!(node.uuid) == node
    end
  end

  describe "list_nodes/0" do
    test "returns all nodes" do
      node1 = node_fixture()
      node2 = node_fixture()

      assert Enum.member?(NodeRepository.list_nodes(), node1)
      assert Enum.member?(NodeRepository.list_nodes(), node2)
    end
  end

  describe "list_nodes_by_episode/1" do
    test "list_nodes/1 returns only nodes of this episode" do
      node1 = node_fixture()
      node2 = node_fixture()

      assert NodeRepository.list_nodes_by_episode(node1.episode_id) == [node1]
      assert NodeRepository.list_nodes_by_episode(node2.episode_id) == [node2]
    end
  end

  describe "delete_node/1" do
    test "deletes the node" do
      node = node_fixture()
      assert {:ok, %Node{}} = NodeRepository.delete_node(node)
      assert_raise Ecto.NoResultsError, fn -> NodeRepository.get_node!(node.uuid) end
    end
  end

  describe "get_prev_node/1" do
    setup :complex_node_fixture

    test "returns the previous node", %{node_2: node_2, node_3: node_3} do
      assert NodeRepository.get_prev_node(node_3) == node_2
    end

    test "returns nil if there is no previous node", %{node_1: node_1} do
      assert NodeRepository.get_prev_node(node_1) == nil
    end
  end

  describe "get_all_children/1" do
    setup :complex_node_fixture

    test "returns all child nodes", %{
      parent_node: parent_node,
      node_1: node_1,
      node_2: node_2,
      node_3: node_3,
      node_4: node_4,
      node_5: node_5,
      node_6: node_6,
      nested_node_1: nested_node_1,
      nested_node_2: nested_node_2
    } do
      all_children = parent_node |> NodeRepository.get_all_children()
      assert Enum.member?(all_children, node_1)
      assert Enum.member?(all_children, node_2)
      assert Enum.member?(all_children, node_3)
      assert Enum.member?(all_children, node_4)
      assert Enum.member?(all_children, node_5)
      assert Enum.member?(all_children, node_6)
      assert Enum.member?(all_children, nested_node_1)
      assert Enum.member?(all_children, nested_node_2)
    end

    test "returns an empty list if there are no child nodes", %{nested_node_1: nested_node_1} do
      assert NodeRepository.get_all_children(nested_node_1) == []
    end
  end

  describe "get_all_siblings/1" do
    setup :complex_node_fixture

    test "returns all direct child nodes", %{
      node_3: node_3,
      nested_node_1: nested_node_1,
      nested_node_2: nested_node_2
    } do
      all_siblings = NodeRepository.get_all_siblings(node_3)
      assert 2 = Enum.count(all_siblings)
      assert Enum.member?(all_siblings, nested_node_1)
      assert Enum.member?(all_siblings, nested_node_2)
    end

    test "does not return child nodes deeper then 1 level", %{
      parent_node: parent_node,
      node_1: node_1,
      nested_node_1: nested_node_1,
      nested_node_2: nested_node_2
    } do
      assert parent_node |> NodeRepository.get_all_siblings() |> Enum.member?(node_1)
      refute parent_node |> NodeRepository.get_all_siblings() |> Enum.member?(nested_node_1)
      refute parent_node |> NodeRepository.get_all_siblings() |> Enum.member?(nested_node_2)
    end

    test "returns an empty list if there are no child nodes", %{node_1: node_1} do
      assert NodeRepository.get_all_siblings(node_1) == []
    end
  end

  describe "get_node_tree/1" do
    setup :complex_node_fixture

    test "returns all nodes from a episode", %{parent_node: parent_node} do
      episode_id = parent_node.episode_id
      assert {:ok, tree} = NodeRepository.get_node_tree(episode_id)

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
      {:ok, tree} = NodeRepository.get_node_tree(episode_id)
      assert Enum.filter(tree, fn n -> n.uuid == other_node.uuid end) == []
    end

    test "returns nodes sorted by level", %{parent_node: parent_node} do
      episode_id = parent_node.episode_id
      {:ok, tree} = NodeRepository.get_node_tree(episode_id)

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
      {:ok, tree} = NodeRepository.get_node_tree(parent_node.episode_id)
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

      {:ok, tree} = NodeRepository.get_node_tree(parent_node.episode_id)
      assert_level_for_node(tree, parent_node, 0)
      assert_level_for_node(tree, other_parent_node, 0)
      assert_level_for_node(tree, third_parent_node, 0)
    end
  end

  defp assert_level_for_node(tree, node, level) do
    node = Enum.filter(tree, fn n -> n.uuid == node.uuid end) |> List.first()
    assert node.level == level
  end
end
