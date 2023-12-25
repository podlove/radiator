defmodule Radiator.OutlineTest do
  use Radiator.DataCase

  alias Radiator.Outline

  describe "outline_nodes" do
    alias Radiator.Outline.Node

    import Radiator.OutlineFixtures
    alias Radiator.PodcastFixtures

    @invalid_attrs %{content: nil}

    test "list_nodes/0 returns all nodes" do
      node = node_fixture()
      assert Outline.list_nodes() == [node]
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

    test "create_node/1 can have a creator" do
      episode = PodcastFixtures.episode_fixture()
      user = %{id: 2}
      valid_attrs = %{content: "some content", episode_id: episode.id}

      assert {:ok, %Node{} = node} = Outline.create_node(valid_attrs, user)
      assert node.content == "some content"
      assert node.creator_id == user.id
    end

    test "create_node/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Outline.create_node(@invalid_attrs)
    end

    test "update_node/2 with valid data updates the node" do
      node = node_fixture()
      update_attrs = %{content: "some updated content"}

      assert {:ok, %Node{} = node} = Outline.update_node(node, update_attrs)
      assert node.content == "some updated content"
    end

    test "update_node/2 with invalid data returns error changeset" do
      node = node_fixture()
      assert {:error, %Ecto.Changeset{}} = Outline.update_node(node, @invalid_attrs)
      assert node == Outline.get_node!(node.uuid)
    end

    test "delete_node/1 deletes the node" do
      node = node_fixture()
      assert {:ok, %Node{}} = Outline.delete_node(node)
      assert_raise Ecto.NoResultsError, fn -> Outline.get_node!(node.uuid) end
    end

    test "change_node/1 returns a node changeset" do
      node = node_fixture()
      assert %Ecto.Changeset{} = Outline.change_node(node)
    end
  end
end
