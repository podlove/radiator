defmodule Radiator.Reporting.ReportGenerator do
  @moduledoc """
  High level report generators.

  See `Radiator.Reporting.Report` for details.
  """

  alias Radiator.Repo
  alias Radiator.Reporting.ReportWorker

  alias Radiator.Directory.{
    Network,
    Podcast,
    Episode,
    AudioPublication
  }

  @doc """
  Hourly reporting, calculating current day's download reports.
  """
  def hourly_report do
    Date.utc_today() |> do_report_for_day([:downloads])
  end

  @doc """
  Daily reporting, calculating previous day's reports.
  """
  def daily_report do
    Date.utc_today() |> Date.add(-1) |> do_report_for_day([:downloads, :listeners, :user_agents])
  end

  def do_report_for_day(day = %Date{}, metrics) do
    entities = fetch_entities()

    for metric <- metrics, do: do_report(entities, day, metric)
  end

  defp do_report(entities, day, :downloads) do
    entities
    |> Enum.map(fn {subject_type, subject} ->
      ReportWorker.enqueue(%{
        subject_type: subject_type,
        subject: subject,
        time_type: :day,
        time: day,
        metric: :downloads
      })

      {subject_type, subject}
    end)
    |> Enum.map(fn {subject_type, subject} ->
      ReportWorker.enqueue(%{
        subject_type: subject_type,
        subject: subject,
        time_type: :month,
        time: day,
        metric: :downloads
      })

      {subject_type, subject}
    end)
    |> Enum.map(fn {subject_type, subject} ->
      ReportWorker.enqueue(%{
        subject_type: subject_type,
        subject: subject,
        time_type: :total,
        metric: :downloads
      })

      {subject_type, subject}
    end)
  end

  defp do_report(entities, day, :listeners) do
    entities
    |> Enum.map(fn {subject_type, subject} ->
      ReportWorker.enqueue(%{
        subject_type: subject_type,
        subject: subject,
        time_type: :day,
        time: day,
        metric: :listeners
      })

      {subject_type, subject}
    end)
    |> Enum.map(fn {subject_type, subject} ->
      ReportWorker.enqueue(%{
        subject_type: subject_type,
        subject: subject,
        time_type: :month,
        time: day,
        metric: :listeners
      })

      {subject_type, subject}
    end)
    |> Enum.map(fn {subject_type, subject} ->
      ReportWorker.enqueue(%{
        subject_type: subject_type,
        subject: subject,
        time_type: :total,
        metric: :listeners
      })

      {subject_type, subject}
    end)
  end

  defp do_report(entities, _day, :user_agents) do
    entities
    |> Enum.map(fn {subject_type, subject} ->
      ReportWorker.enqueue(%{
        subject_type: subject_type,
        subject: subject,
        time_type: :total,
        metric: :user_agents
      })

      {subject_type, subject}
    end)
  end

  @doc """
  Generate all total downloads numbers.

  For:
    - all Networks
    - all Podcasts
    - all Episodes
    - all AudioPublications

  # FIXME: all _total_ calculations must work on already done reporting data,
           because historic raw data will be purged
  """
  def generate_all_total_downloads do
    fetch_entities()
    |> Enum.each(fn {subject_type, subject} ->
      ReportWorker.enqueue(%{
        subject_type: subject_type,
        subject: subject,
        time_type: :total,
        metric: :downloads
      })
    end)
  end

  # I think "total listeners" is a nonsensical number because it can only
  # be calculared for a shorter amount of time?
  def generate_all_total_listeners do
    fetch_entities()
    |> Enum.each(fn {subject_type, subject} ->
      ReportWorker.enqueue(%{
        subject_type: subject_type,
        subject: subject,
        time_type: :total,
        metric: :listeners
      })
    end)
  end

  def generate_all_total_user_agents do
    fetch_entities()
    |> Enum.each(fn {subject_type, subject} ->
      ReportWorker.enqueue(%{
        subject_type: subject_type,
        subject: subject,
        time_type: :total,
        metric: :user_agents
      })
    end)
  end

  @doc """
  Generate all monthly dowanloads for given month.

  For:
    - all Networks
    - all Podcasts
    - all Episodes
    - all AudioPublications

  TODO(perf): only fetch entities published on or after given month
  """
  def generate_all_monthly_downloads(month = %Date{}) do
    fetch_entities()
    |> Enum.each(fn {subject_type, subject} ->
      ReportWorker.enqueue(%{
        subject_type: subject_type,
        subject: subject,
        time_type: :month,
        time: month,
        metric: :downloads
      })
    end)
  end

  # even monthly listeners should not be calculated like this. Is there a "standard"?
  # my suggestion is: calculate daily listeners, then take either the max of each month
  # or average (have to look at actual data to see which one gives more realistic numbers)
  def generate_all_monthly_listeners(month = %Date{}) do
    fetch_entities()
    |> Enum.each(fn {subject_type, subject} ->
      ReportWorker.enqueue(%{
        subject_type: subject_type,
        subject: subject,
        time_type: :month,
        time: month,
        metric: :listeners
      })
    end)
  end

  def generate_all_monthly_user_agents(month = %Date{}) do
    fetch_entities()
    |> Enum.each(fn {subject_type, subject} ->
      ReportWorker.enqueue(%{
        subject_type: subject_type,
        subject: subject,
        time_type: :month,
        time: month,
        metric: :user_agents
      })
    end)
  end

  def generate_all_daily_downloads(day = %Date{}) do
    fetch_entities()
    |> Enum.each(fn {subject_type, subject} ->
      ReportWorker.enqueue(%{
        subject_type: subject_type,
        subject: subject,
        time_type: :day,
        time: day,
        metric: :downloads
      })
    end)
  end

  def generate_all_daily_listeners(day = %Date{}) do
    fetch_entities()
    |> Enum.each(fn {subject_type, subject} ->
      ReportWorker.enqueue(%{
        subject_type: subject_type,
        subject: subject,
        time_type: :day,
        time: day,
        metric: :listeners
      })
    end)
  end

  defp fetch_entities do
    [
      Repo.all(Network) |> Enum.map(&{:network, &1.id}),
      Repo.all(Podcast) |> Enum.map(&{:podcast, &1.id}),
      Repo.all(Episode) |> Enum.map(&{:episode, &1.id}),
      Repo.all(AudioPublication) |> Enum.map(&{:audio_publication, &1.id})
    ]
    |> List.flatten()
  end
end
