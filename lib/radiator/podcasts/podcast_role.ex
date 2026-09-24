defmodule Radiator.Podcasts.PodcastRole do
  @moduledoc "What a user may do with a podcast they are a member of."

  use Ash.Type.Enum,
    values: [
      owner: [label: "Inhaber"]
    ]
end
