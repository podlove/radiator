defmodule Radiator.AudioMeta.DataloaderProvider do
  import Ecto.Query, warn: false

  alias Radiator.Repo
  alias Radiator.AudioMeta.Chapter

  def data() do
    Dataloader.Ecto.new(Repo, query: &query/2)
  end

  def query(Chapter, args) do
    chapters_query(args)
  end

  def query(queryable, _) do
    queryable
  end

  defp chapters_query(args) do
    Enum.reduce(args, Chapter, fn
      {:order, order}, query -> query |> order_by({^order, :start})
    end)
  end
end
