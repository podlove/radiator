defmodule Radiator.Feed.Storage do
  alias Radiator.Feed.Generator
  alias Radiator.Media.FeedFile

  @doc """
  Generates all feed pages and stores them.
  """
  def generate(podcast_id, opts \\ []) do
    # fetch old files
    {:ok, old_feed_files} = Radiator.Storage.list_feed_files(podcast_id)

    # generate new files
    Generator.generate(podcast_id, opts)
    |> Enum.with_index(1)
    |> Enum.each(fn {xml, page} ->
      {:ok, file_path} = Temp.path()
      :ok = File.write(file_path, xml)

      store(file_path, podcast_id: podcast_id, page: page)

      File.rm(file_path)
    end)

    # fetch new files
    {:ok, current_feed_files} = Radiator.Storage.list_feed_files(podcast_id)

    delete_orphaned_feed_pages(old_feed_files, current_feed_files)

    :ok
  end

  # if there are less pages than before, delete orphaned feed pages
  defp delete_orphaned_feed_pages(old_files, current_files) do
    Enum.each(old_files, fn {old_key, old_modified} ->
      List.keyfind(current_files, old_key, 0)
      |> case do
        {_, new_modified} when new_modified == old_modified ->
          Radiator.Storage.delete_file(old_key)

        _ ->
          :ok
      end
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
