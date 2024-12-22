defmodule Radiator.EpisodeOutliner do
  alias Radiator.Outline.NodeRepository
  # alias Radiator.Outline
  alias Radiator.Podcast
  alias Radiator.Podcast.Episode

  @doc """
  Returns a list of all child nodes.
  """
  def list_nodes_by_episode_sorted(episode_id) do
    %Episode{outline_node_container: outline_node_container} = Podcast.get_episode!(episode_id)

    outline_node_container
    |> NodeRepository.list_nodes_by_node_container()
  end

  def insert_node(%{"episode_id" => episode_id} = attrs) do
    %Episode{outline_node_container: outline_node_container} = Podcast.get_episode!(episode_id)

    attrs
    |> Map.put("outline_node_container", outline_node_container)
    |> insert_node()
  end
end
