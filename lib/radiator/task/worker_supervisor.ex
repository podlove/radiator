defmodule Radiator.Task.WorkerSupervisor do
  @moduledoc false

  use DynamicSupervisor
  alias Radiator.Task.TaskWorker

  def start_link(opts \\ []),
    do: DynamicSupervisor.start_link(__MODULE__, [], [name: __MODULE__] ++ opts)

  @impl true
  def init(_init_arg), do: DynamicSupervisor.init(strategy: :one_for_one)

  def start_task_worker(worker_fn, title, id) do
    spec = {TaskWorker, {worker_fn, title, id}}

    DynamicSupervisor.start_child(
      __MODULE__,
      spec
    )
    |> IO.inspect(pretty: true, label: "start_task")
  end
end
