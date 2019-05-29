defmodule Radiator.Directory do
  @moduledoc """
  The Directory context supplying published information.

  All data provided by this context is safe to display publicly.
  """

  import Ecto.Query, warn: false

  alias Radiator.Repo
  alias Radiator.Media
  alias Radiator.Media.AudioFile
  alias Radiator.Directory.{Network, Episode, Podcast}
  alias Radiator.Directory.PodcastQuery
  alias Radiator.Directory.EpisodeQuery

  def data() do
    Dataloader.Ecto.new(Repo, query: &query/2)
  end

  def query(Episode, args) do
    episodes_query(args)
  end

  def query(queryable, _) do
    queryable
  end

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
  Gets a single podcast.

  Raises `Ecto.NoResultsError` if the Podcast does not exist.

  ## Examples

      iex> get_podcast!(123)
      %Podcast{}

      iex> get_podcast!(456)
      ** (Ecto.NoResultsError)

  """
  def get_podcast!(id) do
    Podcast
    |> PodcastQuery.filter_by_published()
    |> Repo.get!(id)
  end

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
      {:ok, %Podcast{}}
  """
  def get_podcast_by_slug(slug), do: Repo.get_by(Podcast, %{slug: slug})

  defp episodes_query(args) when is_map(args) do
    args
    |> Map.put(:published, true)
    |> EpisodeQuery.build()
  end

  def list_episodes do
    list_episodes(%{})
  end

  def list_episodes(args) do
    episodes_query(args)
    |> Repo.all()
    |> preload_for_episode()
  end

  @doc """
  Gets a single published episode.

  Raises `Ecto.NoResultsError` if the Episode does not exist.

  ## Examples

      iex> get_episode!(123)
      %Episode{}

      iex> get_episode!(456)
      ** (Ecto.NoResultsError)

  """
  def get_episode!(id) do
    Episode
    |> EpisodeQuery.filter_by_published(true)
    |> Repo.get!(id)
    |> preload_for_episode()
  end

  def get_episode(id) do
    Episode
    |> EpisodeQuery.filter_by_published(true)
    |> Repo.get(id)
    |> preload_for_episode()
  end

  def preload_for_episode(episode) do
    Repo.preload(episode, [:podcast, audio: [:audio_files]])
  end

  @doc """
  Gets a single episode by its slug.

  ## Examples

      iex> get_episode_by_slug(slug)
      {:ok, %Episode{}}
  """
  def get_episode_by_slug(slug),
    do: Repo.get_by(Episode, %{slug: slug}) |> preload_for_episode()

  def is_published(%Podcast{published_at: nil}), do: false
  def is_published(%Episode{published_at: nil}), do: false

  def is_published(%Podcast{published_at: date}), do: before_utc_now?(date)
  def is_published(%Episode{published_at: date}), do: before_utc_now?(date)

  # todo: missing verification that podcast (& network?) is published
  def get_audio_file(id) do
    with {:get, audio = %AudioFile{}} <-
           {:get, Media.get_audio_file(id) |> Repo.preload(:episode)},
         {:published, published} when published <- {:published, is_published(audio.episode)} do
      {:ok, audio}
    else
      {:get, _} -> {:error, :not_found}
      {:published, _} -> {:error, :unpublished}
    end
  end

  defp before_utc_now?(date) do
    case DateTime.compare(date, DateTime.utc_now()) do
      :lt -> true
      _ -> false
    end
  end
end
