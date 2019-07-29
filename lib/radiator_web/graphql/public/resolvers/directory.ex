defmodule RadiatorWeb.GraphQL.Public.Resolvers.Directory do
  alias Radiator.Directory
  alias Radiator.Directory.{Episode, Podcast, Network}

  def list_networks(_parent, _args, _resolution) do
    {:ok, Directory.list_networks()}
  end

  def find_network(_parent, %{id: id}, _resolution) do
    case Directory.get_network(id) do
      nil -> {:error, "Network ID #{id} not found"}
      network -> {:ok, network}
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

  def find_episode(_parent, %{id: id}, _resolution) do
    case Directory.get_episode(id) do
      nil -> {:error, "Episode ID #{id} not found"}
      episode -> {:ok, episode}
    end
  end

  def find_audio(%Episode{} = episode, _args, _resolution) do
    {:ok, episode.audio}
  end

  def get_image_url(subject, args, resolution) do
    RadiatorWeb.GraphQL.Admin.Resolvers.Editor.get_image_url(subject, args, resolution)
  end

  def get_episodes_count(%Podcast{id: podcast_id}, _, _) do
    episodes_count = Directory.get_episodes_count_for_podcast!(podcast_id)

    {:ok, episodes_count}
  end
end
