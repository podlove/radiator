defmodule Radiator.Outline.EventConsumer do
  use GenStage
  alias Radiator.Outline.EventProducer

  def start_link(opts \\ []) do
    GenStage.start_link(__MODULE__, opts, name: __MODULE__)
  end

  def init(_opts) do
    options = []
    {:consumer, :event_producer, subscribe_to: [{EventProducer, options}]}
  end

  def handle_events(events, _from, state) do
    IO.inspect(events, label: "EventConsumer handle_events")

    Enum.each(events, fn event ->
      process_event(event, state)
      IO.inspect(event, label: "EventConsumer handle_events event")
    end)

    {:noreply, [], state}
  end

  defp process_event(%InsertNodeEvent{} = event) do
    # validate
    #         true->
    #           database action: insert node()
    #           create && persist event (event contains all attributes, user, event_id, timestamps)
    #           broadcast event (topic: episode_id)
    #         false->
    #           log error and return error (audit log)
  end

  defp handle_result(:ok, event) do
    persist_event(event)
    broadcast_success(event)
  end

  defp handle_result(:error, event) do
    broadcast_error(event)
  end
end
