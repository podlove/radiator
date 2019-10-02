defmodule Radiator.Feed.Storage do
  alias Radiator.Feed.Generator
  alias Radiator.Media.FeedFile

  @doc """
  Generates all feed pages and stores them.
  """
  def generate(podcast_id, opts \\ []) do
    Generator.generate(podcast_id, opts)
    |> Enum.with_index(1)
    |> Enum.each(fn {xml, page} ->
      {:ok, file_path} = Temp.path()
      :ok = File.write(file_path, xml)

      store(file_path, podcast_id: podcast_id, page: page)

      File.rm(file_path)
    end)
  end

  def store(file_path, podcast_id: podcast_id, page: page) do
    FeedFile.store({file_path, podcast_id: podcast_id, page: page})
  end

  def url(podcast_id: podcast_id, page: page) do
    FeedFile.url(
      {"",
       [
         podcast_id: podcast_id,
         page: page
       ]}
    )
  end
end
