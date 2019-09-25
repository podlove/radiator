defmodule RadiatorWeb.GraphQL.Admin.Resolvers.Editor do
  use Radiator.Constants

  alias Radiator.Directory.{
    Editor,
    Episode,
    Podcast,
    Network,
    Audio,
    AudioPublication,
    UserProfile
  }

  alias Radiator.AudioMeta
  alias Radiator.AudioMeta.Chapter
  alias Radiator.Auth.User
  alias Radiator.Media.AudioFile

  import Absinthe.Resolution.Helpers
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
    |> Radiator.Repo.preload(:profile)
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

  def list_collaborators(%Network{id: id}, _args, %{context: %{current_user: user}}) do
    with_network user, id do
      fn network -> Editor.list_collaborators(user, network) end
    end
  end

  @spec list_people(Radiator.Directory.Network.t(), any, %{context: %{current_user: any}}) :: any
  def list_people(%Network{id: id}, _args, %{context: %{current_user: user}}) do
    with_network user, id do
      fn network -> Editor.list_people(user, network) end
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

  def find_episode(_parent, %{id: id}, %{context: %{current_user: user}}) do
    with_episode user, id do
      fn episode -> {:ok, episode} end
    end
  end

  def get_episodes(audio = %Audio{}, _, %{context: %{current_user: user}}) do
    {:ok, Editor.list_episodes(user, audio)}
  end

  # Performance considerations.
  #
  # The performance critical use case is: “In a list of podcasts, list the
  # first X episodes matching the given criteria”. This is hard simply because
  # it’s difficult to construct an SQL query for this. `LIMIT` is global, not per podcast.
  #
  # Options:
  #
  # 1) Use Dataloader, but don’t limit/paginate results in the query but _after_
  #    Dataloader is done. This fetches _all_ (filtered) episodes per podcast but
  #    should be fine except for podcasts with hundreds of episodes.
  #
  # 2) Skip Dataloader and make one paginated SQL query per podcast.
  #    Better for podcasts with many episodes but worse if there are many podcasts.
  #
  # 3) Explore generating custom SQL via advanced postgresql features (lateral joins,
  #    window functions)
  #
  # Current choice: 1
  def get_episodes(podcast = %Podcast{}, args, %{context: %{loader: loader, current_user: _user}}) do
    loader
    |> Dataloader.load(Radiator.Directory, {:episodes, args}, podcast)
    |> on_load(fn loader ->
      items = Dataloader.get(loader, Radiator.Directory, {:episodes, args}, podcast)

      items =
        case {Map.get(args, :items_per_page), Map.get(args, :page)} do
          {items_per_page, page} when items_per_page > 0 and page > 0 ->
            Enum.slice(items, (page - 1) * items_per_page, items_per_page)

          _ ->
            items
        end

      {:ok, items}
    end)
  end

  def get_contributions(podcast = %Podcast{}, _, %{context: %{current_user: user}}) do
    Editor.list_contributions(user, podcast)
  end

  def get_contributions(audio = %Audio{}, _, %{context: %{current_user: user}}) do
    Editor.list_contributions(user, audio)
  end

  def is_published(entity, _, _), do: {:ok, Editor.is_published(entity)}

  def list_chapters(%Audio{} = audio, _args, _resolution) do
    {:ok, AudioMeta.list_chapters(audio)}
  end

  def get_audio_files(audio = %Audio{}, _args, %{context: %{current_user: user}}) do
    Editor.list_audio_files(user, audio)
  end

  def get_audio_files(audio = %Audio{}, _args, _resolution) do
    {:ok, Radiator.Directory.list_audio_files(audio)}
  end

  def find_audio(%AudioPublication{} = audio_publication, _args, %{
        context: %{current_user: _user}
      }) do
    {:ok, audio_publication.audio}
  end

  def find_audio(_parent, %{id: id}, %{context: %{current_user: user}}) do
    with_audio user, id do
      fn audio -> {:ok, audio} end
    end
  end

  def get_duration_string(%Audio{duration: time}, _, _) do
    {:ok, format_normal_playtime(time)}
  end

  def get_duration_string(%Chapter{start: time}, _, _) do
    {:ok, format_normal_playtime(time)}
  end

  def get_file_url(audio_file = %AudioFile{}, _, _) do
    {:ok, AudioFile.public_url(audio_file)}
  end

  @spec get_image_url(Network.t() | Podcast.t() | Episode.t() | Audio.t() | Chapter.t(), any, any) ::
          {:ok, String.t()}
  def get_image_url(subject, _, _)

  def get_image_url(%User{} = user, _, _) do
    user = user |> Radiator.Repo.preload(:profile)

    {:ok, UserProfile.image_url(user.profile)}
  end

  def get_image_url(%type{} = subject, _, _) do
    {:ok, type.image_url(subject)}
  end

  def get_episodes_count(%Podcast{id: podcast_id}, _, %{context: %{current_user: user}}) do
    Editor.get_episodes_count_for_podcast!(user, podcast_id)
  end

  def get_audio_publication(audio = %Audio{audio_publication: audio_publication}, _, _) do
    if Ecto.assoc_loaded?(audio_publication) do
      {:ok, audio_publication}
    else
      {:ok, Ecto.assoc(audio, :audio_publication) |> Radiator.Repo.one()}
    end
  end

  def list_audio_publications(%Network{id: id}, _, %{context: %{current_user: user}}) do
    with_network user, id do
      fn network -> Editor.Manager.list_audio_publications(network) end
    end
  end

  def list_contribution_roles(_, _, _) do
    Editor.list_contribution_roles()
  end
end
