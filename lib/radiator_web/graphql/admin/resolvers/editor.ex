defmodule RadiatorWeb.GraphQL.Admin.Resolvers.Editor do
  alias Radiator.Directory.Editor
  alias Radiator.Directory.{Episode, Podcast, Network}
  alias Radiator.EpisodeMeta
  alias Radiator.Media

  @not_authorized_match {:error, :not_authorized}
  @not_authorized_response {:error, "Not Authorized"}

  #  TODO: DRY this up with a macro:
  #
  #  case Editor.get_network(user, id) do
  #    network = %Network{} -> ___custom_code_goes_here___
  #    @not_authorized_match -> @not_authorized_response
  #    {:error, _} -> {:error, "Network ID #{id} not found"}
  #  end

  def list_networks(_parent, _args, %{context: %{authenticated_user: user}}) do
    {:ok, Editor.list_networks(user)}
  end

  def find_network(_parent, %{id: id}, %{context: %{authenticated_user: user}}) do
    case Editor.get_network(user, id) do
      network = %Network{} -> {:ok, network}
      @not_authorized_match -> @not_authorized_response
      {:error, _} -> {:error, "Network ID #{id} not found"}
    end
  end

  def create_network(_parent, %{network: args}, %{context: %{authenticated_user: user}}) do
    case Editor.create_network(user, args) do
      {:ok, network} -> {:ok, network}
      @not_authorized_match -> @not_authorized_response
      _ -> {:error, "Could not create network with #{args}"}
    end
  end

  def update_network(_parent, %{id: id, network: args}, %{context: %{authenticated_user: user}}) do
    case Editor.get_network(user, id) do
      @not_authorized_match ->
        @not_authorized_response

      {:error, _} ->
        {:error, "Network ID #{id} not found"}

      network = %Network{} ->
        Editor.update_network(user, network, args)
        |> case do
          @not_authorized_match -> @not_authorized_response
          {:ok, network} -> {:ok, network}
        end
    end
  end

  def list_podcasts(%Network{id: id}, _args, %{context: %{authenticated_user: user}}) do
    case Editor.get_network(user, id) do
      @not_authorized_match ->
        @not_authorized_response

      {:error, _} ->
        {:error, "Network ID #{id} not found"}

      network = %Network{} ->
        {:ok, Editor.list_podcasts(user, network)}
    end
  end

  def list_podcasts(_parent, _args, %{context: %{authenticated_user: user}}) do
    {:ok, Editor.list_podcasts(user)}
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

  def find_episode(_parent, %{id: id}, %{context: %{authenticated_user: user}}) do
    case Editor.get_episode(user, id) do
      nil -> {:error, "Episode ID #{id} not found"}
      {:error, _} -> {:error, "Episode ID #{id} not found"}
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

  def is_published(entity, _, _), do: {:ok, Editor.is_published(entity)}

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

  def get_episodes_count(%Podcast{id: podcast_id}, _, _) do
    episodes_count = Directory.get_episodes_count_for_podcast!(podcast_id)

    {:ok, episodes_count}
  end
end
