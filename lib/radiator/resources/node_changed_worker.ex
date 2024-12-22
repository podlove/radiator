defmodule Radiator.Resources.NodeChangedWorker do
  @moduledoc """
  job to extract urls from content and persist URLs
  """
  alias __MODULE__
  alias Radiator.NodeAnalyzer
  alias Radiator.Outline.NodeRepository
  alias Radiator.Resources

  def trigger_analyze(node_id) do
    Radiator.Job.start_job(
      worker: &NodeChangedWorker.perform/1,
      arguments: [node_id: node_id]
    )
  end

  def perform(node_id) do
    analyzers = [Radiator.NodeAnalyzer.UrlAnalyzer]
    node = NodeRepository.get_node!(node_id)

    url_attributes =
      node
      |> NodeAnalyzer.do_analyze(analyzers)
      |> Enum.map(fn attributes ->
        attributes
        |> Map.put(:node_id, node_id)
        |> Map.put(:episode_id, node.episode_id)
      end)

    _created_urls = Resources.rebuild_node_urls(node_id, url_attributes)
    :ok
  end
end
