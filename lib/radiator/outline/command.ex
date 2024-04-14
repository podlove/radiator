defmodule Radiator.Outline.Command do
  @moduledoc false

  alias Radiator.Outline.Command.{ChangeNodeContentCommand, InsertNodeCommand}

  def build("insert_node", payload, user_id, event_id) do
    %InsertNodeCommand{
      event_id: event_id,
      user_id: user_id,
      payload: payload
    }
  end

  def build("change_node_content", node_id, content, user_id, event_id) do
    %ChangeNodeContentCommand{
      event_id: event_id,
      user_id: user_id,
      node_id: node_id,
      content: content
    }
  end
end
