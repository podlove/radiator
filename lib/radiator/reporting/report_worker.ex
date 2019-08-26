defmodule Radiator.Reporting.ReportWorker do
  use Oban.Worker, queue: "default", max_attempts: 1

  alias Radiator.Reporting.Report

  def enqueue(args) do
    args
    |> __MODULE__.new()
    |> Oban.insert()
  end

  def perform(args = %{"subject_type" => subject_type, "subject" => _subject}, job)
      when is_binary(subject_type) do
    perform(
      %{args | "subject_type" => String.to_existing_atom(subject_type)},
      job
    )
  end

  def perform(args = %{"time_type" => time_type}, job) when is_binary(time_type) do
    perform(%{args | "time_type" => String.to_existing_atom(time_type)}, job)
  end

  def perform(args = %{"metric" => metric}, job) when is_binary(metric) do
    perform(%{args | "metric" => String.to_existing_atom(metric)}, job)
  end

  def perform(
        %{
          "subject_type" => subject_type,
          "subject" => subject,
          "time_type" => time_type,
          "metric" => metric
        },
        _job
      ) do
    apply(Report, :generate, [{subject_type, subject}, time_type, metric])
  end
end
