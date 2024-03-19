defmodule Radiator.Outline.Event do
  @moduledoc false

  def build(event_id, event_type, user_id, payload) do
    %{
      event_id: event_id,
      event_type: event_type,
      user_id: user_id,
      payload: payload
    }
  end
end
