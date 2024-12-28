defmodule Radiator.EpisodeOutliner do
  @moduledoc """
    perhaps an intermediate module to connect the outliner and the episode
  """
  alias Radiator.Outline.Node
  alias Radiator.Podcast
  alias Radiator.Podcast.Episode

  def insert_node(%{"episode_id" => episode_id} = attrs) do
    %Episode{outline_node_container: outline_node_container} = Podcast.get_episode!(episode_id)

    attrs
    |> Map.put("outline_node_container", outline_node_container)
    |> insert_node()
  end

  def episode_id_for_node(node) do
    node
    |> episode_for_node()
    |> episode_id()
  end

  def episode_for_node(%Node{outline_node_container_id: outline_node_container_id}) do
    Podcast.get_episode_by_container_id(outline_node_container_id)
    # case Podcast.get_episode_by_container_id(outline_node_container_id) do
    #   {:ok, episode} -> episode
    #   _ -> nil
    # end
  end

  defp episode_id(nil), do: nil
  defp episode_id(%Episode{id: id}), do: id
end
