defmodule Radiator.Directory do
  @moduledoc """
  The Directory context supplying published information.

  All data provided by this context is safe to display publicly.
  """

  import Ecto.Query, warn: false

  alias Radiator.Support
  alias Radiator.Repo
  alias Radiator.Media.AudioFile
  alias Radiator.Directory.{Network, Episode, Podcast, Audio, AudioPublication}
  alias Radiator.Directory.{PodcastQuery, EpisodeQuery, AudioQuery}
  alias Radiator.Contribution.{PodcastContribution, AudioContribution}

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

  defp published_networks_query do
    published_podcasts_query = PodcastQuery.filter_by_published(Podcast)

    network_query =
      from(p in published_podcasts_query, join: n in assoc(p, :network), distinct: n, select: n)

    from(n in subquery(network_query), order_by: [desc: n.title])
  end

  # TODO: have a clearer concept of published for networks (currently just defers to the podcast)
  def list_networks do
    published_networks_query()
    |> Repo.all()
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
  def get_network!(id) do
    query = published_networks_query()

    from(n in query, where: n.id == ^id)
    |> Repo.one!()
  end

  def get_network(id) do
    query = published_networks_query()

    from(n in query, where: n.id == ^id)
    |> Repo.one()
  end

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
    |> preload_for_podcast()
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
    |> preload_for_podcast()
  end

  def get_audio_publication(id) do
    AudioPublication
    |> where(id: ^id, publish_state: "published")
    |> preload([:network, audio: [:audio_files, :chapters]])
    |> Repo.one()
  end

  def get_audio_publication_by_slug(slug) do
    AudioPublication
    |> where(slug: ^slug, publish_state: "published")
    |> preload(:network)
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

  def get_podcast_contributions(podcast = %Podcast{}) do
    podcast
    |> Ecto.assoc(:contributions)
    |> order_by(asc: :position)
    |> Repo.all()
    |> Repo.preload([:person, :role])
  end

  def get_audio_contributions(audio = %Audio{}) do
    audio
    |> Ecto.assoc(:contributions)
    |> order_by(asc: :position)
    |> Repo.all()
    |> Repo.preload([:person, :role])
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

  def preload_for_podcast(nil) do
    nil
  end

  def preload_for_podcast(%Podcast{} = podcast) do
    contributions_query =
      PodcastContribution
      |> order_by(asc: :position)

    Repo.preload(podcast, [:network, contributions: {contributions_query, [:person, :role]}])
  end

  # fixme: this is currently identical to `Editor.preloaded_episode/1`,
  #        however: in Directory context preloading is dangerous as it might
  #        provide access to entities without checking for permissions.
  #        Solution: write preloader that checks permissions.
  def preload_for_episode(episode) do
    contributions_query =
      AudioContribution
      |> order_by(asc: :position)

    Repo.preload(episode, [
      :podcast,
      audio: [
        :chapters,
        :audio_files,
        :contributors,
        contributions: {contributions_query, [:person, :role]}
      ]
    ])
  end

  def preload_for_audio(audio) do
    chapter_query = Radiator.AudioMeta.Chapter.ordered_query()
    Repo.preload(audio, chapters: chapter_query, audio_files: [])
  end

  def preload_episodes(podcast = %Podcast{}) do
    %{
      podcast
      | episodes: list_episodes(%{podcast: podcast, order_by: :published_at, order: :desc})
    }
  end

  def is_published(%Podcast{published_at: nil}), do: false
  def is_published(%Episode{published_at: nil}), do: false

  def is_published(%Podcast{published_at: date}),
    do: Support.DateTime.before_utc_now?(date)

  def is_published(%Episode{published_at: date}),
    do: Support.DateTime.before_utc_now?(date)

  # fixme: implementation missing for AudioPublication
  def is_published(_), do: true

  def get_audio(id) do
    Audio
    |> AudioQuery.filter_by_published(true)
    |> Repo.get(id)
    |> preload_for_audio()
  end

  # todo: missing verification that podcast (& network?) is published
  def get_audio_file(audio_file_id) do
    with {:get, audio_file = %AudioFile{}} <-
           {:get,
            Repo.get(AudioFile, audio_file_id)
            |> Repo.preload(audio: :episodes)},
         {:published, published} when published <-
           {:published, is_published(hd(audio_file.audio.episodes))} do
      {:ok, audio_file}
    else
      {:get, _} -> {:error, :not_found}
      {:published, _} -> {:error, :unpublished}
    end
  end

  @spec list_audio_files(Audio.t()) :: [AudioFile.t()]
  def list_audio_files(audio = %Audio{}) do
    if is_published(audio) do
      audio
      |> Ecto.assoc(:audio_files)
      |> Repo.all()
    else
      []
    end
  end
end
