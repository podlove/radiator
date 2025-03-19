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
        "container_id" => episode.outline_node_container_id
      }

      num_nodes =
        NodeRepository.count_nodes_by_container(episode.outline_node_container_id)

      command = Command.build("insert_node", attributes, user.id, event_id)
      CommandProcessor.handle_events([command], 0, nil)

      # assert a node has been created
      assert num_nodes + 1 ==
               NodeRepository.count_nodes_by_container(episode.outline_node_container_id)
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
      node = OutlineFixtures.node_fixture(%{container_id: old_container.id})
      user = AccountsFixtures.user_fixture()

      command = %MoveNodeToContainerCommand{
        event_id: Ecto.UUID.generate(),
        user_id: user.id,
        container_id: new_container.id,
        node_id: node.uuid,
        parent_id: nil,
        prev_id: nil
      }

      CommandProcessor.handle_events([command], 0, nil)
      moved_node = Repo.reload!(node)
      assert moved_node.container_id == new_container.id
      assert moved_node.parent_id == nil
      assert moved_node.prev_id == nil
    end
  end

  def prepare_outline(_) do
    episode = PodcastFixtures.episode_fixture()
    user = AccountsFixtures.user_fixture()
    event_id = Ecto.UUID.generate()
    %{episode: episode, user: user, event_id: event_id}
  end
end
