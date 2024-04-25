defmodule Radiator.Outline.EventProducer do
  @moduledoc false

  use GenStage

  def start_link(opts \\ []) do
    name = Keyword.get(opts, :name, __MODULE__)
    GenStage.start_link(__MODULE__, opts, name: name)
  end

  def init(_opts) do
    {:producer, {:queue.new(), 0}}
  end

  def enqueue(server \\ __MODULE__, command) do
    GenStage.cast(server, {:enqueue, command})
    :ok
  end

  def handle_cast({:enqueue, command}, state) do
    {:noreply, [command], state}
  end

  def handle_demand(_incoming, state) do
    {:noreply, [], state}
  end
end
