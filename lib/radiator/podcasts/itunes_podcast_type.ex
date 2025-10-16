defmodule Radiator.Podcasts.ItunesPodcastType do
  @moduledoc false

  use Ash.Type.Enum, values: [:episodic, :serial]
end
