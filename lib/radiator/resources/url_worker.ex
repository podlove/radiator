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
    # TODO - handle old existing urls for this node, error handling!
    Enum.each(result, fn info ->
      {:ok, _url} =
        info
        |> Map.put(:node_id, node_id)
        |> Map.put(:url, info.parsed_url)
        |> Resources.create_url()
    end)

    :ok
  end
end
