defmodule Radiator.Tracking.CleanerWorker do
  use Oban.Worker, queue: "default", max_attempts: 1

  alias Radiator.Tracking.Cleaner

  def enqueue(date = %Date{}) do
    %{day: date}
    |> __MODULE__.new()
    |> Oban.insert()
  end

  @impl Oban.Worker
  def perform(%{"day" => day}, _job) do
    day
    |> Date.from_iso8601!()
    |> Cleaner.clean_day()
  end
end
