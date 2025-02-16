defmodule Radiator.Scheduler do
  use GenServer
  require Logger

  # One day in milliseconds
  @one_day 24 * 60 * 60 * 1000

  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  def init(_opts) do
    schedule_next_run()
    {:ok, %{}}
  end

  def handle_info(:run_daily_task, state) do
    # Run your daily task here
    Logger.info("Running daily task")
    perform_daily_task()
    
    # Schedule the next run
    schedule_next_run()
    
    {:noreply, state}
  end

  defp schedule_next_run do
    # Calculate time until next run (midnight)
    milliseconds_until_midnight = get_milliseconds_until_midnight()
    Process.send_after(self(), :run_daily_task, milliseconds_until_midnight)
  end

  defp get_milliseconds_until_midnight do
    now = DateTime.utc_now()
    tomorrow = Date.add(now, 1) |> DateTime.new!(~T[00:00:00.000], "Etc/UTC")
    DateTime.diff(tomorrow, now, :millisecond)
  end

  defp perform_daily_task do
    # Implement your daily task logic here
  end
end 