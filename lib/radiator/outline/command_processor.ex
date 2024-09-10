defmodule Radiator.Outline.CommandProcessor do
  @moduledoc false

  use GenStage

  alias Radiator.EventStore
  alias Radiator.Outline
  alias Radiator.Outline.NodeRepoResult

  alias Radiator.Outline.Command.{
    ChangeNodeContentCommand,
    DeleteNodeCommand,
    IndentNodeCommand,
    InsertNodeCommand,
    MoveNodeCommand,
    OutdentNodeCommand
  }

  alias Radiator.Outline.Dispatch

  alias Radiator.Outline.Event.{
    NodeContentChangedEvent,
    NodeDeletedEvent,
    NodeInsertedEvent,
    NodeMovedEvent
  }

  alias Radiator.Outline.NodeRepository

  require Logger

  def start_link(opts \\ []) do
    {name, opts} = Keyword.pop(opts, :name, __MODULE__)
    GenStage.start_link(__MODULE__, opts, name: name)
  end

  def init(opts) do
    {:consumer, [], opts}
  end

  def handle_events([command], _from, state) do
    Logger.debug("Processing command: #{inspect(command)}")
    process_command(command)

    {:noreply, [], state}
  end

  defp process_command(%InsertNodeCommand{payload: payload, user_id: user_id} = command) do
    payload
    |> Map.merge(%{"user_id" => user_id})
    |> Outline.insert_node()
    |> handle_insert_node_result(command)
  end

  defp process_command(%ChangeNodeContentCommand{node_id: node_id, content: content} = command) do
    node_id
    |> Outline.update_node_content(content)
    |> handle_change_node_content_result(command)
  end

  defp process_command(
         %MoveNodeCommand{
           node_id: node_id,
           parent_id: parent_id,
           prev_id: prev_id
         } = command
       ) do
    node_id
    |> Outline.move_node(prev_id: prev_id, parent_id: parent_id)
    |> handle_move_node_result(command)
  end

  defp process_command(%IndentNodeCommand{node_id: node_id} = command) do
    node_id
    |> Outline.indent_node()
    |> handle_move_node_result(command)
  end

  defp process_command(%OutdentNodeCommand{node_id: node_id} = command) do
    node_id
    |> Outline.outdent_node()
    |> handle_move_node_result(command)
  end

  defp process_command(%DeleteNodeCommand{node_id: node_id} = command) do
    case NodeRepository.get_node(node_id) do
      nil ->
        Logger.error("Could not remove node. Node not found.")

      node ->
        result = Outline.remove_node(node)

        %NodeDeletedEvent{
          node_id: node_id,
          episode_id: node.episode_id,
          uuid: command.event_id,
          user_id: command.user_id,
          children: result.children,
          next_id: result.next_id
        }
        |> EventStore.persist_event()
        |> Dispatch.broadcast()
    end

    :ok
  end

  defp handle_insert_node_result({:ok, %NodeRepoResult{node: node, next_id: next_id}}, command) do
    %NodeInsertedEvent{
      node: node,
      uuid: command.event_id,
      user_id: command.user_id,
      next_id: next_id,
      episode_id: node.episode_id
    }
    |> EventStore.persist_event()
    |> Dispatch.broadcast()

    {:ok, node}
  end

  defp handle_insert_node_result({:error, error}, _event) do
    Logger.error("Insert node failed #{inspect(error)}")
    :error
  end

  def handle_move_node_result(
        {:ok, %NodeRepoResult{node: node} = result},
        %MoveNodeCommand{} = command
      ) do
    %NodeMovedEvent{
      node_id: node.uuid,
      parent_id: command.parent_id,
      prev_id: command.prev_id,
      old_prev_id: result.old_prev_id,
      old_next_id: result.old_next_id,
      user_id: command.user_id,
      uuid: command.event_id,
      next_id: result.next_id,
      episode_id: node.episode_id,
      children: result.children
    }
    |> EventStore.persist_event()
    |> Dispatch.broadcast()

    {:ok, node}
  end

  def handle_move_node_result(
        {:ok, %NodeRepoResult{node: node} = result},
        %IndentNodeCommand{} = command
      ) do
    %NodeMovedEvent{
      node_id: node.uuid,
      parent_id: result.node.parent_id,
      prev_id: result.node.prev_id,
      old_prev_id: result.old_prev_id,
      old_next_id: result.old_next_id,
      user_id: command.user_id,
      uuid: command.event_id,
      next_id: result.next_id,
      episode_id: node.episode_id,
      children: result.children
    }
    |> EventStore.persist_event()
    |> Dispatch.broadcast()

    {:ok, node}
  end

  def handle_move_node_result(
        {:ok, %NodeRepoResult{node: node} = result},
        %OutdentNodeCommand{} = command
      ) do
    %NodeMovedEvent{
      node_id: node.uuid,
      parent_id: result.node.parent_id,
      prev_id: result.node.prev_id,
      old_prev_id: result.old_prev_id,
      old_next_id: result.old_next_id,
      user_id: command.user_id,
      uuid: command.event_id,
      next_id: result.next_id,
      episode_id: node.episode_id
    }
    |> EventStore.persist_event()
    |> Dispatch.broadcast()

    {:ok, node}
  end

  def handle_move_node_result({:error, changeset}, _command) do
    Logger.error("Move node failed. #{inspect(changeset)}")
    :error
  end

  def handle_change_node_content_result({:ok, node}, %ChangeNodeContentCommand{} = command) do
    %NodeContentChangedEvent{
      node_id: node.uuid,
      content: node.content,
      user_id: command.user_id,
      uuid: command.event_id,
      episode_id: node.episode_id
    }
    |> EventStore.persist_event()
    |> Dispatch.broadcast()

    {:ok, node}
  end

  def handle_change_node_content_result({:error, :not_found}, _command) do
    Logger.error("Update node content failed. Node not found.")
    :error
  end

  def handle_change_node_content_result({:error, changeset}, _command) do
    Logger.error("Update node content failed. #{inspect(changeset)}")
    :error
  end
end
