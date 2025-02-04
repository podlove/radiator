defmodule Radiator.EpisodeOutliner do
  @moduledoc """
    an intermediate module to connect the outliner and the episode
  """
  alias Radiator.Outline.Node
  alias Radiator.Podcast
  alias Radiator.Podcast.Episode

  def episode_id_for_node(node) do
    node
    |> episode_for_node()
    |> episode_id()
  end

  def episode_for_node(%Node{outline_node_container_id: outline_node_container_id}) do
    Podcast.get_episode_by_container_id(outline_node_container_id)
  end

  @doc """
    Not yet sure wether we want this
    Note: Will crash when episode does not exist
  """
  def container_with_episode_id(episode_id) do
    Podcast.get_episode!(episode_id).outline_node_container_id
  end

  defp episode_id(nil), do: nil
  defp episode_id(%Episode{id: id}), do: id
end
