defmodule Radiator.Scheduler do
  @moduledoc """
    This module provides a scheduler for Radiator.

    It uses the GenServer behavior to schedule tasks at regular intervals.
  """
  use GenServer
  require Logger

  defstruct [:task, :interval]

  @type scheduler_opts :: [
          task: function(),
          interval: integer()
        ]

  @doc """
  Starts the scheduler with the given options.

  ## Options
    * `:task` - Required. The function to be executed on schedule
    * `:interval` - Optional. Interval in milliseconds between executions. Defaults to 24 hours.

  ## Examples
      iex> Radiator.Scheduler.start_link(
        task: fn -> IO.puts("Daily task") end,
        interval: 24 * 60 * 60 * 1000  # 24 hours
      )
      {:ok, pid}
  """
  def start_link(opts) do
    task = Keyword.fetch!(opts, :task)
    interval = Keyword.get(opts, :interval, 24 * 60 * 60 * 1000)

    GenServer.start_link(__MODULE__, %__MODULE__{task: task, interval: interval},
      name: __MODULE__
    )
  end

  def init(state) do
    schedule_next_run()
    {:ok, state}
  end

  def handle_info(:run_task, state) do
    Logger.info("Running scheduled task")

    try do
      state.task.()
    rescue
      e ->
        Logger.error("Scheduled task failed: #{inspect(e)}")
    end

    schedule_next_run()
    {:noreply, state}
  end

  defp schedule_next_run do
    Process.send_after(self(), :run_task, get_milliseconds_until_next_run())
  end

  defp get_milliseconds_until_next_run do
    now = DateTime.utc_now()
    tomorrow = Date.add(now, 1) |> DateTime.new!(~T[00:00:00.000], "Etc/UTC")
    DateTime.diff(tomorrow, now, :millisecond)
  end
end
