defmodule Radiator.Podcasts.ItunesShowType do
  use Ash.Type.Enum, values: [:episodic, :serial]
end
