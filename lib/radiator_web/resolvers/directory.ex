defmodule RadiatorWeb.Resolvers.Directory do
  alias Radiator.Directory
  alias Radiator.Directory.{Episode, Podcast, Network}
  alias Radiator.EpisodeMeta
  alias Radiator.Media

  alias Directory.Editor

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
    user = Editor.Owner.api_user_shim()
    # TODO: use the correct user once authentication is in place for graphql
    case Editor.Owner.create_network(user, args) do
      {:ok, %{network: network}} -> {:ok, network}
      _ -> {:error, "Could not create network with #{args}"}
    end
  end

  def update_network(_parent, %{id: id, network: args}, _resolution) do
    case Directory.get_network(id) do
      nil -> {:error, "Network ID #{id} not found"}
      network -> Editor.Owner.update_network(network, args)
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
      network -> Editor.Manager.create_podcast(network, args)
    end
  end

  def update_podcast(_parent, %{id: id, podcast: args}, _resolution) do
    case Directory.get_podcast(id) do
      nil -> {:error, "Podcast ID #{id} not found"}
      podcast -> Editor.Manager.update_podcast(podcast, args)
    end
  end

  def publish_podcast(_parent, %{id: id}, _res) do
    case Directory.get_podcast(id) do
      nil ->
        {:error, "Podcast ID #{id} not found"}

      podcast ->
        Editor.Manager.publish_podcast(podcast)
    end
  end

  def depublish_podcast(_parent, %{id: id}, _res) do
    case Directory.get_podcast(id) do
      nil ->
        {:error, "Podcast ID #{id} not found"}

      podcast ->
        Editor.Manager.depublish_podcast(podcast)
    end
  end

  def delete_podcast(_parent, %{id: id}, _resolution) do
    case Directory.get_podcast(id) do
      nil -> {:error, "Podcast ID #{id} not found"}
      podcast -> Editor.Manager.delete_podcast(podcast)
    end
  end

  def is_published(%Podcast{published_at: nil}, _, _), do: {:ok, false}
  def is_published(%Episode{published_at: nil}, _, _), do: {:ok, false}

  def is_published(%Podcast{published_at: date}, _, _), do: {:ok, before_utc_now?(date)}
  def is_published(%Episode{published_at: date}, _, _), do: {:ok, before_utc_now?(date)}

  def find_episode(_parent, %{id: id}, _resolution) do
    case Directory.get_episode(id) do
      nil -> {:error, "Episode ID #{id} not found"}
      episode -> {:ok, episode}
    end
  end

  def create_episode(_parent, %{podcast_id: podcast_id, episode: args}, _resolution) do
    case Directory.get_podcast(podcast_id) do
      nil -> {:error, "Podcast ID #{podcast_id} not found"}
      podcast -> Editor.Manager.create_episode(podcast, args)
    end
  end

  def update_episode(_parent, %{id: id, episode: args}, _resolution) do
    case Directory.get_episode(id) do
      nil -> {:error, "Episode ID #{id} not found"}
      episode -> Editor.Manager.update_episode(episode, args)
    end
  end

  def publish_episode(_parent, %{id: id}, _res) do
    case Directory.get_episode(id) do
      nil ->
        {:error, "Episode ID #{id} not found"}

      episode ->
        Editor.Manager.publish_episode(episode)
    end
  end

  def depublish_episode(_parent, %{id: id}, _res) do
    case Directory.get_episode(id) do
      nil ->
        {:error, "Episode ID #{id} not found"}

      episode ->
        Editor.Manager.depublish_episode(episode)
    end
  end

  def delete_episode(_parent, %{id: id}, _resolution) do
    case Directory.get_episode(id) do
      nil -> {:error, "episode ID #{id} not found"}
      episode -> Editor.Manager.delete_episode(episode)
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

  # PERF: use data loader
  def get_enclosure(%Episode{} = episode, _args, _resolution) do
    episode = Radiator.Repo.preload(episode, :enclosure)

    {:ok,
     %{
       url: Episode.enclosure_url(episode),
       type: episode.enclosure.mime_type,
       length: episode.enclosure.byte_length
     }}
  end

  def get_image_url(episode = %Episode{}, _, _) do
    {:ok, Media.EpisodeImage.url({episode.image, episode})}
  end

  def get_image_url(podcast = %Podcast{}, _, _) do
    {:ok, Media.PodcastImage.url({podcast.image, podcast})}
  end

  def get_image_url(network = %Network{}, _, _) do
    {:ok, Media.NetworkImage.url({network.image, network})}
  end

  defp before_utc_now?(date) do
    case DateTime.compare(date, DateTime.utc_now()) do
      :lt -> true
      _ -> false
    end
  end
end
