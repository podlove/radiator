defmodule Radiator.OutlineTest do
  use Radiator.DataCase

  alias Radiator.Outline

  alias Radiator.Outline.Node

  import Radiator.OutlineFixtures
  alias Radiator.PodcastFixtures

  @invalid_attrs %{content: nil}

  describe "list_nodes/0" do
    test "returns all nodes" do
      node = node_fixture()
      assert Outline.list_nodes() == [node]
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
      assert {:error, %Ecto.Changeset{}} = Outline.update_node_content(node, @invalid_attrs)
      assert node == Outline.get_node!(node.uuid)
    end
  end

  describe "move_node/2" do
    test "moves node to another parent" do
      node = node_fixture()
      new_parent = node_fixture(episode_id: node.episode_id)

      assert {:ok, %Node{} = node} = Outline.move_node(node, new_parent)
      assert node.parent_id == new_parent.uuid
    end

    test "update_node_content/2 with parent from another episode returns error changeset" do
      node = node_fixture()
      new_bad_parent = node_fixture()
      assert node.episode_id != new_bad_parent.episode_id

      assert {:error, %Ecto.Changeset{}} = Outline.move_node(node, new_bad_parent)
      assert node == Outline.get_node!(node.uuid)
    end
  end

  describe "delete_node/1" do
    test "deletes the node" do
      node = node_fixture()
      assert {:ok, %Node{}} = Outline.delete_node(node)
      assert_raise Ecto.NoResultsError, fn -> Outline.get_node!(node.uuid) end
    end
  end
end
