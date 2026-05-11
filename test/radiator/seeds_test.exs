defmodule Radiator.SeedsTest do
  use Radiator.DataCase, async: true

  test "seeds are successfully" do
    assert :ok == Mix.Task.run("run", ["priv/repo/seeds.exs"])
  end
end
