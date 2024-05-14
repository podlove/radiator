defmodule Radiator.Outline.EventConsumerTest do
  alias Radiator.Outline.NodeRepository
  use Radiator.DataCase

  alias Radiator.AccountsFixtures
  alias Radiator.EventStore
  alias Radiator.Outline.{Command, Dispatch, EventConsumer, EventProducer, NodeRepository}
  alias Radiator.Outline.Command.InsertNodeCommand
  alias Radiator.Outline.Event.NodeInsertedEvent
  alias Radiator.PodcastFixtures

  describe "handle_events/2" do
    setup :prepare_outline

    test "insert_node stores a node", %{episode: episode, user: user, event_id: event_id} do
      attributes = %{
        "title" => "Node Title",
        "content" => "Node Content",
        "episode_id" => episode.id
      }

      num_nodes = NodeRepository.count_nodes_by_episode(episode.id)
      command = Command.build("insert_node", attributes, user.id, event_id)
      EventConsumer.handle_events([command], 0, nil)

      # assert a node has been created
      assert num_nodes + 1 == NodeRepository.count_nodes_by_episode(episode.id)
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
      EventConsumer.handle_events([command], 0, nil)
      event = EventStore.list_event_data() |> hd()

      assert event.event_type == "NodeInsertedEvent"
      assert event.user_id == user.id
      assert event.data["content"] == new_content
    end

    test "handles previously enqueued events", %{episode: episode, user: user, event_id: event_id} do
      producer = start_supervised!({EventProducer, name: TestEventProducer})

      command = %InsertNodeCommand{
        event_id: event_id,
        user_id: user.id,
        payload: %{
          "title" => "Node Title",
          "content" => "Node Content",
          "episode_id" => episode.id
        }
      }

      Dispatch.subscribe(episode.id)
      EventProducer.enqueue(producer, command)

      start_supervised!(
        {EventConsumer, name: TestEventConsumer, subscribe_to: [{producer, max_demand: 1}]}
      )

      assert_receive(%NodeInsertedEvent{}, 1000)
    end
  end

  def prepare_outline(_) do
    episode = PodcastFixtures.episode_fixture()
    user = AccountsFixtures.user_fixture()
    event_id = Ecto.UUID.generate()
    %{episode: episode, user: user, event_id: event_id}
  end
end
