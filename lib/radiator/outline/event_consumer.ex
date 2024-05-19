defmodule Radiator.Outline.EventConsumer do
  @moduledoc false

  use GenStage

  alias Radiator.EventStore
  alias Radiator.Outline
  alias Radiator.Outline.Command.{ChangeNodeContentCommand, DeleteNodeCommand, InsertNodeCommand}
  alias Radiator.Outline.Dispatch
  alias Radiator.Outline.Event.{NodeContentChangedEvent, NodeDeletedEvent, NodeInsertedEvent}
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

  defp process_command(%DeleteNodeCommand{node_id: node_id} = command) do
    case NodeRepository.get_node(node_id) do
      nil -> Logger.error("Could not remove node. Node not found.")
      node -> Outline.remove_node(node)
    end

    %NodeDeletedEvent{node_id: node_id, event_id: command.event_id, user_id: command.user_id}
    |> EventStore.persist_event()
    |> Dispatch.broadcast()

    :ok
  end

  defp handle_insert_node_result({:ok, node}, command) do
    %NodeInsertedEvent{node: node, event_id: command.event_id, user_id: command.user_id}
    |> EventStore.persist_event()
    |> Dispatch.broadcast()

    {:ok, node}
  end

  defp handle_insert_node_result({:error, error}, _event) do
    Logger.error("Insert node failed #{inspect(error)}")
    :error
  end

  def handle_change_node_content_result({:ok, node}, %ChangeNodeContentCommand{} = command) do
    %NodeContentChangedEvent{
      node_id: node.uuid,
      content: node.content,
      user_id: command.user_id,
      event_id: command.event_id
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
