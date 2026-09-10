defmodule Radiator.Podcasts.PodcastType do
  @moduledoc "The values of `itunes:type`."

  use Ash.Type.Enum,
    values: [
      episodic: [label: "Episodisch"],
      serial: [label: "Fortlaufend"]
    ]
end
