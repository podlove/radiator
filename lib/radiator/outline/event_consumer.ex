defmodule Radiator.Outline.EventConsumer do
  @moduledoc false

  use GenStage

  alias Radiator.Outline
  alias Radiator.Outline.Command.{ChangeNodeContentCommand, InsertNodeCommand}
  alias Radiator.Outline.Event.{NodeContentChangedEvent, NodeInsertedEvent}
  alias Radiator.Outline.Dispatch
  alias Radiator.Outline.EventProducer
  alias Radiator.EventStore

  def start_link(opts \\ []) do
    GenStage.start_link(__MODULE__, opts, name: __MODULE__)
  end

  def init(opts \\ [max_demand: 1]) do
    {:consumer, [], subscribe_to: [{EventProducer, opts}]}
  end

  def handle_events([command], _from, state) do
    IO.inspect(command, label: "EventConsumer.handle_events")
    process_command(command)

    {:noreply, [], state}
  end

  defp process_command(%InsertNodeCommand{payload: payload} = command) do
    payload
    |> Outline.insert_node()
    |> handle_insert_node_result(command)
  end

  defp process_command(%ChangeNodeContentCommand{node_id: node_id, content: content} = command) do
    node_id
    |> Outline.update_node_content(content)
    |> handle_change_node_content_result(command)
    |> dbg()
  end

  defp handle_insert_node_result({:ok, node}, command) do
    %NodeInsertedEvent{node: node, event_id: command.event_id}
    |> EventStore.persist_event()
    |> Dispatch.broadcast()

    {:ok, node}
  end

  defp handle_insert_node_result({:error, _error}, _event) do
    # log_error_please :-)
    :error
  end

  def handle_change_node_content_result({:ok, node}, command) do
    %NodeContentChangedEvent{node: node, event_id: command.event_id}
    |> EventStore.persist_event()
    |> Dispatch.broadcast()
    |> dbg()

    {:ok, node}
  end
end
