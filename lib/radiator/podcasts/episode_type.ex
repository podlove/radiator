defmodule Radiator.Podcasts.EpisodeType do
  @moduledoc "The values of `itunes:episodeType`."

  use Ash.Type.Enum,
    values: [
      full: [label: "Vollständige Episode"],
      trailer: [label: "Trailer"],
      bonus: [label: "Bonus"]
    ]
end
