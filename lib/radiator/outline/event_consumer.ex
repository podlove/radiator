defmodule Radiator.Outline.EventConsumer do
  @moduledoc false

  use GenStage

  alias Radiator.Outline
  alias Radiator.Outline.Event.InsertNodeEvent
  alias Radiator.Outline.EventProducer

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

  defp process_event(%InsertNodeEvent{payload: payload} = _event) do
    payload
    |> Outline.insert_node()
    |> handle_insert_result()

    #      validate
    #         true->
    #           database action: insert node()
    #           create && persist event (event contains all attributes, user, event_id, timestamps)
    #           broadcast event (topic: episode_id)
    #           broadcast node (topic: episode_id)
    #         false->
    #           log error and return error (audit log)
  end

  defp handle_insert_result({:ok, node}) do
    {:ok, node}
  end

  defp handle_insert_result({:error, _error}) do
    # log_error_please :-)

    :error
  end
end
