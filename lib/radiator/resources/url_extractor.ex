defmodule Radiator.Resources.UrlExtractor do
  @moduledoc """
  extract urls
  """
  @url_regex ~r/((([A-Za-z]{3,9}:(?:\/\/)?)(?:[-;:&=\+\$,\w]+@)?[A-Za-z0-9.-]+|(?:www.|[-;:&=\+\$,\w]+@)[A-Za-z0-9.-]+)((?:\/[\+~%\/.\w-_]*)?\??(?:[-\+=&;%@.\w_]*)#?(?:[\w]*))?)/

  def extract_urls(text) do
    text
    |> extract_url_positions
    |> Enum.map(fn {start_bytes, size_bytes} ->
      %{
        start_bytes: start_bytes,
        size_bytes: size_bytes,
        parsed_url: String.byte_slice(text, start_bytes, size_bytes)
      }
    end)
  end

  # should return two URLs that we can parse/scrape later
  # @return [{Integer.t, Integer.t}] list of positions of URLs in the text
  def extract_url_positions(text) do
    @url_regex
    |> Regex.scan(text, return: :index)
    |> Enum.map(&hd/1)
  end
end
