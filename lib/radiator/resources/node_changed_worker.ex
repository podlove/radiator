defmodule Radiator.Resources.NodeChangedWorker do
  @moduledoc """
  job to extract urls from content and persist URLs
  """
  alias __MODULE__
  alias Radiator.EpisodeOutliner
  alias Radiator.EventStore
  alias Radiator.NodeAnalyzer
  alias Radiator.Outline.Dispatch
  alias Radiator.Outline.Event.UrlsAnalyzedEvent
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
    episode_id = EpisodeOutliner.episode_id_for_node(node)

    url_attributes =
      node
      |> NodeAnalyzer.do_analyze(analyzers)
      |> Enum.map(fn attributes ->
        attributes
        |> Map.put(:node_id, node_id)
        |> Map.put(:episode_id, episode_id)
      end)

    url_resources = Resources.rebuild_node_urls(node_id, url_attributes)

    if url_resources != [] do
      %UrlsAnalyzedEvent{
        node_id: node_id,
        urls: url_resources,
        episode_id: node.episode_id
      }
      |> EventStore.persist_event()
      |> Dispatch.broadcast()
    end

    :ok
  end
end
