defmodule Radiator.Tracking.Server do
  @doc """
  Tracking Server

  Tracking happens async in a separate process for two reasons:

  1. If something in the tracking process fails, the user still gets
     to her download.
  2. Downloads are served faster because the user does not need to wait
     for tracking processing to finish.
  """
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
    Tracking.track_download(data)
    {:noreply, state}
  end
end
