defmodule Radiator.JobSupervisor do
  @moduledoc """
    A Supervisor for each job for greater flexibility. Starts as a child of
    JobRunner and as a Supervisor for each job
  """
  use Supervisor, restart: :temporary

  def start_link(args) do
    Supervisor.start_link(__MODULE__, args)
  end

  def init(args) do
    children = [
      {Radiator.Job, args}
    ]

    options = [
      strategy: :one_for_one,
      max_seconds: 30
    ]

    Supervisor.init(children, options)
  end
end
