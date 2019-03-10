defmodule RadiatorWeb.Resolvers.Directory do
  alias Radiator.Directory
  alias Radiator.Directory.{Episode, Podcast}

  def list_podcasts(_parent, _args, _resolution) do
    {:ok, Directory.list_podcasts()}
  end

  def find_podcast(%Episode{} = episode, _args, _resolution) do
    case Directory.get_podcast(episode.podcast_id) do
      nil -> {:error, "Podcast ID #{episode.podcast_id} not found"}
      podcast -> {:ok, podcast}
    end
  end

  def find_podcast(_parent, %{id: id}, _resolution) do
    case Directory.get_podcast(id) do
      nil -> {:error, "Podcast ID #{id} not found"}
      podcast -> {:ok, podcast}
    end
  end

  def create_podcast(_parent, args, _resolution) do
    Directory.create_podcast(args)
  end

  def update_podcast(_parent, args = %{id: id}, _resolution) do
    case Directory.get_podcast(id) do
      nil -> {:error, "Podcast ID #{id} not found"}
      podcast -> Directory.update_podcast(podcast, args)
    end
  end

  def delete_podcast(_parent, %{id: id}, _resolution) do
    case Directory.get_podcast(id) do
      nil -> {:error, "Podcast ID #{id} not found"}
      podcast -> Directory.delete_podcast(podcast)
    end
  end

  def find_episode(_parent, %{id: id}, _resolution) do
    {:ok, Directory.get_episode!(id)}
  end

  def list_episodes(%Podcast{} = podcast, _args, _resolution) do
    {:ok, Directory.list_episodes(podcast)}
  end
end
