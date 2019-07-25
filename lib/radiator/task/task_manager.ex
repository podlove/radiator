defmodule Radiator.Task.TaskManager do
  use GenServer

  @task_manager __MODULE__

  alias Radiator.Task.TaskWorker

  ## TODO: add timer to sweep and delete old tasks automatically

  @moduledoc """
  Registry and Manager for Radiator Tasks with Progress.
  """
  defstruct table_name: :radiator_tasks,
            id_sequence: :random.uniform(1000),
            log_limit: 1_000_000

  def start_link(opts \\ []) do
    GenServer.start_link(
      __MODULE__,
      %__MODULE__{},
      [name: @task_manager] ++ opts
    )
  end

  def start_task(worker_fn, title) do
    id = GenServer.call(@task_manager, :get_next_id)

    {:ok, _pid} =
      Radiator.Task.WorkerSupervisor.start_task_worker(
        worker_fn,
        title,
        id
      )

    {:ok, id}
  end

  @doc """
  Returns Radiator.Task.t() if it exists, nil otherwise.
  """

  def get_task(task_id) when is_binary(task_id), do: get_task(String.to_integer(task_id))

  def get_task(task_id) when is_integer(task_id) do
    with {:found, pid} <- get(task_id) do
      TaskWorker.get_status(pid)
    else
      _ -> nil
    end
  end

  def end_task(task_id) when is_binary(task_id), do: end_task(String.to_integer(task_id))

  def end_task(task_id) when is_integer(task_id) do
    with {:found, pid} <- get(task_id) do
      task = TaskWorker.get_status(pid)
      TaskWorker.stop(pid)
      {:ended, task}
    else
      _ -> {:error, :not_found}
    end
  end

  def get(key) do
    case GenServer.call(@task_manager, {:get, key}) do
      [] -> {:not_found}
      [{_key, result}] -> {:found, result}
    end
  end

  require Logger

  def set(key, value) do
    GenServer.cast(@task_manager, {:set, key, value})
    value
  end

  ## :via tuple registry support

  def whereis_name(task_id) do
    case get(task_id) do
      {:found, pid} ->
        pid

      _ ->
        :undefined
    end
  end

  def register_name(task_id, pid) do
    set(task_id, pid)
    :yes
  end

  def unregister_name(task_id) do
    set(task_id, nil)
    :ok
  end

  def send(task_id, message) do
    case whereis_name(task_id) do
      :undefined ->
        {:badarg, {task_id, message}}

      pid ->
        Kernel.send(pid, message)
        pid
    end
  end

  # GenServer callbacks

  @impl true
  def handle_call(:get_next_id, _from, state = %__MODULE__{}) do
    id = state.id_sequence
    state = %{state | id_sequence: id + :random.uniform(33)}

    {:reply, id, state}
  end

  @impl true
  def handle_call({:get, key}, _from, state) do
    result = :ets.lookup(state.table_name, key)
    {:reply, result, state}
  end

  @impl true
  def handle_cast({:set, key, value}, state) do
    case value do
      nil ->
        true = :ets.delete(state.table_name, key)

      value ->
        true = :ets.insert(state.table_name, {key, value})
        ## monitor pid for now
        Process.monitor(value)
    end

    {:noreply, state}
  end

  @impl true
  def handle_cast(:purge, state) do
    :ets.delete_all_objects(state.table_name)
    {:noreply, state}
  end

  @impl true
  def init(initial_state) do
    :ets.new(initial_state.table_name, [:named_table, :set, :private])

    {:ok, initial_state}
  end

  @impl true
  def handle_info({:DOWN, _, :process, pid, _}, state = %__MODULE__{}) do
    matches = :ets.match(state.table_name, {:"$1", pid})

    matches
    |> Enum.each(fn [task_id] -> :ets.delete(state.table_name, task_id) end)

    {:noreply, state}
  end
end
