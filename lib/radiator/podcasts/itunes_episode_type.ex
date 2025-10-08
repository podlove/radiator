defmodule Radiator.Podcasts.ItunesEpisodeType do
  use Ash.Type.Enum, values: [:full, :trailer, :bonus]
end
