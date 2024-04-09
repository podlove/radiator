defmodule Radiator.Outline.Command do
  @moduledoc false

  alias Radiator.Outline.Command.InsertNodeCommand
  defstruct [:event_type, :event_id, :user_id, :payload]

  def build("insert_node", payload, user_id, event_id) do
    %InsertNodeCommand{
      event_id: event_id,
      user_id: user_id,
      payload: payload
    }
  end
end
