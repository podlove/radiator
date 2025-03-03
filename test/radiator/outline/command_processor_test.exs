defmodule Radiator.Outline.CommandProcessorTest do
  use Radiator.DataCase

  alias Radiator.AccountsFixtures
  alias Radiator.EventStore
  alias Radiator.Outline.Command.InsertNodeCommand
  alias Radiator.Outline.Command.MoveNodeToContainerCommand
  alias Radiator.Outline.Event.NodeInsertedEvent
  alias Radiator.Outline.NodeRepository
  alias Radiator.Outline.{Command, CommandProcessor, CommandQueue, Dispatch, NodeRepository}
  alias Radiator.OutlineFixtures
  alias Radiator.PodcastFixtures

  describe "handle_events/2" do
    setup :prepare_outline

    test "insert_node stores a node", %{episode: episode, user: user, event_id: event_id} do
      attributes = %{
        "title" => "Node Title",
        "content" => "Node Content",
        "episode_id" => episode.id
      }

      num_nodes =
        NodeRepository.count_nodes_by_outline_node_container(episode.outline_node_container_id)

      command = Command.build("insert_node", attributes, user.id, event_id)
      CommandProcessor.handle_events([command], 0, nil)

      # assert a node has been created
      assert num_nodes + 1 ==
               NodeRepository.count_nodes_by_outline_node_container(
                 episode.outline_node_container_id
               )
    end

    test "insert_node creates and stores an event", %{
      episode: episode,
      user: user,
      event_id: event_id
    } do
      new_content = "Node Content"

      attributes = %{
        "title" => "Node Title",
        "content" => new_content,
        "episode_id" => episode.id
      }

      command = Command.build("insert_node", attributes, user.id, event_id)
      CommandProcessor.handle_events([command], 0, nil)
      event = EventStore.list_event_data() |> hd()

      assert event.event_type == "NodeInsertedEvent"
      assert event.user_id == user.id
      assert event.data["content"] == new_content
    end

    test "handles previously enqueued events", %{episode: episode, user: user, event_id: event_id} do
      producer = start_supervised!({CommandQueue, name: TestCommandQueue})

      command = %InsertNodeCommand{
        event_id: event_id,
        user_id: user.id,
        payload: %{
          "title" => "Node Title",
          "content" => "Node Content",
          "episode_id" => episode.id
        }
      }

      Dispatch.subscribe()
      CommandQueue.enqueue(producer, command)

      start_supervised!(
        {CommandProcessor, name: TestCommandProcessor, subscribe_to: [{producer, max_demand: 1}]}
      )

      assert_receive(%NodeInsertedEvent{}, 1000)
    end
  end

  describe "move_node_to_container" do
    setup :complex_node_fixture

    test "successfully moves node to a new container" do
      # Setup test data
      old_container = OutlineFixtures.node_container_fixture()
      new_container = OutlineFixtures.node_container_fixture()
      node = OutlineFixtures.node_fixture(%{outline_node_container_id: old_container.id})
      user = AccountsFixtures.user_fixture()

      command = %MoveNodeToContainerCommand{
        event_id: Ecto.UUID.generate(),
        user_id: user.id,
        container_id: new_container.id,
        node_id: node.id,
        parent_id: nil,
        prev_id: nil
      }

      CommandProcessor.handle_events([command], 0, nil)
      # TODO fix handle result
      # assert event.old_container_id == old_container.id
      # assert event.new_container_id == new_container.id

      # Verify nodes were moved
      # assert Repo.reload!(node1).outline_node_container_id == new_container.id
      # assert Repo.reload!(node2).outline_node_container_id == new_container.id
    end

    # test "fails when nodes are from different containers" do
    #   container1 = node_container_fixture()
    #   container2 = node_container_fixture()
    #   new_container = node_container_fixture()

    #   node1 = node_fixture(%{outline_node_container_id: container1.id})
    #   node2 = node_fixture(%{outline_node_container_id: container2.id})

    #   command = %MoveNodesToContainerCommand{
    #     event_id: Ecto.UUID.generate(),
    #     user_id: "test_user",
    #     container_id: new_container.id,
    #     node_ids: [node1.uuid, node2.uuid]
    #   }

    #   assert {:error, :nodes_from_different_containers} =
    #            CommandProcessor.handle_events([command], 0, nil)
    # end
  end

  # describe "move_nodes_to_container" do
  #   test "successfully moves nodes to a new container" do
  #     # Setup test data
  #     old_container = node_container_fixture()
  #     new_container = node_container_fixture()
  #     node1 = node_fixture(%{outline_node_container_id: old_container.id})
  #     node2 = node_fixture(%{outline_node_container_id: old_container.id})
  #     user = AccountsFixtures.user_fixture()

  #     command = %MoveNodesToContainerCommand{
  #       event_id: Ecto.UUID.generate(),
  #       user_id: user.id,
  #       container_id: new_container.id,
  #       node_ids: [node1.uuid, node2.uuid]
  #     }

  #     CommandProcessor.handle_events([command], 0, nil)
  #     # TODO fix handle result
  #     # assert event.old_container_id == old_container.id
  #     # assert event.new_container_id == new_container.id

  #     # Verify nodes were moved
  #     assert Repo.reload!(node1).outline_node_container_id == new_container.id
  #     assert Repo.reload!(node2).outline_node_container_id == new_container.id
  #   end

  #   # test "fails when nodes are from different containers" do
  #   #   container1 = node_container_fixture()
  #   #   container2 = node_container_fixture()
  #   #   new_container = node_container_fixture()

  #   #   node1 = node_fixture(%{outline_node_container_id: container1.id})
  #   #   node2 = node_fixture(%{outline_node_container_id: container2.id})

  #   #   command = %MoveNodesToContainerCommand{
  #   #     event_id: Ecto.UUID.generate(),
  #   #     user_id: "test_user",
  #   #     container_id: new_container.id,
  #   #     node_ids: [node1.uuid, node2.uuid]
  #   #   }

  #   #   assert {:error, :nodes_from_different_containers} =
  #   #            CommandProcessor.handle_events([command], 0, nil)
  #   # end
  # end

  def prepare_outline(_) do
    episode = PodcastFixtures.episode_fixture()
    user = AccountsFixtures.user_fixture()
    event_id = Ecto.UUID.generate()
    %{episode: episode, user: user, event_id: event_id}
  end
end
