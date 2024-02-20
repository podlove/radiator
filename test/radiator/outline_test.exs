defmodule Radiator.OutlineTest do
  use Radiator.DataCase

  alias Radiator.Outline
  alias Radiator.Outline.Node
  alias Radiator.PodcastFixtures

  import Radiator.OutlineFixtures
  import Ecto.Query, warn: false

  @invalid_attrs %{episode_id: nil}

  describe "list_nodes/0" do
    test "returns all nodes" do
      node1 = node_fixture()
      node2 = node_fixture()

      assert Outline.list_nodes() == [node1, node2]
    end

    test "list_nodes/1 returns only nodes of this episode" do
      node1 = node_fixture()
      node2 = node_fixture()

      assert Outline.list_nodes_by_episode(node1.episode_id) == [node1]
      assert Outline.list_nodes_by_episode(node2.episode_id) == [node2]
    end
  end

  describe "get_node!/1" do
    test "returns the node with given id" do
      node = node_fixture()
      assert Outline.get_node!(node.uuid) == node
    end
  end

  describe "create_node/1" do
    test "with valid data creates a node" do
      episode = PodcastFixtures.episode_fixture()
      valid_attrs = %{content: "some content", episode_id: episode.id}

      assert {:ok, %Node{} = node} = Outline.create_node(valid_attrs)
      assert node.content == "some content"
    end

    test "trims whitespace from content" do
      episode = PodcastFixtures.episode_fixture()
      valid_attrs = %{content: "  some content  ", episode_id: episode.id}

      assert {:ok, %Node{} = node} = Outline.create_node(valid_attrs)
      assert node.content == "some content"
    end

    test "can have a creator" do
      episode = PodcastFixtures.episode_fixture()
      user = %{id: 2}
      valid_attrs = %{content: "some content", episode_id: episode.id}

      assert {:ok, %Node{} = node} = Outline.create_node(valid_attrs, user)
      assert node.content == "some content"
      assert node.creator_id == user.id
    end

    test "with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Outline.create_node(@invalid_attrs)
    end
  end

  describe "update_node_content/2" do
    test "with valid data updates the node" do
      node = node_fixture()
      update_attrs = %{content: "some updated content"}

      assert {:ok, %Node{} = node} = Outline.update_node_content(node, update_attrs)
      assert node.content == "some updated content"
    end

    test "with invalid data returns error changeset" do
      node = node_fixture()
      assert {:error, %Ecto.Changeset{}} = Outline.update_node_content(node, %{content: nil})
      assert node == Outline.get_node!(node.uuid)
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

  describe "delete_node/1" do
    setup :complex_node_fixture

    test "deletes the node" do
      node = node_fixture()
      assert {:ok, %Node{}} = Outline.delete_node(node)
      assert_raise Ecto.NoResultsError, fn -> Outline.get_node!(node.uuid) end
    end

    test "next node must be updated", %{
      node_2: node_2,
      node_3: node_3,
      node_4: node_4
    } do
      assert node_4.prev_id == node_3.uuid

      assert {:ok, %Node{}} = Outline.delete_node(node_3)
      # reload nodes
      node_4 = Outline.get_node!(node_4.uuid)
      node_2 = Outline.get_node!(node_2.uuid)

      assert node_4.prev_id == node_2.uuid
    end

    test "works for last element in list", %{
      node_6: node_6
    } do
      episode_id = node_6.episode_id

      count_nodes =
        episode_id
        |> Outline.list_nodes_by_episode()
        |> Enum.count()

      assert {:ok, %Node{}} = Outline.delete_node(node_6)

      new_count_nodes =
        episode_id
        |> Outline.list_nodes_by_episode()
        |> Enum.count()

      assert new_count_nodes == count_nodes - 1
    end

    test "works for first element in list", %{
      node_1: node_1,
      node_2: node_2
    } do
      episode_id = node_1.episode_id

      count_nodes =
        episode_id
        |> Outline.list_nodes_by_episode()
        |> Enum.count()

      assert {:ok, %Node{}} = Outline.delete_node(node_1)

      new_count_nodes =
        episode_id
        |> Outline.list_nodes_by_episode()
        |> Enum.count()

      assert new_count_nodes == count_nodes - 1
      node_2 = Outline.get_node!(node_2.uuid)
      assert node_2.prev_id == nil
    end

    test "delete also child elements", %{
      node_3: node_3,
      nested_node_1: nested_node_1,
      nested_node_2: nested_node_2
    } do
      assert {:ok, %Node{}} = Outline.delete_node(node_3)

      assert_raise Ecto.NoResultsError, fn -> Outline.get_node!(nested_node_1.uuid) end
      assert_raise Ecto.NoResultsError, fn -> Outline.get_node!(nested_node_2.uuid) end
    end

    test "when top parent gets deleted the whole tree will be gone", %{
      node_1: node_1,
      node_4: node_4,
      node_6: node_6,
      nested_node_2: nested_node_2,
      parent: parent
    } do
      assert {:ok, %Node{}} = Outline.delete_node(parent)

      # test some of elements in the tree
      assert_raise Ecto.NoResultsError, fn -> Outline.get_node!(node_1.uuid) end
      assert_raise Ecto.NoResultsError, fn -> Outline.get_node!(node_4.uuid) end
      assert_raise Ecto.NoResultsError, fn -> Outline.get_node!(node_6.uuid) end
      assert_raise Ecto.NoResultsError, fn -> Outline.get_node!(nested_node_2.uuid) end
    end
  end

  describe "get_node_tree/1" do
    setup :complex_node_fixture

    test "returns all nodes from a episode", %{parent: parent} do
      episode_id = parent.episode_id
      assert {:ok, tree} = Outline.get_node_tree(episode_id)

      all_nodes = Outline.list_nodes_by_episode(episode_id)

      assert Enum.count(tree) == Enum.count(all_nodes)

      Enum.each(tree, fn node ->
        assert node.uuid ==
                 List.first(Enum.filter(all_nodes, fn n -> n.uuid == node.uuid end)).uuid
      end)
    end

    test "does not return a node from another episode", %{
      parent: parent
    } do
      episode_id = parent.episode_id
      other_node = node_fixture(parent_id: nil, prev_id: nil, content: "other content")
      assert other_node.episode_id != episode_id
      {:ok, tree} = Outline.get_node_tree(episode_id)
      assert Enum.filter(tree, fn n -> n.uuid == other_node.uuid end) == []
    end

    test "returns nodes sorted by level", %{parent: parent} do
      episode_id = parent.episode_id
      {:ok, tree} = Outline.get_node_tree(episode_id)

      Enum.reduce(tree, 0, fn node, current_level ->
        if node.parent_id != nil do
          parent = Enum.find(tree, fn n -> n.uuid == node.parent_id end)
          assert parent.level + 1 == node.level
        end

        assert node.level >= current_level
        node.level
      end)
    end
  end

  defp complex_node_fixture(_) do
    episode = PodcastFixtures.episode_fixture()
    parent = node_fixture(episode_id: episode.id, parent_id: nil, prev_id: nil)
    node_1 = node_fixture(episode_id: episode.id, parent_id: parent.uuid, prev_id: nil)
    node_2 = node_fixture(episode_id: episode.id, parent_id: parent.uuid, prev_id: node_1.uuid)
    node_3 = node_fixture(episode_id: episode.id, parent_id: parent.uuid, prev_id: node_2.uuid)
    node_4 = node_fixture(episode_id: episode.id, parent_id: parent.uuid, prev_id: node_3.uuid)
    node_5 = node_fixture(episode_id: episode.id, parent_id: parent.uuid, prev_id: node_4.uuid)
    node_6 = node_fixture(episode_id: episode.id, parent_id: parent.uuid, prev_id: node_5.uuid)

    nested_node_1 = node_fixture(episode_id: episode.id, parent_id: node_3.uuid, prev_id: nil)

    nested_node_2 =
      node_fixture(episode_id: episode.id, parent_id: node_3.uuid, prev_id: nested_node_1.uuid)

    %{
      node_1: node_1,
      node_2: node_2,
      node_3: node_3,
      node_4: node_4,
      node_5: node_5,
      node_6: node_6,
      nested_node_1: nested_node_1,
      nested_node_2: nested_node_2,
      parent: parent
    }
  end
end
