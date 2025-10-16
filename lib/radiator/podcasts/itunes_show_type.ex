defmodule Radiator.Podcasts.ItunesShowType do
  @moduledoc false

  use Ash.Type.Enum, values: [:episodic, :serial]
end
