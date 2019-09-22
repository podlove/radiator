defmodule RadiatorWeb.FormatHelpers do
  @moduledoc """
  General formatting view helpers that should be readily available
  """

  use Radiator.Constants, :permissions

  def format_date_relative(date) do
    with {:ok, result} <- Timex.format(date, "{relative}", :relative) do
      result
    else
      _ -> "-"
    end
  end

  def format_number(number, opts \\ [])

  def format_number(nil, _) do
    "-"
  end

  def format_number(number, opts) do
    with {:ok, result} <- Radiator.Cldr.Number.to_string(number, opts) do
      result
    end
  end

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
    format_normal_playtime_round_to_seconds(time)
  end

  def format_normal_playtime_round_to_seconds(nil) do
    ""
  end

  def format_normal_playtime_round_to_seconds(time) do
    (round(time / 1_000) * 1_000)
    |> format_normal_playtime()
    |> String.slice(0..-5)
  end

  # Since we are display formatting only, allow for nil
  def format_normal_playtime(nil), do: format_normal_playtime(0)

  def format_normal_playtime(time) do
    time
    |> Chapters.Formatters.Normalplaytime.Formatter.format()
    |> case do
      "00:" <> rest -> rest
      sth -> sth
    end
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

  def format_permission(perm) when is_permission(perm) do
    case perm do
      :own -> "owner"
      :manage -> "manager"
      :edit -> "editor"
      :readonly -> "viewer"
    end
  end

  def looks_like_html(binary) do
    Regex.match?(~r/\<\/?(br|ul|li|p|a)\s*?\/?>/, binary)
  end
end
