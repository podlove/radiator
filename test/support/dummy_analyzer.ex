defmodule Radiator.NodeAnalyzer.DummyAnalyzer do
  @moduledoc false
  @behaviour Radiator.NodeAnalyzer

  def match?(_node), do: true

  def analyze(_node), do: {:ok, []}
end
