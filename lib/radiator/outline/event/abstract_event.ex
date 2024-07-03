defprotocol Radiator.Outline.Event.AbstractEvent do
  def payload(event)
  def event_type(event)
end

alias Radiator.Outline.Event.{
  NodeContentChangedEvent,
  NodeInsertedEvent,
  NodeDeletedEvent,
  NodeMovedEvent
}

defimpl Radiator.Outline.Event.AbstractEvent, for: NodeInsertedEvent do
  def payload(event) do
    %{
      node_id: event.node.uuid,
      content: event.node.content,
      parent_id: event.node.parent_id,
      prev_id: event.node.prev_id,
      next_id: event.next_id
    }
  end

  def event_type(_event), do: "NodeInsertedEvent"
end

defimpl Radiator.Outline.Event.AbstractEvent, for: NodeContentChangedEvent do
  def payload(event) do
    %{node_id: event.node_id, content: event.content}
  end

  def event_type(_event), do: "NodeContentChangedEvent"
end

defimpl Radiator.Outline.Event.AbstractEvent, for: NodeDeletedEvent do
  def payload(event) do
    %{node_id: event.node_id}
  end

  def event_type(_event), do: "NodeDeletedEvent"
end

defimpl Radiator.Outline.Event.AbstractEvent, for: NodeMovedEvent do
  def payload(event) do
    %{
      node_id: event.node_id,
      parent_id: event.parent_id,
      prev_id: event.prev_id,
      old_prev_id: event.old_prev_id,
      old_next_id: event.old_next_id,
      next_id: event.next_id
    }
  end

  def event_type(_event), do: "NodeMovedEvent"
end
