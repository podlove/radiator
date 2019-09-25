defmodule Radiator.Directory.Editor.DataloaderProvider do
  import Ecto.Query, warn: false

  alias Radiator.Repo
  alias Radiator.Directory.{Episode, EpisodeQuery}

  def data() do
    Dataloader.Ecto.new(Repo, query: &query/2)
  end

  def query(Episode, args) do
    args
    # pagination for gql is handled in resolver
    |> Map.put(:items_per_page, :unlimited)
    |> Map.put(:published, :any)
    |> EpisodeQuery.build()
  end

  def query(queryable, _) do
    queryable
  end
end
