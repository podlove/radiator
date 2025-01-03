defmodule Radiator.Outline.CommandProcessor do
  @moduledoc false

  use GenStage

  alias Radiator.EventStore
  alias Radiator.Outline
  alias Radiator.Outline.Command
  alias Radiator.Outline.NodeRepoResult
  alias Radiator.Podcast

  alias Radiator.Outline.Command.{
    ChangeNodeContentCommand,
    DeleteNodeCommand,
    IndentNodeCommand,
    InsertNodeCommand,
    MoveDownCommand,
    MoveNodeCommand,
    MoveUpCommand,
    OutdentNodeCommand,
    SplitNodeCommand
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
  # for the guard
  require Radiator.Outline.Command

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
    |> add_node_container()
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

  defp process_command(%MoveUpCommand{node_id: node_id} = command) do
    node_id
    |> Outline.move_up()
    |> handle_move_node_result(command)
  end

  defp process_command(%MoveDownCommand{node_id: node_id} = command) do
    node_id
    |> Outline.move_down()
    |> handle_move_node_result(command)
  end

  defp process_command(%DeleteNodeCommand{node_id: node_id} = command) do
    case NodeRepository.get_node(node_id) do
      nil ->
        Logger.error("Could not remove node. Node not found.")

      node ->
        result = Outline.remove_node(node)

        %NodeDeletedEvent{
          node: result.node,
          outline_node_container_id: result.outline_node_container_id,
          event_id: command.event_id,
          user_id: command.user_id,
          children: result.children,
          next: result.next
        }
        |> EventStore.persist_event()
        |> Dispatch.broadcast()
    end

    :ok
  end

  defp process_command(
         %SplitNodeCommand{
           node_id: node_id,
           selection: selection
         } = command
       ) do
    {:ok,
     %NodeRepoResult{
       node: node,
       next: next,
       outline_node_container_id: outline_node_container_id,
       old_next: old_next
     }} =
      node_id
      |> Outline.split_node(selection)

    # broadcast two events
    handle_insert_node_result(
      {:ok,
       %NodeRepoResult{
         node: next,
         next: old_next,
         outline_node_container_id: outline_node_container_id
       }},
      command
    )

    # for the second event, we need to generate a new event_id
    command = Map.put(command, :event_id, Ecto.UUID.generate())
    handle_change_node_content_result({:ok, node}, command)
  end

  defp handle_insert_node_result(
         {:ok,
          %NodeRepoResult{
            node: node,
            next: next,
            outline_node_container_id: outline_node_container_id
          }},
         command
       ) do
    %NodeInsertedEvent{
      node: node,
      event_id: command.event_id,
      user_id: command.user_id,
      next: next,
      outline_node_container_id: outline_node_container_id
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
        %command_type{} = command
      )
      when Command.move_command?(command_type) do
    %NodeMovedEvent{
      node: node,
      old_prev: result.old_prev,
      old_next: result.old_next,
      user_id: command.user_id,
      event_id: command.event_id,
      next: result.next,
      children: result.children,
      outline_node_container_id: result.outline_node_container_id
    }
    |> EventStore.persist_event()
    |> Dispatch.broadcast()

    {:ok, node}
  end

  def handle_move_node_result({:error, changeset}, _command) do
    Logger.error("Move node failed. #{inspect(changeset)}")
    :error
  end

  def handle_change_node_content_result({:ok, node}, command) do
    %NodeContentChangedEvent{
      node_id: node.uuid,
      content: node.content,
      user_id: command.user_id,
      event_id: command.event_id,
      outline_node_container_id: node.outline_node_container_id
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

  defp add_node_container(%{"outline_node_container_id" => _outline_node_container_id} = payload),
    do: payload

  defp add_node_container(%{"episode_id" => episode_id} = payload) do
    episode = Podcast.get_episode!(episode_id)

    Map.put(payload, "outline_node_container_id", episode.outline_node_container_id)
  end
end
