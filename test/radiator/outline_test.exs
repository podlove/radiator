defmodule Radiator.OutlineTest do
  use Radiator.DataCase

  alias Radiator.Outline

  describe "outline_nodes" do
    alias Radiator.Outline.Node

    import Radiator.OutlineFixtures
    alias Radiator.PodcastFixtures

    @invalid_attrs %{episode_id: nil}

    test "list_nodes/0 returns all nodes" do
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

    test "get_node!/1 returns the node with given id" do
      node = node_fixture()
      assert Outline.get_node!(node.uuid) == node
    end

    test "create_node/1 with valid data creates a node" do
      episode = PodcastFixtures.episode_fixture()
      valid_attrs = %{content: "some content", episode_id: episode.id}

      assert {:ok, %Node{} = node} = Outline.create_node(valid_attrs)
      assert node.content == "some content"
    end

    test "create_node/1 trims whitespace from content" do
      episode = PodcastFixtures.episode_fixture()
      valid_attrs = %{content: "  some content  ", episode_id: episode.id}

      assert {:ok, %Node{} = node} = Outline.create_node(valid_attrs)
      assert node.content == "some content"
    end

    test "create_node/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Outline.create_node(@invalid_attrs)
    end

    test "update_node_content/2 with valid data updates the node" do
      node = node_fixture()
      update_attrs = %{content: "some updated content"}

      assert {:ok, %Node{} = node} = Outline.update_node_content(node, update_attrs)
      assert node.content == "some updated content"
    end

    test "update_node_content/2 with invalid data returns error changeset" do
      node = node_fixture()
      assert {:error, %Ecto.Changeset{}} = Outline.update_node_content(node, @invalid_attrs)
      assert node == Outline.get_node!(node.uuid)
    end

    test "delete_node/1 deletes the node" do
      node = node_fixture()
      assert {:ok, %Node{}} = Outline.delete_node(node)
      assert_raise Ecto.NoResultsError, fn -> Outline.get_node!(node.uuid) end
    end
  end
end
