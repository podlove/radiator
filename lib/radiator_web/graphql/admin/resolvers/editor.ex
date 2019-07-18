defmodule RadiatorWeb.GraphQL.Admin.Resolvers.Editor do
  use Radiator.Constants

  alias Radiator.Directory.Editor
  alias Radiator.Directory.{Episode, Podcast, Network, Audio}
  alias Radiator.AudioMeta
  alias Radiator.AudioMeta.Chapter
  alias Radiator.Media
  alias Radiator.Auth.User
  alias Radiator.Contribution.Person
  import RadiatorWeb.FormatHelpers, only: [format_normal_playtime: 1]

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

  @doc """
  Get audio with user and do something with it or return error.

  The `do` block must be a function with `audio` as argument. It is called if the
  audio can be retrieved successfully. Otherwise, an error response, ready for
  GraphQL, is returned and the block not executed.

  ## Examples

      with_audio user, id do
        fn audio -> {:ok, audio}
      end

  """
  defmacro with_audio(user, audio_id, do: block) do
    quote do
      case Editor.get_audio(unquote(user), unquote(audio_id)) do
        {:ok, audio} -> unquote(block).(audio)
        @not_found_match -> @not_found_response
        @not_authorized_match -> @not_authorized_response
      end
    end
  end

  def find_user(_, _, %{context: %{current_user: user}}) do
    user
    |> Radiator.Repo.preload(:person)
    |> (&{:ok, &1}).()
  end

  def find_users(_, %{query: query_string}, _) do
    {:ok, Radiator.Auth.Register.find_users(query_string)}
  end

  def list_networks(_parent, _args, %{context: %{current_user: user}}) do
    {:ok, Editor.list_networks(user)}
  end

  def find_network(_parent, %{id: id}, %{context: %{current_user: user}}) do
    with_network user, id do
      fn network -> {:ok, network} end
    end
  end

  def create_network(_parent, %{network: args}, %{context: %{current_user: user}}) do
    case Editor.create_network(user, args) do
      {:ok, network} -> {:ok, network}
      @not_authorized_match -> @not_authorized_response
      _ -> {:error, "Could not create network with #{args}"}
    end
  end

  def update_network(_parent, %{id: id, network: args}, %{context: %{current_user: user}}) do
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

  def list_collaborators(%Network{id: id}, _args, %{context: %{current_user: user}}) do
    with_network user, id do
      fn network -> Editor.list_collaborators(user, network) end
    end
  end

  def list_podcasts(%Network{id: id}, _args, %{context: %{current_user: user}}) do
    with_network user, id do
      fn network -> {:ok, Editor.list_podcasts(user, network)} end
    end
  end

  def list_podcasts(_parent, _args, %{context: %{current_user: user}}) do
    {:ok, Editor.list_podcasts(user)}
  end

  def find_podcast(%Episode{} = episode, _args, %{context: %{current_user: user}}) do
    with_podcast user, episode.podcast_id do
      fn podcast -> {:ok, podcast} end
    end
  end

  def find_podcast(_parent, %{id: id}, %{context: %{current_user: user}}) do
    with_podcast user, id do
      fn podcast -> {:ok, podcast} end
    end
  end

  def create_podcast(_parent, %{podcast: args, network_id: network_id}, %{
        context: %{current_user: user}
      }) do
    with_network user, network_id do
      fn network ->
        Editor.create_podcast(user, network, args)
      end
    end
  end

  def update_podcast(_parent, %{id: id, podcast: args}, %{context: %{current_user: user}}) do
    with_podcast user, id do
      fn podcast ->
        Editor.update_podcast(user, podcast, args)
      end
    end
  end

  def publish_podcast(_parent, %{id: id}, %{context: %{current_user: user}}) do
    with_podcast user, id do
      fn podcast ->
        Editor.publish_podcast(user, podcast)
      end
    end
  end

  def depublish_podcast(_parent, %{id: id}, %{context: %{current_user: user}}) do
    with_podcast user, id do
      fn podcast ->
        Editor.depublish_podcast(user, podcast)
      end
    end
  end

  def delete_podcast(_parent, %{id: id}, %{context: %{current_user: user}}) do
    with_podcast user, id do
      fn podcast ->
        Editor.delete_podcast(user, podcast)
      end
    end
  end

  def find_episode(_parent, %{id: id}, %{context: %{current_user: user}}) do
    with_episode user, id do
      fn episode -> {:ok, episode} end
    end
  end

  def get_episodes(audio = %Audio{}, _, %{context: %{current_user: user}}) do
    {:ok, Editor.list_episodes(user, audio)}
  end

  def create_episode(_parent, %{podcast_id: podcast_id, episode: args}, %{
        context: %{current_user: user}
      }) do
    with_podcast user, podcast_id do
      fn podcast ->
        Editor.create_episode(user, podcast, args)
      end
    end
  end

  def update_episode(_parent, %{id: id, episode: args}, %{context: %{current_user: user}}) do
    with_episode user, id do
      fn episode ->
        Editor.update_episode(user, episode, args)
      end
    end
  end

  def publish_episode(_parent, %{id: id}, %{context: %{current_user: user}}) do
    with_episode user, id do
      fn episode ->
        Editor.publish_episode(user, episode)
      end
    end
  end

  def depublish_episode(_parent, %{id: id}, %{context: %{current_user: user}}) do
    with_episode user, id do
      fn episode ->
        Editor.depublish_episode(user, episode)
      end
    end
  end

  def schedule_episode(_parent, %{id: id, datetime: datetime}, %{
        context: %{current_user: user}
      }) do
    with_episode user, id do
      fn episode ->
        Editor.schedule_episode(user, episode, datetime)
      end
    end
  end

  # todo: do not use Manager context here
  def delete_episode(_parent, %{id: id}, %{context: %{current_user: user}}) do
    with_episode user, id do
      fn episode ->
        Editor.delete_episode(user, episode)
      end
    end
  end

  def is_published(entity, _, _), do: {:ok, Editor.is_published(entity)}

  def list_chapters(%Audio{} = audio, _args, _resolution) do
    {:ok, AudioMeta.list_chapters(audio)}
  end

  def get_audio_files(audio = %Audio{}, _args, %{context: %{current_user: user}}) do
    {:ok, Editor.list_audio_files(user, audio)}
  end

  def get_audio_files(audio = %Audio{}, _args, _resolution) do
    {:ok, Radiator.Directory.list_audio_files(audio)}
  end

  def list_audios(%Network{} = network, _args, %{context: %{current_user: actor}}) do
    Editor.list_audios(actor, network)
  end

  def find_audio(%Episode{} = episode, _args, %{context: %{current_user: _user}}) do
    {:ok, episode.audio}
  end

  def find_audio(_parent, %{id: id}, %{context: %{current_user: user}}) do
    with_audio user, id do
      fn audio -> {:ok, audio} end
    end
  end

  def get_chapters(%Audio{} = audio, _, _) do
    chapter_query = Radiator.AudioMeta.Chapter.ordered_query()
    audio = Radiator.Repo.preload(audio, chapters: chapter_query)

    {:ok, audio.chapters}
  end

  def get_duration_string(%Audio{duration: time}, _, _) do
    {:ok, format_normal_playtime(time)}
  end

  def get_duration_string(%Chapter{start: time}, _, _) do
    {:ok, format_normal_playtime(time)}
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

  def get_image_url(%User{} = user, _, _) do
    user = user |> Radiator.Repo.preload(:person)

    {:ok, Person.image_url(user.person)}
  end

  def get_episodes_count(%Podcast{id: podcast_id}, _, %{context: %{current_user: user}}) do
    Editor.get_episodes_count_for_podcast!(user, podcast_id)
  end
end
