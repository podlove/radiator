defmodule Radiator.OutlineTest do
  use Radiator.DataCase

  import Ecto.Query, warn: false
  import Radiator.OutlineFixtures
  import Radiator.PodcastFixtures

  alias Radiator.Outline
  alias Radiator.Outline.Node
  alias Radiator.Outline.NodeRepoResult
  alias Radiator.Outline.NodeRepository
  alias Radiator.Podcast

  describe "node_tree" do
    test "generate from template" do
      %{id: episode_id, show_id: show_id} = episode_fixture()

      nodes =
        [
          "node-1",
          {"node-2", ["node-2_1", "node-2_2", "node-2_3"]},
          "node-3",
          {"node-4",
           [
             {
               "node-4_1",
               [
                 "node-4_1_1",
                 {"node-4_1_2", ["node-4_1_2_1"]}
               ]
             },
             "node-4_2"
           ]},
          "node-5"
        ]
        |> node_tree_fixture(%{episode_id: episode_id, show_id: show_id})

      assert length(nodes) == 13
      assert Enum.all?(nodes, &match?(%Node{episode_id: ^episode_id}, &1))

      assert [
               %{uuid: uuid_1, content: "node-1", parent_id: nil, prev_id: nil},
               %{uuid: uuid_2, content: "node-2", parent_id: nil, prev_id: uuid_1},
               %{uuid: uuid_2_1, content: "node-2_1", parent_id: uuid_2, prev_id: nil},
               %{uuid: uuid_2_2, content: "node-2_2", parent_id: nil, prev_id: uuid_2_1},
               %{uuid: _, content: "node-2_3", parent_id: nil, prev_id: uuid_2_2},
               %{uuid: uuid_3, content: "node-3", parent_id: nil, prev_id: uuid_2},
               %{uuid: uuid_4, content: "node-4", parent_id: nil, prev_id: uuid_3},
               %{uuid: uuid_4_1, content: "node-4_1", parent_id: uuid_4, prev_id: nil},
               %{uuid: uuid_4_1_1, content: "node-4_1_1", parent_id: uuid_4_1, prev_id: nil},
               %{uuid: uuid_4_1_2, content: "node-4_1_2", parent_id: nil, prev_id: uuid_4_1_1},
               %{uuid: _, content: "node-4_1_2_1", parent_id: uuid_4_1_2, prev_id: nil},
               %{uuid: _, content: "node-4_2", parent_id: nil, prev_id: uuid_4_1},
               %{uuid: _, content: "node-5", parent_id: nil, prev_id: uuid_4}
             ] = nodes
    end
  end

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

    test "the show_id gets set - even if not given", %{
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

      episode = Podcast.get_episode!(node_3.episode_id)
      assert new_node.show_id == episode.show_id
    end

    test "the next node - if existing - changes its prev_id and gets returned", %{
      node_2: node_2,
      node_3: node_3
    } do
      node_attrs = %{
        "content" => "new node",
        "episode_id" => node_2.episode_id,
        "prev_id" => node_2.uuid
      }

      {:ok, %{next: %{uuid: next_id}, node: new_node}} = Outline.insert_node(node_attrs)
      assert node_3.uuid == next_id
      assert NodeRepository.get_node!(node_3.uuid).prev_id == new_node.uuid
    end

    test "if prev_id has been given the parent_id can be omitted", %{
      node_3: node_3,
      nested_node_1: nested_node_1
    } do
      node_attrs = %{
        "content" => "new node",
        "episode_id" => node_3.episode_id,
        "prev_id" => nested_node_1.uuid
      }

      {:ok, %{node: new_node}} = Outline.insert_node(node_attrs)
      assert new_node.parent_id == node_3.uuid
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
      episode: episode,
      parent_node: parent_node,
      nested_node_1: nested_node_1
    } do
      count_nodes = NodeRepository.count_nodes_by_episode(parent_node.episode_id)

      {:ok, another_episode} =
        Podcast.create_episode(%{title: "current episode", show_id: episode.show_id, number: 23})

      node_attrs = %{
        "content" => "new node",
        "episode_id" => another_episode.id,
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
      {:ok, _} = Outline.move_node(node_2.uuid, prev_id: nil, parent_id: node_2.parent_id)

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
      {:ok, _} = Outline.move_node(node_1.uuid, prev_id: node_2.uuid, parent_id: node_1.parent_id)

      # reload nodes
      node_1 = Repo.reload!(node_1)
      node_2 = Repo.reload!(node_2)

      assert node_1.prev_id == node_2.uuid
      assert node_2.prev_id == nil
    end

    test "if prev_id has been given the parent_id can be omitted", %{
      node_1: node_1,
      node_2: node_2
    } do
      {:ok, _} = Outline.move_node(node_1.uuid, prev_id: node_2.uuid)

      # reload nodes
      node_1 = Repo.reload!(node_1)
      node_2 = Repo.reload!(node_2)

      assert node_1.prev_id == node_2.uuid
      assert node_2.prev_id == nil
    end

    test "error when nothing should change", %{
      node_1: node_1,
      node_2: node_2
    } do
      {:error, :noop} =
        Outline.move_node(node_2.uuid, prev_id: node_1.uuid, parent_id: node_2.parent_id)

      # reload nodes
      node_1 = Repo.reload!(node_1)
      node_2 = Repo.reload!(node_2)

      assert node_2.prev_id == node_1.uuid
      assert node_1.prev_id == nil
    end

    test "error when nothing should change - other way around", %{
      node_1: node_1,
      node_2: node_2
    } do
      {:error, :noop} = Outline.move_node(node_1.uuid, prev_id: nil, parent_id: node_2.parent_id)

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
      {:ok, _} = Outline.move_node(node_2.uuid, prev_id: nil, parent_id: node_1.uuid)

      # reload nodes
      node_1 = Repo.reload!(node_1)
      node_2 = Repo.reload!(node_2)

      assert node_1.prev_id == nil
      assert node_2.prev_id == nil

      assert node_1.parent_id == nil
      assert node_2.parent_id == node_1.uuid
    end

    test "error when parent and prev are the same", %{
      node_1: node_1,
      node_2: node_2
    } do
      {:error, :parent_and_prev_not_consistent} =
        Outline.move_node(node_2.uuid, prev_id: node_1.uuid, parent_id: node_1.uuid)
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
      {:ok, _} = Outline.move_node(node_4.uuid, prev_id: node_2.uuid, parent_id: node_4.parent_id)

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
    # after  1 2 4 3 5
    test "move node 4 within list to node 2, but ommitting the parent_id", %{
      node_2: node_2,
      node_3: node_3,
      node_4: node_4,
      node_5: node_5
    } do
      {:ok, _} = Outline.move_node(node_4.uuid, prev_id: node_2.uuid)

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
      {:ok, _} = Outline.move_node(node_4.uuid, prev_id: nil, parent_id: node_4.parent_id)

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
      {:ok, _} = Outline.move_node(node_2.uuid, prev_id: node_5.uuid, parent_id: node_2.parent_id)

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
    # after  1 3 4 5 2
    test "move node 2 to the end of the list but ommitting the parent_id", %{
      node_1: node_1,
      node_2: node_2,
      node_3: node_3,
      node_4: node_4,
      node_5: node_5
    } do
      {:ok, _} = Outline.move_node(node_2.uuid, prev_id: node_5.uuid)

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
      {:ok, _} = Outline.move_node(node_1.uuid, prev_id: node_5.uuid, parent_id: node_2.parent_id)

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
    # after  2 3 4 5 1
    test "move first node to the end of the list and ommitting the parent_id", %{
      node_1: node_1,
      node_2: node_2,
      node_3: node_3,
      node_4: node_4,
      node_5: node_5
    } do
      {:ok, _} = Outline.move_node(node_1.uuid, prev_id: node_5.uuid)

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
      {:ok, _} = Outline.move_node(node_5.uuid, prev_id: nil, parent_id: node_2.parent_id)

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
      {:ok, _} = Outline.move_node(nested_node_1.uuid, prev_id: nil, parent_id: node_2.uuid)

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
      {:ok, _} = Outline.move_node(node_3.uuid, prev_id: nil, parent_id: nil)

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

    test "move node with child elements to top also works without parent_id", %{
      parent_node: parent_node,
      node_3: node_3,
      nested_node_1: nested_node_1,
      nested_node_2: nested_node_2
    } do
      {:ok, _} = Outline.move_node(node_3.uuid, prev_id: nil)

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
        Outline.move_node(node_1.uuid, prev_id: node_5.uuid, parent_id: node_2.parent_id)

      assert node_result.node.uuid == node_1.uuid
      assert node_result.old_prev == nil
      assert node_result.old_next.uuid == node_2.uuid
    end

    test "error when prev id is the same as node id", %{
      node_1: node_1
    } do
      {:error, :self_link} =
        Outline.move_node(node_1.uuid, prev_id: node_1.uuid, parent_id: node_1.parent_id)
    end

    test "error when parent id is the same as node id", %{
      node_1: node_1,
      node_5: node_5
    } do
      {:error, :circle_link} =
        Outline.move_node(node_1.uuid, prev_id: node_5.uuid, parent_id: node_1.uuid)
    end

    test "error when parent is a child of new node", %{
      node_1: node_1,
      node_5: node_5,
      nested_node_1: nested_node_1
    } do
      {:error, :parent_and_prev_not_consistent} =
        Outline.move_node(node_1.uuid, prev_id: node_5.uuid, parent_id: nested_node_1.uuid)
    end

    test "error when parent is on same level of new node", %{
      node_1: node_1,
      node_5: node_5,
      node_3: node_3
    } do
      {:error, :parent_and_prev_not_consistent} =
        Outline.move_node(node_1.uuid, prev_id: node_5.uuid, parent_id: node_3.uuid)
    end

    test "error when new prev is not a direct child of new parent", %{
      parent_node: parent_node,
      node_1: node_1,
      nested_node_1: nested_node_1
    } do
      {:error, :parent_and_prev_not_consistent} =
        Outline.move_node(node_1.uuid, prev_id: nested_node_1.uuid, parent_id: parent_node.uuid)
    end

    test "error when new new parent is nil but prev is not on level 1", %{
      node_1: node_1,
      nested_node_1: nested_node_1
    } do
      {:error, :parent_and_prev_not_consistent} =
        Outline.move_node(node_1.uuid, prev_id: nested_node_1.uuid, parent_id: nil)
    end
  end

  describe "split_node/2" do
    setup :simple_node_fixture

    test "returns updated node", %{
      node_1: node_1
    } do
      start = 2

      {:ok, %Radiator.Outline.NodeRepoResult{node: node}} =
        Outline.split_node(node_1.uuid, {2, 3})

      assert node.uuid == node_1.uuid
      assert node.episode_id == node_1.episode_id
      {new_content, _} = String.split_at(node_1.content, start)
      assert node.content == new_content
    end
  end

  describe "indent_node/1 - simple context" do
    setup :simple_node_fixture

    # before 1 2
    # intend node 2: 1 parentof 2
    test "intended node is now child of old previous node", %{
      node_1: node_1,
      node_2: node_2
    } do
      assert node_2.parent_id == nil
      assert node_2.prev_id == node_1.uuid

      {:ok, _} = Outline.indent_node(node_2.uuid)

      # reload nodes
      node_1 = Repo.reload!(node_1)
      node_2 = Repo.reload!(node_2)

      assert node_2.parent_id == node_1.uuid
      assert node_2.prev_id == nil
    end

    # before 1 2
    # intend node 2: 1 parentof 2
    test "returns changed nodes in result", %{
      node_1: node_1,
      node_2: node_2
    } do
      {:ok, result} = Outline.indent_node(node_2.uuid)

      assert result.node.parent_id == node_1.uuid
      assert result.old_prev.uuid == node_1.uuid
      assert result.old_prev.uuid == node_1.uuid
    end

    # before 1 2
    # intend node 1: error because node 1 is the first in the list
    test "intended node does not work when there is no previous node", %{
      node_1: node_1,
      node_2: node_2
    } do
      {:error, :no_prev_node} = Outline.indent_node(node_1.uuid)

      node_1 = Repo.reload!(node_1)
      node_2 = Repo.reload!(node_2)

      assert node_1.parent_id == nil
      assert node_1.prev_id == nil
      assert node_2.parent_id == nil
      assert node_2.prev_id == node_1.uuid
    end
  end

  describe "indent_node/1" do
    setup :complex_node_fixture

    #  1 2 3 4 5
    test "intend node 3 moves under node 2 and does not change nested nodes", %{
      node_2: node_2,
      node_3: node_3,
      node_4: node_4,
      nested_node_1: nested_node_1,
      nested_node_2: nested_node_2
    } do
      {:ok, _} = Outline.indent_node(node_3.uuid)

      # reload nodes
      node_4 = Repo.reload!(node_4)
      node_3 = Repo.reload!(node_3)
      node_2 = Repo.reload!(node_2)
      nested_node_1 = Repo.reload!(nested_node_1)
      nested_node_2 = Repo.reload!(nested_node_2)

      assert node_3.prev_id == nil
      assert node_3.parent_id == node_2.uuid
      assert node_4.prev_id == node_2.uuid
      assert nested_node_1.prev_id == nil
      assert nested_node_2.prev_id == nested_node_1.uuid
      assert nested_node_1.parent_id == node_3.uuid
      assert nested_node_2.parent_id == node_3.uuid
    end

    test "intend node 4 moves under node 3 and after existing nested nodes", %{
      node_3: node_3,
      node_4: node_4,
      nested_node_2: nested_node_2
    } do
      {:ok, _} = Outline.indent_node(node_4.uuid)

      # reload nodes
      node_4 = Repo.reload!(node_4)
      node_3 = Repo.reload!(node_3)
      nested_node_2 = Repo.reload!(nested_node_2)

      assert node_4.prev_id == nested_node_2.uuid
      assert node_4.parent_id == node_3.uuid
    end

    test "indent node 2 returns the correct result", %{
      parent_node: parent_node,
      node_1: node_1,
      node_2: node_2,
      node_3: node_3
    } do
      {:ok, result} = Outline.indent_node(node_2.uuid)
      assert result.node.parent_id == node_1.uuid
      assert result.node.prev_id == nil
      assert result.old_next.uuid == node_3.uuid
      assert result.old_next.parent_id == parent_node.uuid
      assert result.old_next.prev_id == node_1.uuid
    end
  end

  describe "outdent_node/1 - simple context" do
    setup :simple_node_fixture_hierachical

    test "outdent_node node moves node to same level as previous parent", %{
      node_1: node_1,
      node_2: node_2
    } do
      assert node_2.parent_id == node_1.uuid
      assert node_2.prev_id == nil

      {:ok, _} = Outline.outdent_node(node_2.uuid)

      # reload nodes
      node_1 = Repo.reload!(node_1)
      node_2 = Repo.reload!(node_2)

      assert node_2.parent_id == nil
      assert node_2.prev_id == node_1.uuid
    end

    test "outdent_node needs a parent node", %{
      node_1: node_1
    } do
      assert node_1.parent_id == nil
      {:error, :no_parent_node} = Outline.outdent_node(node_1.uuid)
    end
  end

  describe "outdent_node/1" do
    setup :complex_node_fixture

    test "outdent nested node 1", %{
      parent_node: parent_node,
      node_3: node_3,
      node_4: node_4,
      nested_node_1: nested_node_1,
      nested_node_2: nested_node_2
    } do
      {:ok, _} = Outline.outdent_node(nested_node_1.uuid)

      # reload nodes
      node_4 = Repo.reload!(node_4)
      node_3 = Repo.reload!(node_3)
      nested_node_1 = Repo.reload!(nested_node_1)
      nested_node_2 = Repo.reload!(nested_node_2)

      assert nested_node_1.prev_id == node_3.uuid
      assert nested_node_1.parent_id == parent_node.uuid

      assert nested_node_2.prev_id == nil
      assert nested_node_2.parent_id == nested_node_1.uuid

      assert node_4.prev_id == nested_node_1.uuid
    end

    test "outdent nested node with a next node makes next node new child", %{
      episode: episode,
      parent_node: parent_node,
      node_3: node_3,
      node_4: node_4,
      nested_node_1: nested_node_1,
      nested_node_2: nested_node_2
    } do
      nested_node_3 =
        node_fixture(
          episode_id: episode.id,
          parent_id: node_3.uuid,
          prev_id: nested_node_2.uuid,
          content: "nested_node_3"
        )

      nested_node_4 =
        node_fixture(
          episode_id: episode.id,
          parent_id: node_3.uuid,
          prev_id: nested_node_3.uuid,
          content: "nested_node_4"
        )

      {:ok, _} = Outline.outdent_node(nested_node_2.uuid)

      # reload nodes
      node_4 = Repo.reload!(node_4)
      node_3 = Repo.reload!(node_3)
      nested_node_1 = Repo.reload!(nested_node_1)
      nested_node_2 = Repo.reload!(nested_node_2)
      nested_node_3 = Repo.reload!(nested_node_3)
      nested_node_4 = Repo.reload!(nested_node_4)

      assert nested_node_1.prev_id == nil
      assert nested_node_1.parent_id == node_3.uuid

      assert nested_node_2.prev_id == node_3.uuid
      assert nested_node_2.parent_id == parent_node.uuid

      assert node_4.prev_id == nested_node_2.uuid

      assert nested_node_3.prev_id == nil
      assert nested_node_3.parent_id == nested_node_2.uuid

      assert nested_node_4.prev_id == nested_node_3.uuid
      assert nested_node_4.parent_id == nested_node_2.uuid
    end

    test "outdent node 3 with children", %{
      parent_node: parent_node,
      node_3: node_3,
      node_4: node_4,
      nested_node_1: nested_node_1,
      nested_node_2: nested_node_2
    } do
      {:ok, _result} = Outline.outdent_node(node_3.uuid)

      # reload nodes
      node_4 = Repo.reload!(node_4)
      node_3 = Repo.reload!(node_3)
      nested_node_1 = Repo.reload!(nested_node_1)
      nested_node_2 = Repo.reload!(nested_node_2)

      assert node_3.prev_id == parent_node.uuid
      assert node_3.parent_id == nil

      assert nested_node_1.prev_id == nil
      assert nested_node_1.parent_id == node_3.uuid
      assert nested_node_2.prev_id == nested_node_1.uuid
      assert nested_node_2.parent_id == node_3.uuid

      assert node_4.prev_id == nested_node_2.uuid
      assert node_4.parent_id == node_3.uuid
    end

    test "outdent nested 1 returns correct result", %{
      parent_node: parent_node,
      node_3: node_3,
      nested_node_1: nested_node_1,
      nested_node_2: nested_node_2
    } do
      {:ok, result} = Outline.outdent_node(nested_node_1.uuid)
      assert result.node.parent_id == parent_node.uuid
      assert result.node.prev_id == node_3.uuid

      result_nested_node_2 =
        Enum.find(result.children, fn node -> node.uuid == nested_node_2.uuid end)

      assert result_nested_node_2.parent_id == nested_node_1.uuid
      assert result_nested_node_2.prev_id == nil
    end
  end

  describe "move_up/1" do
    setup :complex_node_fixture

    test "moves node up", %{
      node_1: node_1,
      node_2: node_2,
      node_3: node_3,
      node_4: node_4
    } do
      assert node_2.prev_id == node_1.uuid
      assert node_3.prev_id == node_2.uuid
      assert node_4.prev_id == node_3.uuid

      {:ok, _} = Outline.move_up(node_3.uuid)

      # reload nodes
      node_2 = Repo.reload!(node_2)
      node_3 = Repo.reload!(node_3)
      node_4 = Repo.reload!(node_4)

      assert node_2.prev_id == node_3.uuid
      assert node_3.prev_id == node_1.uuid
      assert node_4.prev_id == node_2.uuid
    end

    test "moves node up returns correct result", %{
      node_1: node_1,
      node_2: node_2,
      node_3: node_3,
      node_4: node_4
    } do
      {:ok, response} = Outline.move_up(node_3.uuid)
      assert response.node.prev_id == node_1.uuid
      assert response.node.uuid == node_3.uuid
      assert response.old_prev.uuid == node_2.uuid
      assert response.old_next.uuid == node_4.uuid
    end

    test "cannot move up when there is no previous node", %{
      nested_node_1: nested_node_1,
      nested_node_2: nested_node_2
    } do
      assert nested_node_1.prev_id == nil
      assert nested_node_2.prev_id == nested_node_1.uuid

      {:error, :no_previous_node} = Outline.move_up(nested_node_1.uuid)

      # reload nodes
      nested_node_1 = Repo.reload!(nested_node_1)
      nested_node_2 = Repo.reload!(nested_node_2)

      assert nested_node_1.prev_id == nil
      assert nested_node_2.prev_id == nested_node_1.uuid
    end

    test "moves node up when there is no next node", %{
      nested_node_1: nested_node_1,
      nested_node_2: nested_node_2
    } do
      assert nested_node_1.prev_id == nil
      assert nested_node_2.prev_id == nested_node_1.uuid

      {:ok, _} = Outline.move_up(nested_node_2.uuid)

      # reload nodes
      nested_node_1 = Repo.reload!(nested_node_1)
      nested_node_2 = Repo.reload!(nested_node_2)

      assert nested_node_2.prev_id == nil
      assert nested_node_1.prev_id == nested_node_2.uuid
    end
  end

  describe "move_down/1" do
    setup :complex_node_fixture

    # moving node_2 down should be the same as moving node_3 up
    test "moves node down", %{
      node_1: node_1,
      node_2: node_2,
      node_3: node_3,
      node_4: node_4
    } do
      assert node_2.prev_id == node_1.uuid
      assert node_3.prev_id == node_2.uuid
      assert node_4.prev_id == node_3.uuid

      {:ok, _} = Outline.move_down(node_2.uuid)

      # reload nodes
      node_2 = Repo.reload!(node_2)
      node_3 = Repo.reload!(node_3)
      node_4 = Repo.reload!(node_4)

      assert node_2.prev_id == node_3.uuid
      assert node_3.prev_id == node_1.uuid
      assert node_4.prev_id == node_2.uuid
    end

    test "moves node down returns correct result", %{
      node_2: node_2,
      node_3: node_3,
      node_4: node_4
    } do
      {:ok, response} = Outline.move_down(node_2.uuid)
      assert response.node.uuid == node_2.uuid
      assert response.node.prev_id == node_3.uuid
      assert response.old_prev == nil
      assert response.old_next.uuid == node_3.uuid
      assert response.next.uuid == node_4.uuid
    end

    test "cannot move down when there is no next node", %{
      nested_node_1: nested_node_1,
      nested_node_2: nested_node_2
    } do
      assert nested_node_1.prev_id == nil
      assert nested_node_2.prev_id == nested_node_1.uuid

      {:error, :no_next_node} = Outline.move_down(nested_node_2.uuid)

      # reload nodes, should be no changes
      nested_node_1 = Repo.reload!(nested_node_1)
      nested_node_2 = Repo.reload!(nested_node_2)

      assert nested_node_1.prev_id == nil
      assert nested_node_2.prev_id == nested_node_1.uuid
    end

    test "moves node down when there is no previous node", %{
      nested_node_1: nested_node_1,
      nested_node_2: nested_node_2
    } do
      assert nested_node_1.prev_id == nil
      assert nested_node_2.prev_id == nested_node_1.uuid

      {:ok, _} = Outline.move_down(nested_node_1.uuid)

      # reload nodes
      nested_node_1 = Repo.reload!(nested_node_1)
      nested_node_2 = Repo.reload!(nested_node_2)

      assert nested_node_2.prev_id == nil
      assert nested_node_1.prev_id == nested_node_2.uuid
    end
  end

  describe "remove_node/1" do
    setup :complex_node_fixture

    test "deletes the node" do
      node = node_fixture()
      assert %NodeRepoResult{} = Outline.remove_node(node)
      assert_raise Ecto.NoResultsError, fn -> NodeRepository.get_node!(node.uuid) end
    end

    test "next node must be updated", %{
      node_2: node_2,
      node_3: node_3,
      node_4: node_4
    } do
      assert node_4.prev_id == node_3.uuid

      assert %NodeRepoResult{} = Outline.remove_node(node_3)
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
      assert %NodeRepoResult{} = Outline.remove_node(node_6)
      new_count_nodes = NodeRepository.count_nodes_by_episode(episode_id)
      assert new_count_nodes == count_nodes - 1
    end

    test "works for first element in list", %{
      node_1: node_1,
      node_2: node_2
    } do
      episode_id = node_1.episode_id

      count_nodes = NodeRepository.count_nodes_by_episode(episode_id)
      assert %NodeRepoResult{} = Outline.remove_node(node_1)
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
      assert %NodeRepoResult{} = Outline.remove_node(node_3)

      assert_raise Ecto.NoResultsError, fn -> NodeRepository.get_node!(nested_node_1.uuid) end
      assert_raise Ecto.NoResultsError, fn -> NodeRepository.get_node!(nested_node_2.uuid) end
    end

    test "returns all deleted child elements", %{
      node_3: node_3,
      nested_node_1: nested_node_1,
      nested_node_2: nested_node_2
    } do
      assert %NodeRepoResult{children: children} = Outline.remove_node(node_3)
      assert Enum.count(children) == 2
      assert Enum.member?(children, nested_node_1)
      assert Enum.member?(children, nested_node_2)
    end

    test "when top parent gets deleted the whole tree will be gone", %{
      node_1: node_1,
      node_4: node_4,
      node_6: node_6,
      nested_node_2: nested_node_2,
      parent_node: parent_node
    } do
      assert %NodeRepoResult{} = Outline.remove_node(parent_node)

      # test some of elements in the tree
      assert_raise Ecto.NoResultsError, fn -> NodeRepository.get_node!(node_1.uuid) end
      assert_raise Ecto.NoResultsError, fn -> NodeRepository.get_node!(node_4.uuid) end
      assert_raise Ecto.NoResultsError, fn -> NodeRepository.get_node!(node_6.uuid) end
      assert_raise Ecto.NoResultsError, fn -> NodeRepository.get_node!(nested_node_2.uuid) end
    end

    test "returns all recursive deleted child elements in NodeRepoResult", %{
      node_1: node_1,
      node_6: node_6,
      nested_node_1: nested_node_1,
      nested_node_2: nested_node_2,
      parent_node: parent_node
    } do
      assert %NodeRepoResult{children: children} = Outline.remove_node(parent_node)
      assert Enum.member?(children, node_1)
      assert Enum.member?(children, node_6)
      assert Enum.member?(children, nested_node_1)
      assert Enum.member?(children, nested_node_2)
      refute Enum.member?(children, parent_node)
    end
  end

  describe "list_nodes_by_episode_sorted/1" do
    setup :complex_node_fixture

    test "returns all nodes from a episode", %{parent_node: parent_node} do
      episode_id = parent_node.episode_id
      tree = Outline.list_nodes_by_episode_sorted(episode_id)

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
      tree = Outline.list_nodes_by_episode_sorted(episode_id)
      assert Enum.filter(tree, fn n -> n.uuid == other_node.uuid end) == []
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

      _third_parent_node =
        node_fixture(
          parent_id: nil,
          prev_id: other_parent_node.uuid,
          episode_id: episode_id,
          content: "even another root element"
        )

      tree = Outline.list_nodes_by_episode_sorted(parent_node.episode_id)

      num_nodes_without_parents =
        tree
        |> Enum.count(fn n -> n.parent_id == nil end)

      assert num_nodes_without_parents == 3
    end
  end

  describe "order_child_nodes/1" do
    setup :complex_node_fixture

    test "get child nodes in correct order" do
      episode = episode_fixture()

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
        Outline.move_node(node_3.uuid, prev_id: node_2.uuid, parent_id: node_1.uuid)

      assert node_1 |> Outline.order_child_nodes() |> Enum.map(& &1.content) ==
               ["node_2", "node_3"]
    end
  end

  describe "get_node_id_above/1" do
    setup :complex_node_fixture

    test "returns the node above the given node", %{
      node_2: node_2,
      node_3: node_3
    } do
      assert node_2 == Outline.get_node_above(node_3.uuid)
    end

    test "returns parent node if there is no prev", %{
      nested_node_1: nested_node_1,
      node_3: node_3
    } do
      assert node_3 == Outline.get_node_above(nested_node_1.uuid)
    end

    test "returns last child node of prev has children", %{
      nested_node_2: nested_node_2,
      node_4: node_4
    } do
      assert nested_node_2 == Outline.get_node_above(node_4.uuid)
    end

    test "returns nil if there is no node above", %{
      parent_node: parent_node
    } do
      assert nil == Outline.get_node_above(parent_node.uuid)
    end
  end

  describe "get_node_below/1" do
    setup :complex_node_fixture

    test "returns the node below the given node", %{
      node_2: node_2,
      node_3: node_3
    } do
      assert node_3 == Outline.get_node_below(node_2.uuid)
    end

    test "returns first child node if there is no next", %{
      nested_node_1: nested_node_1,
      node_3: node_3
    } do
      assert nested_node_1 == Outline.get_node_below(node_3.uuid)
    end

    test "returns next of parent of there is no next node", %{
      nested_node_2: nested_node_2,
      node_4: node_4
    } do
      assert node_4 == Outline.get_node_below(nested_node_2.uuid)
    end

    test "returns first child node if next has children", %{
      node_3: node_3,
      nested_node_1: nested_node_1
    } do
      assert nested_node_1 == Outline.get_node_below(node_3.uuid)
    end

    test "first child of root node", %{
      parent_node: parent_node,
      node_1: node_1
    } do
      assert node_1 == Outline.get_node_below(parent_node.uuid)
    end

    test "returns first ch if there is no node below", %{node_6: node_6} do
      assert nil == Outline.get_node_below(node_6.uuid)
    end
  end
end
