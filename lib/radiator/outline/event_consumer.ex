defmodule Radiator.Outline.EventConsumer do
  @moduledoc false

  use GenStage

  alias Radiator.EventStore
  alias Radiator.Outline
  alias Radiator.Outline.Command.{ChangeNodeContentCommand, InsertNodeCommand}
  alias Radiator.Outline.Dispatch
  alias Radiator.Outline.Event.{NodeContentChangedEvent, NodeInsertedEvent}

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

  defp handle_insert_node_result({:ok, node}, command) do
    %NodeInsertedEvent{node: node, event_id: command.event_id, user_id: command.user_id}
    |> EventStore.persist_event()
    |> Dispatch.broadcast()

    {:ok, node}
  end

  defp handle_insert_node_result({:error, _error}, _event) do
    # log_error_please :-)
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
    # log_error_please :-)
    :error
  end

  def handle_change_node_content_result({:error, _changeset}, _command) do
    # log_error_please :-)
    :error
  end
end
