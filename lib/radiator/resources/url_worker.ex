defmodule Radiator.Resources.UrlWorker do
  @moduledoc """
  job to extract urls from content and persist URLs
  """
  alias __MODULE__
  alias Radiator.NodeAnalyzer
  alias Radiator.Resources

  def extract_urls(node_id, content) do
    Radiator.Job.start_job(
      worker: &UrlWorker.perform/2,
      arguments: [node_id: node_id, content: content]
    )
  end

  def perform(node_id, content) do
    url_attributes = NodeAnalyzer.analyze(content)

    _created_urls = Resources.rebuild_node_urls(node_id, url_attributes)
    :ok
  end
end
