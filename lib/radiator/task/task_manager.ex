defmodule Radiator.Task.TaskManager do
  use DynamicSupervisor

  @moduledoc """
  Server to Create and manage the lifetime of long running tasks. E.g. Importing of feeds, preprocessing of files, etc.
  """

  def start_link(init_arg) do
    DynamicSupervisor.start_link(__MODULE__, init_arg, name: __MODULE__)
  end

  @impl true
  def init(_init_arg) do
    DynamicSupervisor.init(strategy: :one_for_one)
  end

  def start_task(taskargument) do
    spec = {Radiator.Task.TaskWorker, [taskargument]}

    DynamicSupervisor.start_child(__MODULE__, spec)
  end
end
