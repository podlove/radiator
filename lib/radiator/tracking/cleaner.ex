defmodule Radiator.Tracking.Cleaner do
  @moduledoc """
  Cleans downloads, removes duplicate requests by same IP+UserAgent aper day.
  """

  import Ecto.Query, warn: false

  alias Radiator.Repo
  alias Radiator.Tracking.Download

  require Logger

  @doc """
  Clean all downloads.
  """
  def clean_all do
    with total_start when not is_nil(total_start) <-
           from(d in Download, select: min(d.accessed_at)) |> Repo.one(),
         total_end when not is_nil(total_end) <-
           from(d in Download, select: max(d.accessed_at)) |> Repo.one() do
      Date.range(DateTime.to_date(total_start), DateTime.to_date(total_end))
      |> Enum.each(&Radiator.Tracking.CleanerWorker.enqueue/1)
    end
  end

  @doc """
  Clean downloads for given day.
  """
  def clean_day(date = %Date{}) do
    query_for_duplicates(date)
    |> Repo.all(timeout: :timer.minutes(1))
    |> Enum.reduce([], &get_duplicate_ids/2)
    |> delete_duplicates()
  end

  defp get_duplicate_ids(%{ids: ids}, acc) do
    [_keep | discard] = ids |> String.split(",") |> Enum.map(&String.to_integer/1) |> Enum.sort()

    discard ++ acc
  end

  defp delete_duplicates(ids = [_ | _]),
    do: from(d in Download, where: d.id in ^ids) |> Repo.delete_all(timeout: :timer.minutes(1))

  defp delete_duplicates([]), do: :ok

  # Fetches duplicate downloads in given day.
  #
  # Column "ids" contains ids of duplicate downloads.
  # All but one of each must be removed or marked as dirty.
  #
  # PERF: could make this faster with a custom index
  defp query_for_duplicates(date) do
    start_time = NaiveDateTime.from_erl!({{date.year, date.month, date.day}, {0, 0, 0}})
    end_time = NaiveDateTime.from_erl!({{date.year, date.month, date.day}, {23, 59, 59}})

    from(
      d in Download,
      select: %{
        request_id: d.request_id,
        cnt: count(d.id),
        aggday: fragment("to_char(?, 'YYYYMMDD')", d.accessed_at),
        ids: fragment("array_to_string(array_agg(?), ',')", d.id)
      },
      where: d.accessed_at >= ^start_time,
      where: d.accessed_at <= ^end_time,
      group_by: [
        d.file_id,
        d.request_id,
        fragment("to_char(?, 'YYYYMMDD')", d.accessed_at)
      ],
      having: count(d.id) > 1
    )
  end
end
