defmodule Radiator.Podcasts.EpisodeType do
  @moduledoc "The values of `itunes:episodeType`."

  use Ash.Type.Enum,
    values: [
      full: [label: "Vollständige Episode"],
      trailer: [label: "Trailer"],
      bonus: [label: "Bonus"]
    ]

  @doc ~S(Label/value pairs for `<.input type="select">`.)
  def options, do: Enum.map(values(), &{label(&1), &1})
end
