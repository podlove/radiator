defmodule Radiator.Feed.Worker do
  @moduledoc """
  Job Worker to generate feed files.
  """
  use Oban.Worker, queue: "feed", max_attempts: 2

  alias Radiator.Feed

  def enqueue(args) do
    args
    |> __MODULE__.new()
    |> Oban.insert()
  end

  def perform(%{"podcast_id" => podcast_id}, _job) do
    Feed.Storage.generate(podcast_id)
  end
end
