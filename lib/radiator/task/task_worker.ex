defmodule Radiator.Task.TaskWorker do
  use GenServer, restart: :transient

  defstruct task: %Radiator.Task{},
            spawned_pid: nil

  def start_link({worker_fn, title, id}, opts \\ []) do
    GenServer.start_link(
      __MODULE__,
      {worker_fn, %__MODULE__{task: %Radiator.Task{id: id, description: %{title: title}}}},
      [name: via_tuple(id)] ++ opts
    )
  end

  def set_in_description(pid, key, value) do
    GenServer.cast(pid, {:set_in_description, key, value})
  end

  def get_status(pid) do
    GenServer.call(pid, :get_status)
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

  defp via_tuple(task_id) do
    {:via, Radiator.Task.TaskManager, task_id}
  end

  ## GenServer callbacks

  def init({worker_fn, initial_state = %__MODULE__{}}) do
    Process.flag(:trap_exit, true)

    with my_pid <- self(),
         state <-
           %{initial_state | spawned_pid: spawn_link(fn -> worker_fn.(my_pid) end)} do
      {:ok, state}
    end
  end

  def handle_call(:get_status, _from, state) do
    result = state.task
    {:reply, result, state}
  end

  def handle_cast(:stop, state) do
    {:stop, :normal, state}
  end

  def handle_cast({:update, key, update_fn}, state = %__MODULE__{}) do
    state = update_in(state, [Access.key!(:task), Access.key!(key)], update_fn)
    {:noreply, state}
  end

  def handle_cast({:set_in_description, key, value}, state = %__MODULE__{}) do
    state =
      update_in(state, [Access.key!(:task), Access.key!(:description)], fn description ->
        Map.put(description, key, value)
      end)

    {:noreply, state}
  end

  require Logger

  # handle the trapped exit call
  def handle_info({:EXIT, from, reason}, state = %__MODULE__{}) do
    Logger.info(
      "child exited #{inspect(from)} #{inspect(reason)} #{inspect(state, pretty: true)}"
    )

    spawned_pid = state.spawned_pid

    state =
      case from do
        ^spawned_pid ->
          state = %{state | spawned_pid: nil, task: %{state.task | end_time: DateTime.utc_now()}}

          %{
            state
            | task:
                case {state.task.progress, state.task.total} do
                  {a, a} -> %{state.task | state: :done}
                  _ -> %{state.task | state: :exited}
                end
          }

        _ ->
          {:stop, reason, state}
      end

    {:noreply, state}
  end
end
