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
      valid_attrs = %{content: "some content", episode_id: episode.id}

      assert {:ok, %Node{} = node} = NodeRepository.create_node(valid_attrs)
      assert node.content == "some content"
    end

    test "can have a creator" do
      episode = PodcastFixtures.episode_fixture()
      user = %{id: 2}
      valid_attrs = %{content: "some content", episode_id: episode.id, creator_id: user.id}

      assert {:ok, %Node{} = node} = NodeRepository.create_node(valid_attrs)
      assert node.content == "some content"
      assert node.creator_id == user.id
    end

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
end
