defmodule Radiator.Outline.Command do
  @moduledoc false

  alias Radiator.Outline.Command.{
    ChangeNodeContentCommand,
    DeleteNodeCommand,
    IndentNodeCommand,
    InsertNodeCommand,
    MergeNextNodeCommand,
    MergePrevNodeCommand,
    MoveDownCommand,
    MoveNodeCommand,
    MoveNodesToContainerCommand,
    MoveNodeToContainerCommand,
    MoveUpCommand,
    OutdentNodeCommand,
    SplitNodeCommand
  }

  @move_commands [
    IndentNodeCommand,
    MoveDownCommand,
    MoveNodeCommand,
    MoveUpCommand,
    OutdentNodeCommand
  ]

  defguard move_command?(command) when command in @move_commands

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

  def build("indent_node", node_id, user_id, event_id) do
    %IndentNodeCommand{
      event_id: event_id,
      user_id: user_id,
      node_id: node_id
    }
  end

  def build("outdent_node", node_id, user_id, event_id) do
    %OutdentNodeCommand{
      event_id: event_id,
      user_id: user_id,
      node_id: node_id
    }
  end

  def build("move_up", node_id, user_id, event_id) do
    %MoveUpCommand{
      event_id: event_id,
      user_id: user_id,
      node_id: node_id
    }
  end

  def build("move_down", node_id, user_id, event_id) do
    %MoveDownCommand{
      event_id: event_id,
      user_id: user_id,
      node_id: node_id
    }
  end

  def build("merge_prev", node_id, user_id, event_id) do
    %MergePrevNodeCommand{
      event_id: event_id,
      user_id: user_id,
      node_id: node_id
    }
  end

  def build("merge_next", node_id, user_id, event_id) do
    %MergeNextNodeCommand{
      event_id: event_id,
      user_id: user_id,
      node_id: node_id
    }
  end

  def build("split_node", node_id, selection, user_id, event_id) do
    %SplitNodeCommand{
      event_id: event_id,
      user_id: user_id,
      node_id: node_id,
      selection: selection
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

  def build("move_nodes_to_container", container_id, node_ids, user_id, event_id) do
    %MoveNodesToContainerCommand{
      event_id: event_id,
      user_id: user_id,
      container_id: container_id,
      node_ids: node_ids
    }
  end

  def build("move_node", node_id, parent_id, prev_id, user_id, event_id) do
    %MoveNodeCommand{
      event_id: event_id,
      user_id: user_id,
      node_id: node_id,
      parent_id: parent_id,
      prev_id: prev_id
    }
  end

  def build(
        "move_node_to_container",
        container_id,
        node_id,
        parent_id,
        prev_id,
        user_id,
        event_id
      ) do
    %MoveNodeToContainerCommand{
      event_id: event_id,
      user_id: user_id,
      container_id: container_id,
      node_id: node_id,
      parent_id: parent_id,
      prev_id: prev_id
    }
  end
end
