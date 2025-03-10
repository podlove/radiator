defmodule Radiator.Outline.Event do
  @moduledoc """
  Event is a module that provides helper base functions do work with events.
  """

  alias Radiator.Outline.Event.{
    NodeContentChangedEvent,
    NodeDeletedEvent,
    NodeInsertedEvent,
    NodeMovedEvent,
    NodeMovedToNewContainer
  }

  def payload(%NodeInsertedEvent{} = event) do
    %{
      node: event.node,
      content: event.node.content,
      next: event.next
    }
  end

  def payload(%NodeContentChangedEvent{} = event) do
    %{node_id: event.node_id, content: event.content}
  end

  def payload(%NodeDeletedEvent{} = event) do
    %{
      node: event.node,
      container_id: event.container_id,
      children: event.children,
      next: event.next
    }
  end

  def payload(%NodeMovedEvent{} = event) do
    %{
      node: event.node,
      old_prev: event.old_prev,
      old_next: event.old_next,
      next: event.next
    }
  end

  def payload(%NodeMovedToNewContainer{} = event) do
    %{
      node: event.node,
      old_prev: event.old_prev,
      old_next: event.old_next,
      next: event.next,
      # TODO which container id to take (or both)
      container_id: event.container_id,
      children: event.children
    }
  end

  def event_type(%NodeInsertedEvent{} = _event), do: "NodeInsertedEvent"
  def event_type(%NodeContentChangedEvent{} = _event), do: "NodeContentChangedEvent"
  def event_type(%NodeDeletedEvent{} = _event), do: "NodeDeletedEvent"
  def event_type(%NodeMovedEvent{} = _event), do: "NodeMovedEvent"
  def event_type(%NodeMovedToNewContainer{} = _event), do: "NodeMovedToNewContainer"

  def container_id(%{container_id: container_id}),
    do: container_id
end
