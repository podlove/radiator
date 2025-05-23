defmodule Radiator.Outline.Dispatch do
  @moduledoc false

  alias Radiator.Outline.{Command, CommandQueue, Event, Validations}

  def insert_node(attributes, user_id, event_id) do
    "insert_node"
    |> Command.build(attributes, user_id, event_id)
    |> CommandQueue.enqueue()
  end

  def change_node_content(node_id, content, user_id, event_id) do
    "change_node_content"
    |> Command.build(node_id, content, user_id, event_id)
    |> CommandQueue.enqueue()
  end

  def split_node(node_id, selection, user_id, event_id) do
    "split_node"
    |> Command.build(node_id, selection, user_id, event_id)
    |> CommandQueue.enqueue()
  end

  def merge_prev(node_id, user_id, event_id) do
    "merge_prev"
    |> Command.build(node_id, user_id, event_id)
    |> CommandQueue.enqueue()
  end

  def merge_next(node_id, user_id, event_id) do
    "merge_next"
    |> Command.build(node_id, user_id, event_id)
    |> CommandQueue.enqueue()
  end

  def indent_node(node_id, user_id, event_id) do
    "indent_node"
    |> Command.build(node_id, user_id, event_id)
    |> CommandQueue.enqueue()
  end

  def outdent_node(node_id, user_id, event_id) do
    "outdent_node"
    |> Command.build(node_id, user_id, event_id)
    |> CommandQueue.enqueue()
  end

  def move_up(node_id, user_id, event_id) do
    "move_up"
    |> Command.build(node_id, user_id, event_id)
    |> CommandQueue.enqueue()
  end

  def move_down(node_id, user_id, event_id) do
    "move_down"
    |> Command.build(node_id, user_id, event_id)
    |> CommandQueue.enqueue()
  end

  def move_node(node_id, user_id, event_id,
        parent_id: parent_id,
        prev_id: prev_id
      ) do
    "move_node"
    |> Command.build(node_id, parent_id, prev_id, user_id, event_id)
    |> CommandQueue.enqueue()
  end

  def delete_node(node_id, user_id, event_id) do
    "delete_node"
    |> Command.build(node_id, user_id, event_id)
    |> CommandQueue.enqueue()
  end

  def move_node_to_container(container_id, node_id, user_id, event_id,
        parent_id: parent_id,
        prev_id: prev_id
      ) do
    "move_node_to_container"
    |> Command.build(container_id, node_id, user_id, event_id, parent_id, prev_id)
    |> CommandQueue.enqueue()
  end

  def move_nodes_to_container(container_id, node_ids, user_id, event_id) do
    "move_nodes_to_container"
    |> Command.build(container_id, node_ids, user_id, event_id)
    |> CommandQueue.enqueue()
  end

  def subscribe do
    Phoenix.PubSub.subscribe(Radiator.PubSub, "events")
  end

  def subscribe(container_id) do
    pubsub_channel = get_pubsub_channel(container_id)
    Phoenix.PubSub.subscribe(Radiator.PubSub, pubsub_channel)
  end

  def broadcast(event) do
    container_id = Event.container_id(event)

    # if enabled validate tree and crash if tree got inconsistent
    if Application.get_env(:radiator, :tree_consistency_validator, false) do
      :ok = Validations.validate_tree_for_container(container_id)
    end

    pubsub_channel = get_pubsub_channel(container_id)
    Phoenix.PubSub.broadcast(Radiator.PubSub, "events", event)
    Phoenix.PubSub.broadcast(Radiator.PubSub, pubsub_channel, event)
  end

  defp get_pubsub_channel(container_id), do: "events-#{container_id}"

  # list_node different case, sync call
end
