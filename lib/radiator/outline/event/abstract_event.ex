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
    event.node
  end

  def event_type(_event), do: "NodeInsertedEvent"
end

defimpl Radiator.Outline.Event.AbstractEvent, for: NodeContentChangedEvent do
  def payload(event) do
    %{node_id: event.node_id, content: event.content}
  end

  def event_type(_event), do: "NodeInsertedEvent"
end

defimpl Radiator.Outline.Event.AbstractEvent, for: NodeDeletedEvent do
  def payload(event) do
    %{node_id: event.node_id}
  end

  def event_type(_event), do: "NodeDeletedEvent"
end

defimpl Radiator.Outline.Event.AbstractEvent, for: NodeMovedEvent do
  def payload(event) do
    %{node_id: event.node_id, parent_id: event.parent_id, prev_id: event.prev_id}
  end

  def event_type(_event), do: "NodeInsertedEvent"
end
