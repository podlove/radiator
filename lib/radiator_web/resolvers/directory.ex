defmodule RadiatorWeb.Resolvers.Directory do
  alias Radiator.Directory
  alias Radiator.Directory.{Episode, Podcast, Network}
  alias Radiator.EpisodeMeta

  def list_networks(_parent, _args, _resolution) do
    {:ok, Directory.list_networks()}
  end

  def find_network(_parent, %{id: id}, _resolution) do
    case Directory.get_network(id) do
      nil -> {:error, "Network ID #{id} not found"}
      network -> {:ok, network}
    end
  end

  def create_network(_parent, %{network: args}, _resolution) do
    Directory.create_network(args)
  end

  def update_network(_parent, %{id: id, network: args}, _resolution) do
    case Directory.get_network(id) do
      nil -> {:error, "Network ID #{id} not found"}
      network -> Directory.update_network(network, args)
    end
  end

  def list_podcasts(%Network{id: id}, _args, _resolution) do
    case Directory.get_network(id) do
      nil -> {:error, "Network ID #{id} not found"}
      network -> {:ok, Directory.list_podcasts(network)}
    end
  end

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

  def create_podcast(_parent, %{podcast: args, network_id: network_id}, _resolution) do
    case Directory.get_network(network_id) do
      nil -> {:error, "Valid network must be provided, ID #{network_id} not found"}
      network -> Directory.create_podcast(network, args)
    end
  end

  def update_podcast(_parent, %{id: id, podcast: args}, _resolution) do
    case Directory.get_podcast(id) do
      nil -> {:error, "Podcast ID #{id} not found"}
      podcast -> Directory.update_podcast(podcast, args)
    end
  end

  def publish_podcast(_parent, %{id: id}, _res) do
    case Directory.get_podcast(id) do
      nil -> {:error, "Podcast ID #{id} not found"}
      podcast -> Directory.publish_podcast(podcast)
    end
  end

  def depublish_podcast(_parent, %{id: id}, _res) do
    case Directory.get_podcast(id) do
      nil -> {:error, "Podcast ID #{id} not found"}
      podcast -> Directory.depublish_podcast(podcast)
    end
  end

  def delete_podcast(_parent, %{id: id}, _resolution) do
    case Directory.get_podcast(id) do
      nil -> {:error, "Podcast ID #{id} not found"}
      podcast -> Directory.delete_podcast(podcast)
    end
  end

  def is_published(%Podcast{published_at: nil}, _, _) do
    {:ok, false}
  end

  def is_published(%Podcast{published_at: date}, _, _) do
    case DateTime.compare(date, DateTime.utc_now()) do
      :lt -> {:ok, true}
      _ -> {:ok, false}
    end
  end

  def find_episode(_parent, %{id: id}, _resolution) do
    case Directory.get_episode(id) do
      nil -> {:error, "Episode ID #{id} not found"}
      episode -> {:ok, episode}
    end
  end

  def create_episode(_parent, %{podcast_id: podcast_id, episode: args}, _resolution) do
    case Directory.get_podcast(podcast_id) do
      nil -> {:error, "Podcast ID #{podcast_id} not found"}
      podcast -> Directory.create_episode(podcast, args)
    end
  end

  def update_episode(_parent, %{id: id, episode: args}, _resolution) do
    case Directory.get_episode(id) do
      nil -> {:error, "Episode ID #{id} not found"}
      episode -> Directory.update_episode(episode, args)
    end
  end

  def delete_episode(_parent, %{id: id}, _resolution) do
    case Directory.get_episode(id) do
      nil -> {:error, "episode ID #{id} not found"}
      episode -> Directory.delete_episode(episode)
    end
  end

  def list_chapters(%Episode{} = episode, _args, _resolution) do
    {:ok, EpisodeMeta.list_chapters(episode)}
  end

  def set_episode_chapters(_parent, %{id: id, chapters: chapters, type: type}, _resolution) do
    case Directory.get_episode(id) do
      nil -> {:error, "Episode ID #{id} not found"}
      episode -> EpisodeMeta.set_chapters(episode, chapters, String.to_existing_atom(type))
    end
  end
end
