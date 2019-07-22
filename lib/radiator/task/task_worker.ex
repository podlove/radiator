defmodule Radiator.Task.TaskWorker do
  use GenServer

  defstruct id: nil,
            total: 0,
            progress: 0,
            state: :setup,
            description: %{},
            start_time: DateTime.utc_now(),
            end_time: nil,
            spawned_pid: nil

  def start_link(task_description, opts \\ []) do
    GenServer.start_link(
      __MODULE__,
      {task_description, %__MODULE__{}},
      opts
    )
  end

  @spec status(atom | pid | {atom, any} | {:via, atom, any}) :: any
  def status(pid) do
    GenServer.call(pid, :status)
  end

  def update_total(pid, update_fn) do
    GenServer.cast(pid, {:update, :total, update_fn})
  end

  def increment_total(pid, amount \\ 1) do
    GenServer.cast(pid, {:update, :total, fn v -> v + amount end})
  end

  def update_progress(pid, update_fn) do
    GenServer.cast(pid, {:update, :progress, update_fn})
  end

  def increment_progress(pid, amount \\ 1) do
    GenServer.cast(pid, {:update, :progress, fn v -> v + amount end})
  end

  def finish_setup(pid) do
    GenServer.cast(pid, {:update, :state, fn _ -> :running end})
  end

  def stop(pid) do
    GenServer.cast(pid, :stop)
  end

  ## GenServer callbacks

  def init({start_work_fun, initial_state = %__MODULE__{}}) do
    Process.flag(:trap_exit, true)
    my_pid = self()

    %{initial_state | spawned_pid: spawn_link(fn -> start_work_fun.(my_pid) end)}
    |> (&{:ok, &1}).()
  end

  def handle_call(:status, _from, state) do
    result = state
    {:reply, result, state}
  end

  def handle_cast(:stop, state) do
    {:stop, :normal, state}
  end

  def handle_cast({:update, key, update_fn}, state = %__MODULE__{}) do
    state = update_in(state, [Access.key!(key)], update_fn)
    {:noreply, state}
  end

  require Logger

  # handle the trapped exit call
  def handle_info({:EXIT, from, reason}, state = %__MODULE__{}) do
    Logger.info("child exited #{inspect(from)} #{inspect(reason)} #{inspect(state)}")

    spawned_pid = state.spawned_pid

    state =
      case from do
        ^spawned_pid ->
          state = %{state | spawned_pid: nil, end_time: DateTime.utc_now()}

          case {state.progress, state.total} do
            {a, a} -> %{state | state: :done}
            _ -> %{state | state: :exited}
          end

        _ ->
          {:stop, reason, state}
      end

    {:noreply, state}
  end
end
