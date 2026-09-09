defmodule Radiator.Podcasts.PodcastType do
  @moduledoc "The values of `itunes:type`."

  use Ash.Type.Enum,
    values: [
      episodic: [label: "Episodisch"],
      serial: [label: "Fortlaufend"]
    ]

  @doc ~S(Label/value pairs for `<.input type="select">`.)
  def options, do: Enum.map(values(), &{label(&1), &1})
end
