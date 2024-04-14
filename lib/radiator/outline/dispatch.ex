defmodule Radiator.Outline.Dispatch do
  @moduledoc false

  alias Radiator.Outline.Command
  alias Radiator.Outline.EventProducer

  def insert_node(attributes, user_id, event_id) do
    "insert_node"
    |> Command.build(attributes, user_id, event_id)
    |> EventProducer.enqueue()
  end

  def subscribe(_episode_id) do
    Phoenix.PubSub.subscribe(Radiator.PubSub, "events")
  end

  def broadcast(event) do
    Phoenix.PubSub.broadcast(Radiator.PubSub, "events", event)
  end

  # TODO
  # update_node
  # delete_node
  # move_node

  # list_node different case, sync call
end
