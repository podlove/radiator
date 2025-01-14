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
    MergeNextNodeCommand,
    MergePrevNodeCommand,
    MoveDownCommand,
    MoveNodeCommand,
    MoveUpCommand,
    OutdentNodeCommand,
    SplitNodeCommand,
    MoveNodesToContainerCommand
  }

  alias Radiator.Outline.Dispatch

  alias Radiator.Outline.Event.{
    NodeContentChangedEvent,
    NodeDeletedEvent,
    NodeInsertedEvent,
    NodeMovedEvent,
    NodesMovedToContainerEvent
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

  defp process_command(%MergePrevNodeCommand{node_id: node_id} = command) do
    case Outline.merge_prev_node(node_id) do
      {:ok, %NodeRepoResult{} = result} ->
        handle_merge_result(result, command)

      {:error, error} ->
        Logger.error("Merge next node failed. #{inspect(error)}")
    end
  end

  defp process_command(%MergeNextNodeCommand{node_id: node_id} = command) do
    case Outline.merge_next_node(node_id) do
      {:ok, %NodeRepoResult{} = result} ->
        handle_merge_result(result, command)

      {:error, error} ->
        Logger.error("Merge next node failed. #{inspect(error)}")
    end
  end

  defp process_command(
         %MoveNodesToContainerCommand{
           container_id: new_container_id,
           node_ids: node_ids,
           user_id: user_id,
           event_id: event_id
         } = command
       ) do
    # Get all nodes that need to be moved
    nodes = Enum.map(node_ids, &NodeRepository.get_node!/1)

    # Ensure all nodes exist and are from the same container
    with {:ok, old_container_id} <- validate_nodes_container(nodes),
         :ok <- validate_container_exists(new_container_id),
         {:ok, updated_nodes} <- move_nodes_to_new_container(nodes, new_container_id) do
      # Create and broadcast the event
      event = %NodesMovedToContainerEvent{
        event_id: event_id,
        user_id: user_id,
        nodes: updated_nodes,
        old_container_id: old_container_id,
        new_container_id: new_container_id
      }

      {:ok, event}
    else
      {:error, reason} -> {:error, reason}
    end
  end

  def handle_merge_result(
        %NodeRepoResult{
          node: node,
          old_next: deleted_node,
          next: next,
          children: children,
          outline_node_container_id: outline_node_container_id
        },
        command
      ) do
    %NodeDeletedEvent{
      node: deleted_node,
      outline_node_container_id: outline_node_container_id,
      event_id: command.event_id,
      user_id: command.user_id,
      children: [],
      next: next
    }
    |> persist_and_broadcast_event()

    %NodeContentChangedEvent{
      node_id: node.uuid,
      content: node.content,
      user_id: command.user_id,
      event_id: Ecto.UUID.generate(),
      outline_node_container_id: node.outline_node_container_id
    }
    |> persist_and_broadcast_event()

    Enum.each(children, fn child ->
      %NodeMovedEvent{
        node: child,
        user_id: command.user_id,
        event_id: Ecto.UUID.generate(),
        children: [],
        outline_node_container_id: child.outline_node_container_id
      }
      |> persist_and_broadcast_event()
    end)
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
    |> persist_and_broadcast_event()

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
    |> persist_and_broadcast_event()

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
    |> persist_and_broadcast_event()

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

  defp persist_and_broadcast_event(event) do
    event
    |> EventStore.persist_event()
    |> Dispatch.broadcast()
  end

  defp validate_nodes_container([first_node | _] = nodes) do
    container_id = first_node.outline_node_container_id

    if Enum.all?(nodes, &(&1.outline_node_container_id == container_id)) do
      {:ok, container_id}
    else
      {:error, :nodes_from_different_containers}
    end
  end

  defp validate_nodes_container([]), do: {:error, :no_nodes_provided}

  defp validate_container_exists(container_id) do
    case Repo.get(NodeContainer, container_id) do
      nil -> {:error, :container_not_found}
      _container -> :ok
    end
  end

  defp move_nodes_to_new_container(nodes, new_container_id) do
    # Start a transaction to ensure all nodes are moved atomically
    Repo.transaction(fn ->
      nodes
      |> Enum.map(fn node ->
        node
        |> Node.move_container_changeset(%{outline_node_container_id: new_container_id})
        |> Repo.update!()
      end)
    end)
  end
end
