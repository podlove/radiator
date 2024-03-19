defmodule Radiator.Outline.EventProducer do
  @moduledoc false

  use GenStage

  def start_link(opts \\ []) do
    GenStage.start_link(__MODULE__, opts, name: __MODULE__)
  end

  def init(_opts) do
    {:producer, {:queue.new(), 0}}
  end

  def enqueue(event) do
    GenStage.cast(__MODULE__, {:enqueue, event})
    :ok
  end

  def handle_cast({:enqueue, event}, {queue, 0}) do
    queue = :queue.in(event, queue)
    {:noreply, [], {queue, 0}}
  end

  def handle_cast({:enqueue, event}, {queue, demand}) do
    queue = :queue.in(event, queue)
    {{:value, event}, queue} = :queue.out(queue)
    {:noreply, [event], {queue, demand - 1}}
  end

  def handle_demand(_incoming, {queue, demand}) do
    with {item, queue} <- :queue.out(queue),
         {:value, event} <- item do
      {:noreply, [event], {queue, demand}}
    else
      _ -> {:noreply, [], {queue, demand + 1}}
    end
  end
end
