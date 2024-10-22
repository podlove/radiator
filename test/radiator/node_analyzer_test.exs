defmodule Radiator.NodeAnalyzerTest do
  use ExUnit.Case, async: true
  doctest Radiator.NodeAnalyzer

  alias Radiator.NodeAnalyzer
  alias Radiator.NodeAnalyzer.DummyAnalyzer
  alias Radiator.Outline.Node

  test "analyze/2 returns a list of results from all analyzers" do
    assert NodeAnalyzer.analyze(%Node{}, [DummyAnalyzer]) == [{:ok, []}]
    assert NodeAnalyzer.analyze(%Node{}, []) == [{:ok, []}]
  end
end
