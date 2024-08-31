defmodule Radiator.Outline.Event do
  @moduledoc """
  Event is a module that provides helper base functions do work with events.
  """

  alias Radiator.Outline.Event.{
    NodeContentChangedEvent,
    NodeDeletedEvent,
    NodeInsertedEvent,
    NodeMovedEvent
  }

  alias Radiator.Outline.NodeRepository

  def payload(%NodeInsertedEvent{} = event) do
    %{
      node_id: event.node.uuid,
      content: event.node.content,
      parent_id: event.node.parent_id,
      prev_id: event.node.prev_id,
      next_id: event.next_id
    }
  end

  def payload(%NodeContentChangedEvent{} = event) do
    %{node_id: event.node_id, content: event.content}
  end

  def payload(%NodeDeletedEvent{} = event) do
    %{node_id: event.node_id, children: event.children, next_id: event.next_id}
  end

  def payload(%NodeMovedEvent{} = event) do
    %{
      node_id: event.node_id,
      parent_id: event.parent_id,
      prev_id: event.prev_id,
      old_prev_id: event.old_prev_id,
      old_next_id: event.old_next_id,
      next_id: event.next_id
    }
  end

  def event_type(%NodeInsertedEvent{} = _event), do: "NodeInsertedEvent"

  def event_type(%NodeContentChangedEvent{} = _event), do: "NodeContentChangedEvent"

  def event_type(%NodeDeletedEvent{} = _event), do: "NodeDeletedEvent"

  def event_type(%NodeMovedEvent{} = _event), do: "NodeMovedEvent"

  def episode_id(%NodeInsertedEvent{} = event) do
    event.node.episode_id
  end

  def episode_id(%NodeContentChangedEvent{} = event) do
    NodeRepository.get_node(event.node_id).episode_id
  end

  def episode_id(%NodeDeletedEvent{} = event) do
    NodeRepository.get_node(event.next_id).episode_id
  end

  def episode_id(%NodeMovedEvent{} = event) do
    NodeRepository.get_node(event.node_id).episode_id
  end
end
