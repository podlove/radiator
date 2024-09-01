# test with
# GenServer.start(Radiator.Job, work: fn -> Process.sleep(5000);{:ok,[]} end)
defmodule Radiator.Job do
  @moduledoc """
    WIP: Job module to handle work in a GenServer
    idea taken from https://pragprog.com/titles/sgdpelixir/concurrent-data-processing-in-elixir/
  """
  use GenServer, restart: :transient
  require Logger

  alias __MODULE__
  alias Radiator.JobRunner
  alias Radiator.JobSupervisor

  defstruct [:work, :arguments, :id, :max_retries, retries: 0, status: "new"]

  def start_job(args) do
    if Enum.count(running_jobs()) >= 5 do
      {:error, :import_quota_reached}
    else
      DynamicSupervisor.start_child(JobRunner, {JobSupervisor, args})
    end
  end

  def running_jobs do
    match_all = {:"$1", :"$2", :"$3"}
    # TODO import is a placeholder
    guards = [{:==, :"$3", "import"}]
    map_result = [%{id: :"$1", pid: :"$2", type: :"$3"}]
    Registry.select(Radiator.JobRegistry, [{match_all, guards, map_result}])
  end

  def start_link(args) do
    GenServer.start_link(__MODULE__, args)
  end

  def init(args) do
    work = Keyword.fetch!(args, :work)
    id = Keyword.get(args, :id, random_job_id())
    max_retries = Keyword.get(args, :max_retries, 3)
    arguments = Keyword.fetch!(args, :arguments)

    state = %Job{id: id, work: work, max_retries: max_retries, arguments: arguments}

    {:ok, state, {:continue, :run}}
  end

  def handle_continue(:run, state) do
    new_state = state.work.(state.arguments) |> handle_job_result(state)

    if new_state.status == "errored" do
      Process.send_after(self(), :retry, 5000)
      {:noreply, new_state}
    else
      Logger.info("Job exiting #{state.id}")
      {:stop, :normal, new_state}
    end
  end

  def handle_info(:retry, state) do
    # Delegate work to the `handle_continue/2` callback.
    {:noreply, state, {:continue, :run}}
  end

  defp handle_job_result({:ok, _data}, state) do
    Logger.info("Job completed #{state.id}")
    %Job{state | status: "done"}
  end

  defp handle_job_result(:error, %{status: "new"} = state) do
    Logger.warning("Job errored #{state.id}")
    %Job{state | status: "errored"}
  end

  defp handle_job_result(:error, %{status: "errored"} = state) do
    Logger.warning("Job retry failed #{state.id}")
    new_state = %Job{state | retries: state.retries + 1}

    if new_state.retries == state.max_retries do
      %Job{new_state | status: "failed"}
    else
      new_state
    end
  end

  defp random_job_id do
    :crypto.strong_rand_bytes(5) |> Base.url_encode64(padding: false)
  end
end
