defmodule Radiator.Outline.Command do
  @moduledoc false

  alias Radiator.Outline.Command.{
    ChangeNodeContentCommand,
    DeleteNodeCommand,
    InsertNodeCommand,
    MoveNodeCommand
  }

  def build("insert_node", payload, user_id, event_id) do
    %InsertNodeCommand{
      event_id: event_id,
      user_id: user_id,
      payload: payload
    }
  end

  def build("delete_node", node_id, user_id, event_id) do
    %DeleteNodeCommand{
      event_id: event_id,
      user_id: user_id,
      node_id: node_id
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

  def build("move_node", node_id, parent_node_id, prev_node_id, user_id, event_id) do
    %MoveNodeCommand{
      event_id: event_id,
      user_id: user_id,
      node_id: node_id,
      parent_node_id: parent_node_id,
      prev_node_id: prev_node_id
    }
  end
end
