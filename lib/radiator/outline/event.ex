defmodule Radiator.Outline.Event do
  @moduledoc false

  alias Radiator.Outline.Event.InsertNodeEvent
  defstruct [:event_type, :event_id, :user_id, :payload]

  def build("insert_node", payload, user_id, event_id) do
    %InsertNodeEvent{
      event_id: event_id,
      user_id: user_id,
      payload: payload
    }
  end
end
