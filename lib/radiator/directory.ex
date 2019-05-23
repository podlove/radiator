defmodule Radiator.Directory do
  @moduledoc """
  The Directory context supplying published information.

  All data provided by this context is safe to display publicly.
  """

  import Ecto.Query, warn: false

  alias __MODULE__
  alias Radiator.Repo
  alias Radiator.Media
  alias Radiator.Media.AudioFile
  alias Directory.{Network, Episode, Podcast}
  alias Radiator.Directory.PodcastQuery

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

  @doc """
  Get the first network.

  Only temporary until users can be assigned to networks.
  Once this is possible, remove this function.
  """
  def get_any_network do
    from(n in Network, limit: 1) |> Repo.one!()
  end

  def list_podcasts(%Network{id: id}) do
    from(p in Podcast, where: p.network_id == ^id)
    |> Repo.all()
  end

  def list_podcasts do
    Podcast
    |> PodcastQuery.filter_by_published()
    |> Repo.all()
  end

  def list_podcasts_with_episode_counts(%Network{id: id}) do
    from(p in Podcast, where: p.network_id == ^id)
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
    Radiator.Directory.EpisodeQuery.build(args)
  end

  def list_episodes do
    list_episodes(%{})
  end

  def list_episodes(args) do
    episodes_query(args)
    |> Repo.all()
  end

  @doc """
  Gets a single episode.

  Raises `Ecto.NoResultsError` if the Episode does not exist.

  ## Examples

      iex> get_episode!(123)
      %Episode{}

      iex> get_episode!(456)
      ** (Ecto.NoResultsError)

  """
  def get_episode!(id), do: Repo.get!(Episode, id) |> Repo.preload(:podcast)
  def get_episode(id), do: Repo.get(Episode, id) |> Repo.preload(:podcast)

  @doc """
  Gets a single episode by its slug.

  ## Examples

      iex> get_episode_by_slug(slug)
      {:ok, %Episode{}}
  """
  def get_episode_by_slug(slug), do: Repo.get_by(Episode, %{slug: slug}) |> Repo.preload(:podcast)

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
