defmodule Radiator.Feeds.Parser.Coercion do
  @moduledoc """
  Converts the text values of an RSS feed into Elixir values.

  Every function is pure and returns `nil` when the value is missing or cannot
  be read. A feed must not fail to import just because one field holds
  nonsense.
  """

  @months %{
    "jan" => 1,
    "feb" => 2,
    "mar" => 3,
    "apr" => 4,
    "may" => 5,
    "jun" => 6,
    "jul" => 7,
    "aug" => 8,
    "sep" => 9,
    "oct" => 10,
    "nov" => 11,
    "dec" => 12
  }

  # RFC 5322 obs-zone plus the european abbreviations that turn up in feeds.
  # Anything else alphabetic is treated as "-0000" — the RFC's way of saying
  # the sender's zone is unknown — rather than discarding the whole date.
  @named_zones %{
    "gmt" => 0,
    "ut" => 0,
    "utc" => 0,
    "z" => 0,
    "est" => -5 * 3600,
    "edt" => -4 * 3600,
    "cst" => -6 * 3600,
    "cdt" => -5 * 3600,
    "mst" => -7 * 3600,
    "mdt" => -6 * 3600,
    "pst" => -8 * 3600,
    "pdt" => -7 * 3600,
    "wet" => 0,
    "west" => 3600,
    "bst" => 3600,
    "cet" => 3600,
    "cest" => 2 * 3600,
    "eet" => 2 * 3600,
    "eest" => 3 * 3600
  }

  @true_values ~w(yes true)
  @false_values ~w(no false)

  @doc """
  Reads a date in RFC 2822 format, as used by `<pubDate>`.

      iex> Radiator.Feeds.Parser.Coercion.datetime("Fri, 28 Aug 2026 17:14:26 +0000")
      ~U[2026-08-28 17:14:26Z]
  """
  def datetime(nil), do: nil

  def datetime(value) when is_binary(value) do
    value
    |> String.trim()
    |> String.replace(~r/^[A-Za-z]{3},\s*/, "")
    |> String.split(~r/\s+/)
    |> parse_rfc2822_parts()
  end

  defp parse_rfc2822_parts([day, month, year, time | zone]) do
    with {:ok, day} <- to_int(day),
         {:ok, month} <- month_number(month),
         {:ok, year} <- year_number(year),
         {:ok, {hour, minute, second}} <- clock(time),
         {:ok, offset} <- zone_offset(zone),
         {:ok, naive} <- NaiveDateTime.new(year, month, day, hour, minute, second) do
      naive
      |> DateTime.from_naive!("Etc/UTC")
      |> DateTime.add(-offset, :second)
    else
      _ -> nil
    end
  end

  defp parse_rfc2822_parts(_parts), do: nil

  # RFC 5322 §4.3: a two-digit year below 50 means 20xx, one of 50 and above
  # means 19xx, and so does any three-digit year. Taken verbatim, "26" would
  # otherwise land in the year 26 AD and sort the episode to the very front of
  # the show forever.
  defp year_number(value) do
    case to_int(value) do
      {:ok, year} when year < 50 -> {:ok, year + 2000}
      {:ok, year} when year < 1000 -> {:ok, year + 1900}
      {:ok, year} -> {:ok, year}
      :error -> :error
    end
  end

  defp month_number(name) do
    case Map.fetch(@months, String.downcase(name)) do
      {:ok, number} -> {:ok, number}
      :error -> :error
    end
  end

  defp clock(time) do
    case String.split(time, ":") do
      [hour, minute] -> build_clock(hour, minute, "0")
      [hour, minute, second] -> build_clock(hour, minute, second)
      _other -> :error
    end
  end

  defp build_clock(hour, minute, second) do
    with {:ok, hour} <- to_int(hour),
         {:ok, minute} <- to_int(minute),
         {:ok, second} <- to_int(second) do
      {:ok, {hour, minute, second}}
    end
  end

  defp zone_offset([]), do: {:ok, 0}

  defp zone_offset([zone | _rest]) do
    cond do
      Map.has_key?(@named_zones, String.downcase(zone)) ->
        {:ok, Map.fetch!(@named_zones, String.downcase(zone))}

      Regex.match?(~r/^[+-]\d{4}$/, zone) ->
        numeric_zone_offset(zone)

      Regex.match?(~r/^[A-Za-z]{1,5}$/, zone) ->
        {:ok, 0}

      true ->
        :error
    end
  end

  defp numeric_zone_offset(<<sign::binary-1, hours::binary-2, minutes::binary-2>>) do
    {:ok, hours} = to_int(hours)
    {:ok, minutes} = to_int(minutes)
    seconds = hours * 3600 + minutes * 60

    {:ok, if(sign == "-", do: -seconds, else: seconds)}
  end

  @doc """
  Reads `itunes:duration` in the three common notations.

      iex> Radiator.Feeds.Parser.Coercion.duration_seconds("1:02:03")
      3723
  """
  def duration_seconds(nil), do: nil

  def duration_seconds(value) when is_binary(value) do
    value
    |> String.trim()
    |> String.split(".", parts: 2)
    |> hd()
    |> String.split(":")
    |> Enum.reverse()
    |> Enum.map(&to_int/1)
    |> sum_units([1, 60, 3600])
  end

  defp sum_units(parts, factors) when length(parts) <= 3 do
    parts
    |> Enum.zip(factors)
    |> Enum.reduce_while(0, fn
      {{:ok, value}, factor}, acc -> {:cont, acc + value * factor}
      {:error, _factor}, _acc -> {:halt, nil}
    end)
  end

  defp sum_units(_parts, _factors), do: nil

  @doc """
  Reads an NPT time as used by the `start` attribute of `psc:chapter` and
  returns milliseconds.

      iex> Radiator.Feeds.Parser.Coercion.npt_ms("00:12:34.567")
      754567
  """
  def npt_ms(nil), do: nil

  def npt_ms(value) when is_binary(value) do
    {clock, fraction} =
      case String.split(String.trim(value), ".", parts: 2) do
        [clock] -> {clock, 0}
        [clock, fraction] -> {clock, fraction_to_ms(fraction)}
      end

    case duration_seconds(clock) do
      nil -> nil
      seconds -> seconds * 1000 + fraction
    end
  end

  defp fraction_to_ms(fraction) do
    case fraction |> String.slice(0, 3) |> String.pad_trailing(3, "0") |> to_int() do
      {:ok, value} -> value
      :error -> 0
    end
  end

  @doc """
  Reads the boolean notations that occur in podcast feeds.

      iex> Radiator.Feeds.Parser.Coercion.boolean("yes")
      true
  """
  def boolean(nil), do: nil

  def boolean(value) when is_binary(value) do
    normalized = value |> String.trim() |> String.downcase()

    cond do
      normalized in @true_values -> true
      normalized in @false_values -> false
      true -> nil
    end
  end

  @doc """
  Reads an integer, ignoring surrounding whitespace.

      iex> Radiator.Feeds.Parser.Coercion.integer(" 42 ")
      42
  """
  def integer(nil), do: nil

  def integer(value) when is_binary(value) do
    case to_int(value) do
      {:ok, number} -> number
      :error -> nil
    end
  end

  defp to_int(value) do
    case value |> String.trim() |> Integer.parse() do
      {number, ""} -> {:ok, number}
      _other -> :error
    end
  end
end
