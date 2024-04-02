defmodule Radiator.Outline.EventConsumer do
  @moduledoc false

  use GenStage

  alias Radiator.Outline
  alias Radiator.Outline.Command.InsertNodeCommand
  alias Radiator.Outline.Event.NodeInsertedEvent
  alias Radiator.Outline.EventProducer
  alias Radiator.EventStore
  alias Radiator.Outline.Dispatch

  def start_link(opts \\ []) do
    GenStage.start_link(__MODULE__, opts, name: __MODULE__)
  end

  def init(opts \\ [max_demand: 1]) do
    {:consumer, :event_producer, subscribe_to: [{EventProducer, opts}]}
  end

  def handle_events([event], _from, state) do
    process_event(event)

    {:noreply, [], state}
  end

  defp process_event(%InsertNodeCommand{payload: payload} = command) do
    payload
    |> Outline.insert_node()
    |> handle_insert_result(command)
  end

  defp handle_insert_result({:ok, node}, command) do
    %NodeInsertedEvent{node: node, event_id: command.event_id}
    |> EventStore.persist_event()
    |> Dispatch.broadcast()

    {:ok, node}
  end

  defp handle_insert_result({:error, _error}, _event) do
    # log_error_please :-)

    :error
  end
end
