defmodule Radiator.Task.Supervisor do
  @moduledoc false

  use Supervisor

  def start_link(opts \\ []) do
    Supervisor.start_link(__MODULE__, :ok, [name: __MODULE__] ++ opts)
  end

  @impl true
  def init(_init_arg) do
    children = [
      Radiator.Task.TaskManager,
      Radiator.Task.WorkerSupervisor
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end
end
