defmodule Radiator.Directory.DataloaderProvider do
  import Ecto.Query, warn: false

  alias Radiator.Repo
  alias Radiator.Directory
  alias Radiator.Directory.Episode

  def data() do
    Dataloader.Ecto.new(Repo, query: &query/2)
  end

  def query(Episode, args) do
    args
    # pagination for gql is handled in resolver
    |> Map.put(:items_per_page, :unlimited)
    |> Directory.episodes_query()
  end

  def query(queryable, _) do
    queryable
  end
end
