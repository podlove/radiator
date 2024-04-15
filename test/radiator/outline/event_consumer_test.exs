defmodule Radiator.Outline.EventConsumerTest do
  use Radiator.DataCase

  alias Radiator.AccountsFixtures
  alias Radiator.Outline.Command
  alias Radiator.Outline.Command.InsertNodeCommand
  alias Radiator.Outline.Dispatch
  alias Radiator.Outline.Event.NodeInsertedEvent
  alias Radiator.Outline.EventConsumer
  alias Radiator.Outline.EventProducer
  alias Radiator.PodcastFixtures

  describe "handle_events/2" do
    test "insert_node" do
      episode = PodcastFixtures.episode_fixture()

      attributes = %{
        "title" => "Node Title",
        "content" => "Node Content",
        "episode_id" => episode.id
      }

      user_id = "user_id"
      event_id = "event_id"

      command = Command.build("insert_node", attributes, user_id, event_id)
      EventConsumer.handle_events([command], 0, nil)
      # assert a node has been created
      # assert an event has been created (and be stored)
    end

    test "handles previously enqueued events" do
      producer = start_supervised!({EventProducer, name: TestEventProducer})

      episode = PodcastFixtures.episode_fixture()
      user = AccountsFixtures.user_fixture()
      event_id = Ecto.UUID.generate()

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
end
