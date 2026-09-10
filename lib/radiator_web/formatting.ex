defmodule RadiatorWeb.Formatting do
  @moduledoc """
  Human-readable dates, durations and enum labels for templates.
  """

  @minute 60
  @hour 60 * @minute
  @day 24 * @hour

  @doc """
  How long ago `datetime` was, in words: "gerade eben", "vor 5 Minuten",
  "vor 2 Tagen". Anything older than a week is given as a date.
  """
  def relative_time(datetime, now \\ DateTime.utc_now())

  def relative_time(nil, _now), do: nil

  def relative_time(datetime, now) do
    seconds = DateTime.diff(now, datetime, :second)

    cond do
      seconds < @minute -> "gerade eben"
      seconds < @hour -> ago(div(seconds, @minute), "Minute", "Minuten")
      seconds < @day -> ago(div(seconds, @hour), "Stunde", "Stunden")
      seconds < 7 * @day -> ago(div(seconds, @day), "Tag", "Tagen")
      true -> "am " <> date(datetime)
    end
  end

  defp ago(1, singular, _plural), do: "vor 1 #{singular}"
  defp ago(count, _singular, plural), do: "vor #{count} #{plural}"

  @doc "A date as `09.09.2026`."
  def date(nil), do: nil
  def date(datetime), do: Calendar.strftime(datetime, "%d.%m.%Y")

  @doc "A duration in seconds as `1:02:03`, or `1:05` under an hour."
  def duration(nil), do: nil

  def duration(seconds) when is_integer(seconds) do
    hours = div(seconds, @hour)
    minutes = div(rem(seconds, @hour), @minute)
    rest = rem(seconds, @minute)

    if hours > 0 do
      "#{hours}:#{pad(minutes)}:#{pad(rest)}"
    else
      "#{minutes}:#{pad(rest)}"
    end
  end

  defp pad(number), do: number |> Integer.to_string() |> String.pad_leading(2, "0")

  @doc ~S(Label/value pairs of an `Ash.Type.Enum` for `<.input type="select">`.)
  def enum_options(enum), do: Enum.map(enum.values(), &{enum.label(&1), &1})
end
