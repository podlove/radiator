defmodule Radiator.Outline.Dispatch do
  @moduledoc false

  alias Radiator.Outline.Command
  alias Radiator.Outline.EventProducer

  def insert_node(attributes, user_id, event_id) do
    "insert_node"
    |> Command.build(attributes, user_id, event_id)
    |> EventProducer.enqueue()
  end

  def change_node_content(node_id, content, user_id, event_id) do
    "change_node_content"
    |> Command.build(node_id, content, user_id, event_id)
    |> EventProducer.enqueue()
  end

  def move_node(node_id, parent_node_id, prev_node_id, user_id, event_id) do
    "move_node"
    |> Command.build(node_id, parent_node_id, prev_node_id, user_id, event_id)
    |> EventProducer.enqueue()
  end

  def delete_node(node_id, user_id, event_id) do
    "delete_node"
    |> Command.build(node_id, user_id, event_id)
    |> EventProducer.enqueue()
  end

  def subscribe(_episode_id) do
    Phoenix.PubSub.subscribe(Radiator.PubSub, "events")
  end

  def broadcast(event) do
    Phoenix.PubSub.broadcast(Radiator.PubSub, "events", event)
  end

  # list_node different case, sync call
end
