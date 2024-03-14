defmodule Radiator.Outline.EventProducer do
  use GenStage

  def start_link(opts \\ []) do
    GenStage.start_link(__MODULE__, opts, name: __MODULE__)
  end

  def init(_opts) do
    {:producer, []}
  end

  def enqueue(event) do
    GenStage.cast(__MODULE__, {:enqueue, event})
    :ok
  end

  def handle_cast({:enqueue, event}, state) do
    {:noreply, [event], state}
  end
end
