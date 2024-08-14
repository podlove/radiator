defmodule Radiator.Outline.NodeChangeListener do
  @moduledoc """
  Genserver that listens to change events and starts jobs
  It is an eventconsumer that listens to changes in the outline and starts workers
  """
  use GenServer
  alias Radiator.Outline.Dispatch

  def start_link(_) do
    GenServer.start_link(__MODULE__, :ok, [])
  end

  def init(_) do
    Dispatch.subscribe()
    {:ok, []}
  end

  def handle_info(%Radiator.Outline.Event.NodeContentChangedEvent{} = _event, state) do
    {:noreply, state}
  end

  def handle_info(%Radiator.Outline.Event.NodeInsertedEvent{} = _event, state) do
    {:noreply, state}
  end

  def handle_info(%Radiator.Outline.Event.NodeMovedEvent{} = _event, state) do
    {:noreply, state}
  end

  def handle_info(%Radiator.Outline.Event.NodeDeletedEvent{} = _event, state) do
    {:noreply, state}
  end
end
