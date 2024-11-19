defmodule Radiator.Outline.Event do
  @moduledoc """
  Event is a module that provides helper base functions do work with events.
  """

  alias Radiator.Outline.Event.{
    NodeContentChangedEvent,
    NodeDeletedEvent,
    NodeInsertedEvent,
    NodeMovedEvent,
    UrlsAnalyzedEvent
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
      outline_node_container_id: event.outline_node_container_id,
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

  def payload(%UrlsAnalyzedEvent{} = event) do
    %{
      node_id: event.node_id,
      urls: event.urls
    }
  end

  def user_id(%UrlsAnalyzedEvent{}), do: nil
  def user_id(event), do: event.user_id

  def event_type(%NodeInsertedEvent{} = _event), do: "NodeInsertedEvent"
  def event_type(%NodeContentChangedEvent{} = _event), do: "NodeContentChangedEvent"
  def event_type(%NodeDeletedEvent{} = _event), do: "NodeDeletedEvent"
  def event_type(%NodeMovedEvent{} = _event), do: "NodeMovedEvent"
  def event_type(%UrlsAnalyzedEvent{} = _event), do: "UrlsAnalyzedEvent"

  def outline_node_container_id(%{outline_node_container_id: outline_node_container_id}),
    do: outline_node_container_id
end
