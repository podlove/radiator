defmodule Radiator.Directory do
  @moduledoc """
  The Directory context supplying published information.

  All data provided by this context is safe to display publicly.
  """

  import Ecto.Query, warn: false

  alias Radiator.Support
  alias Radiator.Repo
  alias Radiator.Media
  alias Radiator.Media.AudioFile
  alias Radiator.Directory.{Network, Episode, Podcast, Audio}
  alias Radiator.Directory.{PodcastQuery, EpisodeQuery, AudioQuery}

  def data() do
    Dataloader.Ecto.new(Repo, query: &query/2)
  end

  def query(Episode, args) do
    chapter_query = Radiator.AudioMeta.Chapter.ordered_query()

    episodes_query(args)
    |> preload([:podcast, audio: [chapters: ^chapter_query, audio_files: []]])
  end

  def query(queryable, _) do
    queryable
  end

  # TODO: add a notion of published to networks as well and only show those
  def list_networks do
    Repo.all(Network)
  end

  @doc """
  Gets a single network.

  Raises `Ecto.NoResultsError` if the Network does not exist.

  ## Examples

      iex> get_network!(123)
      %Network{}

      iex> get_network!(456)
      ** (Ecto.NoResultsError)

  """
  def get_network!(id), do: Repo.get!(Network, id)

  def get_network(id), do: Repo.get(Network, id)

  @doc """
  Gets a single network by its slug.

  ## Examples

      iex> get_network_by_slug(slug)
      %Network{}
  """
  def get_network_by_slug(slug), do: Repo.get_by(Network, %{slug: slug})

  def list_podcasts(%Network{id: id}) do
    from(p in Podcast, where: p.network_id == ^id)
    |> PodcastQuery.filter_by_published()
    |> Repo.all()
  end

  def list_podcasts do
    Podcast
    |> PodcastQuery.filter_by_published()
    |> Repo.all()
  end

  def list_podcasts_with_episode_counts(%Network{id: id}) do
    from(p in Podcast, where: p.network_id == ^id)
    |> PodcastQuery.filter_by_published()
    |> Podcast.preload_episode_counts()
    |> Repo.all()
  end

  @doc """
  Gets a single podcast. `nil` if not found.

  ## Examples

      iex> get_podcast!(123)
      %Podcast{}

  """

  def get_podcast(id) do
    Podcast
    |> PodcastQuery.filter_by_published()
    |> Repo.get(id)
  end

  @doc """
  Gets the number of episodes of the podcast with the given id.

  ## Examples

      iex> get_episodes_count_for_podcast!(123)
      3
  """
  def get_episodes_count_for_podcast!(id) do
    from(e in Episode, where: e.podcast_id == ^id)
    |> EpisodeQuery.filter_by_published(true)
    |> Repo.aggregate(:count, :id)
  end

  @doc """
  Gets a single podcast by its slug.

  ## Examples

      iex> get_podcast_by_slug(slug)
      %Podcast{}
  """
  def get_podcast_by_slug(slug) do
    Podcast
    |> PodcastQuery.filter_by_published(true)
    |> PodcastQuery.find_by_slug(slug)
    |> Repo.one()
  end

  @doc """
  Gets a single episode by its slug.

  ## Examples

      iex> get_episode_by_slug(podcast, slug)
      %Episode{}
  """
  def get_episode_by_slug(podcast_id, slug) when is_integer(podcast_id) do
    episodes_query(%{podcast: podcast_id, slug: slug})
    |> Repo.one()
    |> preload_for_episode()
  end

  def get_episode_by_slug(%Podcast{} = podcast, slug) do
    get_episode_by_slug(podcast.id, slug)
  end

  def get_episode_by_short_id(short_id) do
    episodes_query(%{short_id: short_id})
    |> Repo.one()
    |> preload_for_episode()
  end

  defp episodes_query(args) when is_map(args) do
    args
    |> Map.put(:published, true)
    |> EpisodeQuery.build()
  end

  @doc """
  List public episodes.
  """
  def list_episodes do
    list_episodes(%{})
  end

  @doc """
  List public episodes.

  See `Radiator.Directory.EpisodeQuery` for options.
  """
  def list_episodes(args) do
    episodes_query(args)
    |> Repo.all()
    |> preload_for_episode()
  end

  @doc """
  Reject episodes without audio or audio files.
  """
  def reject_invalid_episodes(episodes) when is_list(episodes) do
    Enum.filter(episodes, fn
      %Episode{audio: %Audio{audio_files: [_ | _]}} -> true
      _ -> false
    end)
  end

  @doc """
  Gets a single published episode.

  ## Examples

      iex> get_episode(123)
      %Episode{}

  """

  def get_episode(id) do
    Episode
    |> EpisodeQuery.filter_by_published(true)
    |> Repo.get(id)
    |> preload_for_episode()
  end

  # fixme: this is currently identical to `Editor.preloaded_episode/1`,
  #        however: in Directory context preloading is dangerous as it might
  #        provide access to entities without checking for permissions.
  #        Solution: write preloader that checks permissions.
  def preload_for_episode(episode) do
    chapter_query = Radiator.AudioMeta.Chapter.ordered_query()
    Repo.preload(episode, [:podcast, audio: [chapters: chapter_query, audio_files: []]])
  end

  def preload_for_audio(audio) do
    chapter_query = Radiator.AudioMeta.Chapter.ordered_query()
    Repo.preload(audio, chapters: chapter_query, audio_files: [])
  end

  def preload_episodes(podcast = %Podcast{}) do
    %{podcast | episodes: list_episodes(%{podcast: podcast, order_by: :number, order: :desc})}
  end

  def is_published(%Podcast{published_at: nil}), do: false
  def is_published(%Episode{published_at: nil}), do: false

  def is_published(%Podcast{published_at: date}),
    do: Support.DateTime.before_utc_now?(date)

  def is_published(%Episode{published_at: date}),
    do: Support.DateTime.before_utc_now?(date)

  def is_published(_), do: false

  def get_audio(id) do
    Audio
    |> AudioQuery.filter_by_published(true)
    |> Repo.get(id)
    |> preload_for_audio()
  end

  # todo: missing verification that podcast (& network?) is published
  def get_audio_file(audio_file_id) do
    with {:get, audio = %AudioFile{}} <-
           {:get,
            Media.get_audio_file(audio_file_id)
            |> Repo.preload(audio: :episodes)},
         {:published, published} when published <-
           {:published, is_published(hd(audio.audio.episodes))} do
      {:ok, audio}
    else
      {:get, _} -> {:error, :not_found}
      {:published, _} -> {:error, :unpublished}
    end
  end
end
