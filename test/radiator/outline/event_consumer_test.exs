defmodule Radiator.Outline.EventConsumerTest do
  use Radiator.DataCase

  alias Radiator.Outline.Command
  # alias Radiator.Outline.Command.InsertNodeCommand
  alias Radiator.Outline.EventConsumer
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
  end
end
