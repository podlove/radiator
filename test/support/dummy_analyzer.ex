defmodule Radiator.NodeAnalyzer.DummyAnalyzer do
  @behaviour Radiator.NodeAnalyzer

  def match?(_node), do: true

  def analyze(_node), do: {:ok, []}
end
