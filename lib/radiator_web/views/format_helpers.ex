defmodule RadiatorWeb.FormatHelpers do
  @moduledoc """
  General formatting view helpers that should be readily available
  """

  def format_bytes(number, precision \\ 2)

  def format_bytes(nil, _) do
    "? Bytes"
  end

  def format_bytes(number, _precision) when number < 1_024 do
    "#{number} Bytes"
  end

  def format_bytes(number, precision) when number < 1_048_576 do
    "#{Float.round(number / 1024, precision)} kB"
  end

  def format_bytes(number, precision) do
    "#{Float.round(number / 1024 / 1024, precision)} MB"
  end

  def format_chapter_time(time) do
    time = round(time / 1_000) * 1_000

    time
    |> Chapters.Formatters.Normalplaytime.Formatter.format()
    |> case do
      "00:" <> rest -> rest
      sth -> sth
    end
    |> String.slice(0..-5)
  end

  def shorten_string(s, max_length, ellipsis \\ "...")
  # used for fields that allow for nil (e.g. Podcast.tagline)
  def shorten_string(nil, _, _) do
    ""
  end

  def shorten_string(s, max_length, ellipsis) when is_binary(s) do
    s
    |> String.split(" ")
    |> Enum.reduce_while("", fn x, prev_string ->
      new_string =
        case prev_string do
          "" -> x
          nonempty_string -> nonempty_string <> " " <> x
        end

      if String.length(new_string) < max_length do
        {:cont, new_string}
      else
        {:halt, prev_string <> ellipsis}
      end
    end)
  end
end
