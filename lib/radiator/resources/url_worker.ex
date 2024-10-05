defmodule Radiator.Resources.UrlWorker do
  @moduledoc """
  job to extract urls from content and persist URLs
  """
  alias __MODULE__
  alias Radiator.Resources
  alias Radiator.Resources.UrlExtractor

  def extract_urls(node_id, content) do
    Radiator.Job.start_job(
      worker: &UrlWorker.perform/2,
      arguments: [node_id: node_id, content: content]
    )
  end

  def perform(node_id, content) do
    result = UrlExtractor.extract_urls(content)

    url_attributes =
      Enum.map(result, fn info ->
        info
        |> Map.put(:url, info.parsed_url)
        |> Map.delete(:parsed_url)
      end)

    _created_urls = Resources.rebuild_node_urls(node_id, url_attributes)
    :ok
  end
end
