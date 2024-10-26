defmodule Radiator.NodeAnalyzer do
  @moduledoc """
  This module provides a behaviour for implementing node analyzers and is the entry point for analyzing nodes.

  ## Examples

      iex> defmodule ExampleAnalyzer do
      ...>   @behaviour Radiator.NodeAnalyzer
      ...>   def match?(_node), do: true
      ...>   def analyze(_node), do: [%{data: "example"}]
      ...> end
      iex> Radiator.NodeAnalyzer.do_analyze("", [ExampleAnalyzer])
      [%{data: "example"}]
  """

  # alias Radiator.Outline.Node

  @callback match?(content :: String.t()) :: boolean
  @callback analyze(content :: String.t()) :: list(map())

  # @spec analyze(Node.t(), list()) :: list()
  # @spec analyze(String.t(), list()) :: list()
  def do_analyze(content, analyzers \\ analyzers()) do
    analyzers
    |> Enum.filter(& &1.match?(content))
    |> Enum.flat_map(& &1.analyze(content))
  end

  @spec analyzers() :: [module()]
  defp analyzers do
    {:ok, modules} = :application.get_key(:radiator, :modules)

    modules
    |> Enum.filter(fn module ->
      try do
        module.__info__(:attributes)
        |> Keyword.get(:behaviour, [])
        |> Enum.member?(Radiator.NodeAnalyzer)
      rescue
        _ -> false
      end
    end)
  end
end
