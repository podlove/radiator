defmodule Radiator.Outline.DispatchTest do
  @moduledoc false

  use Radiator.DataCase

  import Radiator.AccountsFixtures
  import Radiator.PodcastFixtures

  # alias Radiator.Outline
  # alias Radiator.Outline.Dispatch
  # alias Radiator.Outline.Node

  describe "outline dispatch" do
    setup do
      user = user_fixture()
      episode = episode_fixture()

      %{user: user, episode: episode}
    end

    test "insert_node does persist node", %{user: _user, episode: _episode} do
      # attributes = %{"content" => "something very special 1!1", "episode_id" => episode.id}
      # event_id = Ecto.UUID.generate()

      # Dispatch.insert_node(attributes, user.id, event_id)

      # _inserted_node =
      # Outline.NodeRepository.list_nodes_by_episode(episode.id)
      # |> Enum.find(&(&1.content == "something very special 1!1"))

      # assert inserted_node.episode_id == node.episode_id
      # assert inserted_node.content == node.content

      ####

      # command = %Radiator.Outline.Command.InsertNodeCommand{
      #   event_id: event_id,
      #   user_id: user.id,
      #   payload: attributes
      # }

      # consumer_pid = Process.whereis(Radiator.Outline.EventConsumer)
      # producer_pid = Process.whereis(Radiator.Outline.CommandQueue)

      # send(consumer_pid, [command])
      # send(producer_pid, {:enqueue, command})

      # Process.send(consumer_pid, [command], [])
      # Process.send(producer_pid, [command], [])

      # assert_receive({_, ^consumer_pid, _}, 5000)
      # assert_receive({_, ^producer_pid, _}, 5000)
    end
  end
end
