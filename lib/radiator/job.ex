defmodule Radiator.Job do
  @moduledoc """
    Job module to handle job processing in a GenServer
    Provides a basic retry mechanism.
    idea taken from https://pragprog.com/titles/sgdpelixir/concurrent-data-processing-in-elixir/
  """
  use GenServer, restart: :transient
  require Logger

  alias __MODULE__
  alias Radiator.JobRunner
  alias Radiator.JobSupervisor

  defstruct [:worker, :arguments, :id, :max_retries, retries: 0, status: "new"]

  @doc """
   Enqueue a job to be processed.
   Requires a worker function to be passed in as an argument to the job with the keyword `worker`
   This function requires to return either `:ok` or `:error`.
   Arguments are optional and can be passed in as a keyword list with the keyword `arguments`.
   Please note that order matters here and the worker function must accept the arguments as single arguments.
   The keyword list is only for beeing more clear about the arguments.
   If a job errors it will be retried up to `max_retries` times.
   It defaults to 3 but can be set via the keyword `max_retries`

   ## Examples

         iex> Radiator.Job.start_job(worker: &MyWorkerModule.perform/3,
           arguments: [arg1: arg1, arg2: arg2, arg3: arg3]
         )

  """
  def start_job([worker: _worker, arguments: _arguments] = args) do
    DynamicSupervisor.start_child(JobRunner, {JobSupervisor, args})
  end

  def start_link(args) do
    GenServer.start_link(__MODULE__, args)
  end

  def init(args) do
    worker = Keyword.fetch!(args, :worker)
    id = Keyword.get(args, :id, random_job_id())
    max_retries = Keyword.get(args, :max_retries, 3)

    arguments =
      case Keyword.fetch(args, :arguments) do
        {:ok, args} -> args
        :error -> []
      end

    state = %Job{
      id: id,
      worker: worker,
      max_retries: max_retries,
      arguments: arguments
    }

    {:ok, state, {:continue, :run}}
  end

  def handle_continue(:run, state) do
    new_state = state |> execute_job |> handle_job_result(state)

    if new_state.status == "errored" do
      Process.send_after(self(), :retry, 5000)
      {:noreply, new_state}
    else
      Logger.info("Job exiting #{state.id}")
      {:stop, :normal, new_state}
    end
  end

  defp execute_job(state) do
    function_info = Function.info(state.worker)

    apply(
      Keyword.fetch!(function_info, :module),
      Keyword.fetch!(function_info, :name),
      Keyword.values(state.arguments)
    )
  end

  def handle_info(:retry, state) do
    # Delegate work to the `handle_continue/2` callback.
    {:noreply, state, {:continue, :run}}
  end

  defp handle_job_result(:ok, state) do
    Logger.debug("Job completed #{state.id}")
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

  defp handle_job_result(result, state) do
    Logger.error(
      "Job returned unexpected result #{inspect(result)}, only :ok and :error are allowed"
    )

    %Job{state | status: "errored"}
  end

  defp random_job_id do
    :crypto.strong_rand_bytes(5) |> Base.url_encode64(padding: false)
  end
end
