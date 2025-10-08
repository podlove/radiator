defmodule Radiator.Import.Tools do
  @moduledoc """
  Shared utility functions for all importers

  This module provides common data transformation and parsing functions
  used across different import sources.
  """

  @doc """
  Converts duration string from "HH:MM:SS" format to milliseconds.

  ## Examples

      iex> Radiator.Import.Tools.parse_duration("01:23:45")
      5025000

      iex> Radiator.Import.Tools.parse_duration("45:30")
      2730000

      iex> Radiator.Import.Tools.parse_duration("30")
      30000

      iex> Radiator.Import.Tools.parse_duration(nil)
      nil
  """
  def parse_duration(duration_string) when is_binary(duration_string) do
    seconds =
      duration_string
      |> String.split(":")
      |> Enum.reverse()
      |> Enum.with_index()
      |> Enum.reduce(0, fn {time_part, index}, acc ->
        {time_int, _} = Integer.parse(time_part)
        acc + time_int * :math.pow(60, index)
      end)
      |> trunc()

    # Convert seconds to milliseconds
    seconds * 1000
  end

  def parse_duration(_), do: nil

  @doc """
  Converts chapter start time from "HH:MM:SS.mmm" format to milliseconds.

  Handles both "HH:MM:SS.mmm" and "HH:MM:SS" formats.

  ## Examples

      iex> Radiator.Import.Tools.parse_chapter_time("01:23:45.500")
      5025500

      iex> Radiator.Import.Tools.parse_chapter_time("01:23:45")
      5025000

      iex> Radiator.Import.Tools.parse_chapter_time(nil)
      0
  """
  def parse_chapter_time(time_string) when is_binary(time_string) do
    # Handle both "HH:MM:SS.mmm" and "HH:MM:SS" formats
    parts = String.split(time_string, ".")
    time_part = hd(parts)

    # Convert time to seconds first
    seconds =
      time_part
      |> String.split(":")
      |> Enum.reverse()
      |> Enum.with_index()
      |> Enum.reduce(0, fn {time_part, index}, acc ->
        {time_int, _} = Integer.parse(time_part)
        acc + time_int * :math.pow(60, index)
      end)
      |> trunc()

    # Add milliseconds if present
    milliseconds =
      case parts do
        [_, ms_part] ->
          # Pad or truncate to 3 digits
          ms_padded = String.pad_trailing(ms_part, 3, "0") |> String.slice(0, 3)
          {ms_int, _} = Integer.parse(ms_padded)
          ms_int

        _ ->
          0
      end

    # Convert to total milliseconds
    seconds * 1000 + milliseconds
  end

  def parse_chapter_time(_), do: 0

  @doc """
  Converts episode type string to iTunes episode type atom.

  ## Examples

      iex> Radiator.Import.Tools.convert_episode_type("full")
      :full

      iex> Radiator.Import.Tools.convert_episode_type("trailer")
      :trailer

      iex> Radiator.Import.Tools.convert_episode_type("bonus")
      :bonus

      iex> Radiator.Import.Tools.convert_episode_type("unknown")
      :full
  """
  def convert_episode_type("full"), do: :full
  def convert_episode_type("trailer"), do: :trailer
  def convert_episode_type("bonus"), do: :bonus
  def convert_episode_type(_), do: :full

  @doc """
  Converts show type string to iTunes show type atom.

  ## Examples

      iex> Radiator.Import.Tools.convert_show_type("episodic")
      :episodic

      iex> Radiator.Import.Tools.convert_show_type("serial")
      :serial

      iex> Radiator.Import.Tools.convert_show_type("unknown")
      :episodic
  """
  def convert_show_type("episodic"), do: :episodic
  def convert_show_type("serial"), do: :serial
  def convert_show_type(_), do: :episodic

  @doc """
  Flattens iTunes categories from nested arrays to flat array.

  Maximum 3 categories are allowed per podcast.

  ## Examples

      iex> Radiator.Import.Tools.flatten_categories([["Technology", "News"]])
      ["Technology", "News"]

      iex> Radiator.Import.Tools.flatten_categories(["Technology", "News", "Business", "Extra"])
      ["Technology", "News", "Business"]
  """
  def flatten_categories(categories) when is_list(categories) do
    categories
    |> Enum.flat_map(&flatten_category/1)
    |> Enum.take(3)
  end

  def flatten_categories(_), do: []

  defp flatten_category(category) when is_list(category), do: category
  defp flatten_category(category) when is_binary(category), do: [category]
  defp flatten_category(_), do: []

  @doc """
  Safely converts episode number from string to integer.

  ## Examples

      iex> Radiator.Import.Tools.parse_episode_number("42")
      42

      iex> Radiator.Import.Tools.parse_episode_number(42)
      42

      iex> Radiator.Import.Tools.parse_episode_number("not a number")
      nil

      iex> Radiator.Import.Tools.parse_episode_number(nil)
      nil
  """
  def parse_episode_number(episode_str) when is_binary(episode_str) do
    case Integer.parse(episode_str) do
      {num, _} -> num
      _ -> nil
    end
  end

  def parse_episode_number(num) when is_integer(num), do: num
  def parse_episode_number(_), do: nil

  @doc """
  Truncates summary to 4000 characters to match database constraint.

  Adds "..." at the end if truncated.

  ## Examples

      iex> Radiator.Import.Tools.truncate_summary("Short summary")
      "Short summary"

      iex> long = String.duplicate("a", 4001)
      iex> result = Radiator.Import.Tools.truncate_summary(long)
      iex> String.length(result)
      4000

      iex> Radiator.Import.Tools.truncate_summary(nil)
      nil
  """
  def truncate_summary(summary) when is_binary(summary) do
    if String.length(summary) > 4000 do
      String.slice(summary, 0, 3997) <> "..."
    else
      summary
    end
  end

  def truncate_summary(_), do: nil
end
