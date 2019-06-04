defmodule RadiatorWeb.GraphQL.Admin.Resolvers.Editor do
  use Radiator.Constants

  alias Radiator.Directory.Editor
  alias Radiator.Directory.{Episode, Podcast, Network}
  alias Radiator.EpisodeMeta
  alias Radiator.Media

  @doc """
  Get network with user and do something with it or return error.

  The `do` block must be a function with `network` as argument. It is called if the
  network can be retrieved successfully. Otherwise, an error response, ready for
  GraphQL, is returned and the block not executed.

  ## Examples

      with_network user, id do
        fn network -> {:ok, network}
      end

  """
  defmacro with_network(user, network_id, do: block) do
    quote do
      case Editor.get_network(unquote(user), unquote(network_id)) do
        {:ok, network} -> unquote(block).(network)
        @not_found_match -> @not_found_response
        @not_authorized_match -> @not_authorized_response
      end
    end
  end

  @doc """
  Get podcast with user and do something with it or return error.

  The `do` block must be a function with `podcast` as argument. It is called if the
  podcast can be retrieved successfully. Otherwise, an error response, ready for
  GraphQL, is returned and the block not executed.

  ## Examples

      with_podcast Ruser, id do
        fn podcast -> {:ok, podcast}
      end

  """
  defmacro with_podcast(user, podcast_id, do: block) do
    quote do
      case Editor.get_podcast(unquote(user), unquote(podcast_id)) do
        {:ok, podcast} -> unquote(block).(podcast)
        @not_found_match -> @not_found_response
        @not_authorized_match -> @not_authorized_response
      end
    end
  end

  @doc """
  Get episode with user and do something with it or return error.

  The `do` block must be a function with `episode` as argument. It is called if the
  episode can be retrieved successfully. Otherwise, an error response, ready for
  GraphQL, is returned and the block not executed.

  ## Examples

      with_episode user, id do
        fn episode -> {:ok, episode}
      end

  """
  defmacro with_episode(user, episode_id, do: block) do
    quote do
      case Editor.get_episode(unquote(user), unquote(episode_id)) do
        {:ok, episode} -> unquote(block).(episode)
        @not_found_match -> @not_found_response
        @not_authorized_match -> @not_authorized_response
      end
    end
  end

  def list_networks(_parent, _args, %{context: %{authenticated_user: user}}) do
    {:ok, Editor.list_networks(user)}
  end

  def find_network(_parent, %{id: id}, %{context: %{authenticated_user: user}}) do
    with_network user, id do
      fn network -> {:ok, network} end
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
    with_network user, id do
      fn network ->
        Editor.update_network(user, network, args)
        |> case do
          @not_authorized_match -> @not_authorized_response
          {:error, changeset = %Ecto.Changeset{}} -> {:error, changeset}
          {:ok, network} -> {:ok, network}
        end
      end
    end
  end

  def list_podcasts(%Network{id: id}, _args, %{context: %{authenticated_user: user}}) do
    with_network user, id do
      fn network -> {:ok, Editor.list_podcasts(user, network)} end
    end
  end

  def list_podcasts(_parent, _args, %{context: %{authenticated_user: user}}) do
    {:ok, Editor.list_podcasts(user)}
  end

  def find_podcast(%Episode{} = episode, _args, %{context: %{authenticated_user: user}}) do
    with_podcast user, episode.podcast_id do
      fn podcast -> {:ok, podcast} end
    end
  end

  def find_podcast(_parent, %{id: id}, %{context: %{authenticated_user: user}}) do
    with_podcast user, id do
      fn podcast -> {:ok, podcast} end
    end
  end

  def create_podcast(_parent, %{podcast: args, network_id: network_id}, %{
        context: %{authenticated_user: user}
      }) do
    with_network user, network_id do
      fn network ->
        Editor.create_podcast(user, network, args)
      end
    end
  end

  def update_podcast(_parent, %{id: id, podcast: args}, %{context: %{authenticated_user: user}}) do
    with_podcast user, id do
      fn podcast ->
        Editor.update_podcast(user, podcast, args)
      end
    end
  end

  def publish_podcast(_parent, %{id: id}, %{context: %{authenticated_user: user}}) do
    with_podcast user, id do
      fn podcast ->
        Editor.publish_podcast(user, podcast)
      end
    end
  end

  def depublish_podcast(_parent, %{id: id}, %{context: %{authenticated_user: user}}) do
    with_podcast user, id do
      fn podcast ->
        Editor.depublish_podcast(user, podcast)
      end
    end
  end

  def delete_podcast(_parent, %{id: id}, %{context: %{authenticated_user: user}}) do
    with_podcast user, id do
      fn podcast ->
        Editor.delete_podcast(user, podcast)
      end
    end
  end

  def find_episode(_parent, %{id: id}, %{context: %{authenticated_user: user}}) do
    with_episode user, id do
      fn episode -> {:ok, episode} end
    end
  end

  def create_episode(_parent, %{podcast_id: podcast_id, episode: args}, %{
        context: %{authenticated_user: user}
      }) do
    with_podcast user, podcast_id do
      fn podcast ->
        Editor.create_episode(user, podcast, args)
      end
    end
  end

  def update_episode(_parent, %{id: id, episode: args}, %{context: %{authenticated_user: user}}) do
    with_episode user, id do
      fn episode ->
        Editor.update_episode(user, episode, args)
      end
    end
  end

  def publish_episode(_parent, %{id: id}, %{context: %{authenticated_user: user}}) do
    with_episode user, id do
      fn episode ->
        Editor.publish_episode(user, episode)
      end
    end
  end

  def depublish_episode(_parent, %{id: id}, %{context: %{authenticated_user: user}}) do
    with_episode user, id do
      fn episode ->
        Editor.depublish_episode(user, episode)
      end
    end
  end

  # todo: do not use Manager context here
  def delete_episode(_parent, %{id: id}, %{context: %{authenticated_user: user}}) do
    with_episode user, id do
      fn episode ->
        Editor.delete_episode(user, episode)
      end
    end
  end

  def is_published(entity, _, _), do: {:ok, Editor.is_published(entity)}

  def list_chapters(%Episode{} = episode, _args, _resolution) do
    {:ok, EpisodeMeta.list_chapters(episode)}
  end

  def set_episode_chapters(_parent, %{id: id, chapters: chapters, type: type}, %{
        context: %{authenticated_user: user}
      }) do
    with_episode user, id do
      fn episode ->
        EpisodeMeta.set_chapters(episode, chapters, String.to_existing_atom(type))
      end
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

  def get_chapters(%Episode{audio: audio}, _, _) do
    audio = Radiator.Repo.preload(audio, :chapters)

    {:ok, audio.chapters}
  end

  def get_duration(%Episode{audio: audio}, _, _) do
    {:ok, audio.duration}
  end

  def get_image_url(episode = %Episode{}, _, _) do
    {:ok, Media.EpisodeImage.url({episode.image, episode})}
  end

  def get_image_url(podcast = %Podcast{}, _, _) do
    {:ok, Podcast.image_url(podcast)}
  end

  def get_image_url(network = %Network{}, _, _) do
    {:ok, Media.NetworkImage.url({network.image, network})}
  end

  def get_episodes_count(%Podcast{id: podcast_id}, _, %{context: %{authenticated_user: user}}) do
    Editor.get_episodes_count_for_podcast!(user, podcast_id)
  end
end
