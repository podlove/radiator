defmodule Radiator.NodeAnalyzer.UrlAnalyzer do
  @behaviour Radiator.NodeAnalyzer

  require Logger

  @impl true
  def match?(content) do
    extract_uris(content) != []
  end

  @impl true
  def analyze(content) do
    for {range, uri} <- extract_uris(content) do
      data =
        case analyze_uri(uri) do
          {:ok, data} -> data
          {:error, _} -> %{}
        end

      %{
        start_bytes: range.first,
        size_bytes: range.last - range.first + 1,
        url: uri,
        data: data
      }
    end
  end

  defp analyze_uri(uri) do
    uri
    |> URI.parse()
    |> unfurl()
  end

  defp unfurl(nil) do
    {:error, :no_url}
  end

  defp unfurl(uri) do
    case WebInspector.unfurl(URI.to_string(uri)) do
      {:ok, data} ->
        {:ok, data}

      {:error, err} ->
        Logger.error("Could not unfurl uri #{inspect(uri)}: #{inspect(err)}")
        {:error, err}
    end
  end

  @spec extract_uris(String.t()) :: [{Range.t(), String.t()}]
  defp extract_uris(content) do
    content
    |> String.split(~r/\s+/, trim: false, include_captures: true)
    |> add_ranges()
    |> Enum.filter(fn {_range, string} -> valid_uri?(string) end)
  end

  @spec valid_uri?(String.t()) :: boolean()
  defp valid_uri?(string) do
    uri = URI.parse(string)
    uri.scheme in ~w(http https) && uri.host != nil
  end

  @spec add_ranges([String.t()]) :: [{Range.t(), String.t()}]
  defp add_ranges(strings) do
    Enum.reduce(strings, [], &add_ranges/2)
    |> Enum.reverse()
  end

  defp add_ranges(string, []) do
    [{0..(String.length(string) - 1), string}]
  end

  defp add_ranges(string, [{_first..prev_last//_, _string} | _rest] = acc) do
    first = prev_last + 1
    last = prev_last + max(String.length(string), 1)
    [{first..last, string} | acc]
  end
end
