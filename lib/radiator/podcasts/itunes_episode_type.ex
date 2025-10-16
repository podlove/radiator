defmodule Radiator.Podcasts.ItunesEpisodeType do
  @moduledoc false

  use Ash.Type.Enum, values: [:full, :trailer, :bonus]
end
