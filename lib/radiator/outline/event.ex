defmodule Radiator.Outline.Event do
  alias Radiator.Outline.EventProducer

  def build(event_id, event_type, user_id, payload) do
    %{
      event_id: event_id,
      event_type: event_type,
      user_id: user_id,
      payload: payload
    }
  end

  def enqueue(event) do
    EventProducer.enqueue(event)
  end
end
