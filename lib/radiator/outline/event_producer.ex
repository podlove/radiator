defmodule Radiator.Outline.EventProducer do
  @moduledoc false

  use GenStage

  def start_link(opts \\ []) do
    GenStage.start_link(__MODULE__, opts, name: __MODULE__)
  end

  def init(_opts) do
    {:producer, {:queue.new(), 0}}
  end

  def enqueue(command) do
    GenStage.cast(__MODULE__, {:enqueue, command})
    :ok
  end

  def handle_cast({:enqueue, command}, {queue, 0}) do
    queue = :queue.in(command, queue)
    {:noreply, [], {queue, 0}}
  end

  def handle_cast({:enqueue, command}, {queue, demand}) do
    queue = :queue.in(command, queue)
    {{:value, command}, queue} = :queue.out(queue)
    {:noreply, [command], {queue, demand - 1}}
  end

  def handle_demand(_incoming, {queue, demand}) do
    with {item, queue} <- :queue.out(queue),
         {:value, command} <- item do
      {:noreply, [command], {queue, demand}}
    else
      _ -> {:noreply, [], {queue, demand + 1}}
    end
  end
end
