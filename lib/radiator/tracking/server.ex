defmodule Radiator.Tracking.Server do
  use GenServer

  require Logger

  alias Radiator.Tracking

  def start_link(_) do
    Logger.info("Starting #{__MODULE__}")
    GenServer.start_link(__MODULE__, %{}, name: __MODULE__)
  end

  @impl true
  def init(state) do
    {:ok, state}
  end

  def track_download(data) do
    GenServer.cast(__MODULE__, {:track, data})
  end

  @impl true
  def handle_cast({:track, data}, state) do
    Tracking.process_access(data)
    {:noreply, state}
  end
end
