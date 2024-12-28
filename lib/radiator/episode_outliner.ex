defmodule Radiator.EpisodeOutliner do
  @moduledoc """
    perhaps an intermediate module to connect the outliner and the episode
  """
  alias Radiator.Podcast
  alias Radiator.Podcast.Episode

  def insert_node(%{"episode_id" => episode_id} = attrs) do
    %Episode{outline_node_container: outline_node_container} = Podcast.get_episode!(episode_id)

    attrs
    |> Map.put("outline_node_container", outline_node_container)
    |> insert_node()
  end
end
