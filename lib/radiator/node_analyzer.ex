defmodule Radiator.NodeAnalyzer do
  @moduledoc """
  This module provides a behaviour for implementing node analyzers and is the entry point for analyzing nodes.

  ## Examples

      iex> defmodule ExampleAnalyzer do
      ...>   @behaviour Radiator.NodeAnalyzer
      ...>   def match?(_node), do: true
      ...>   def analyze(_node), do: [%{data: "example"}]
      ...> end
      iex> Radiator.NodeAnalyzer.do_analyze(%Radiator.Outline.Node{}, [ExampleAnalyzer])
      [%{data: "example"}]
  """

  alias Radiator.Outline.Node

  @callback match?(node :: Node.t()) :: boolean
  @callback analyze(node :: Node.t()) :: list(map())

  @doc """
  Analyzes a node with the given analyzers by calling
  `match?/1` and `analyze/1` on each analyzer.

  The analyzers need to be modules that implement the `Radiator.NodeAnalyzer` behaviour.
  """
  def do_analyze(%Node{} = node, analyzers \\ analyzers()) do
    analyzers
    |> Enum.filter(& &1.match?(node))
    |> Enum.flat_map(& &1.analyze(node))
  end

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
