defmodule Radiator.Directory do
  @moduledoc """
  The Directory context.
  """

  import Ecto.Query, warn: false

  alias Radiator.Directory.Episode
  alias Radiator.Directory.Podcast
  alias Radiator.Directory.Network
  alias Radiator.Repo

  def data() do
    Dataloader.Ecto.new(Repo, query: &query/2)
  end

  def query(Episode, args) do
    episodes_query(args)
  end

  def query(queryable, _) do
    queryable
  end

  def list_podcasts(%Network{id: id}) do
    from(p in Podcast, where: p.network_id == ^id)
    |> Repo.all()
  end

  def list_podcasts do
    Repo.all(Podcast)
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
  def get_podcast!(id), do: Repo.get!(Podcast, id)
  def get_podcast(id), do: Repo.get(Podcast, id)

  @doc """
  Creates a podcast.

  ## Examples

      iex> create_podcast(network, %{field: value})
      {:ok, %Podcast{}}

      iex> create_podcast(network, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_podcast(%Network{} = network, attrs \\ %{}) do
    %Podcast{}
    |> Podcast.changeset(attrs)
    |> Ecto.Changeset.put_assoc(:network, network)
    |> Repo.insert()
  end

  @doc """
  Updates a podcast.

  ## Examples

      iex> update_podcast(podcast, %{field: new_value})
      {:ok, %Podcast{}}

      iex> update_podcast(podcast, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_podcast(%Podcast{} = podcast, attrs) do
    podcast
    |> Podcast.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a Podcast.

  ## Examples

      iex> delete_podcast(podcast)
      {:ok, %Podcast{}}

      iex> delete_podcast(podcast)
      {:error, %Ecto.Changeset{}}

  """
  def delete_podcast(%Podcast{} = podcast) do
    Repo.delete(podcast)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking podcast changes.

  ## Examples

      iex> change_podcast(podcast)
      %Ecto.Changeset{source: %Podcast{}}

  """
  def change_podcast(%Podcast{} = podcast) do
    Podcast.changeset(podcast, %{})
  end

  @doc """
  Publishes a single podcast by giving it a `published_at` date.

  ## Examples

      iex> publish_podcast(podcast_id)
      {:ok, podcast}

      iex> publish_podcast(non_existing_id)
      {:error, :not_found}

      iex> publish_podcast(id)
      {:error, %Ecto.Changeset{}}
  """
  def publish_podcast(id) do
    case get_podcast(id) do
      nil ->
        {:error, :not_found}

      %Podcast{slug: nil} = podcast ->
        slug = Slugger.slugify_downcase(podcast.title)

        attrs = %{
          published_at: DateTime.utc_now(),
          slug: slug
        }

        case update_podcast(podcast, attrs) do
          {:ok, podcast} ->
            {:ok, podcast}

          {:error, %Ecto.Changeset{errors: [slug: {"has already been taken", _}]}} ->
            {:error, "Slug #{slug} has already been taken"}

          {:error, error} ->
            {:error, error}
        end

      podcast ->
        update_podcast(podcast, %{
          published_at: DateTime.utc_now()
        })
    end
  end

  @doc """
  Depublishes a single podcast by removing it's `published_at` date.

  ## Examples

      iex> depublish_podcast(podcast_id)
      {:ok, podcast}

      iex> depublish_podcast(non_existing_id)
      {:error, :not_found}

      iex> depublish_podcast(id)
      {:error, %Ecto.Changeset{}}
  """
  def depublish_podcast(id) do
    case get_podcast(id) do
      nil ->
        {:error, :not_found}

      %Podcast{} = podcast ->
        update_podcast(podcast, %{published_at: nil})
    end
  end

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
  Creates a episode.

  ## Examples

      iex> create_episode(%Podcast{}, %{field: value})
      {:ok, %Episode{}}

      iex> create_episode(%Podcast{}, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_episode(%Podcast{} = podcast, attrs \\ %{}) do
    %Episode{}
    |> Episode.changeset(attrs)
    |> Ecto.Changeset.put_assoc(:podcast, podcast)
    |> Repo.insert()
  end

  @doc """
  Updates a episode.

  ## Examples

      iex> update_episode(episode, %{field: new_value})
      {:ok, %Episode{}}

      iex> update_episode(episode, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_episode(%Episode{} = episode, attrs) do
    episode
    |> Episode.changeset(attrs)
    |> Repo.update()
  end

  def regenerate_episode_guid(episode) do
    episode
    |> change_episode()
    |> Episode.regenerate_guid()
    |> Repo.update()
  end

  @doc """
  Deletes a Episode.

  ## Examples

      iex> delete_episode(episode)
      {:ok, %Episode{}}

      iex> delete_episode(episode)
      {:error, %Ecto.Changeset{}}

  """
  def delete_episode(%Episode{} = episode) do
    Repo.delete(episode)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking episode changes.

  ## Examples

      iex> change_episode(episode)
      %Ecto.Changeset{source: %Episode{}}

  """
  def change_episode(%Episode{} = episode) do
    Episode.changeset(episode, %{})
  end

  @doc """
  Returns the list of networks.

  ## Examples

      iex> list_networks()
      [%Network{}, ...]

  """
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
  Get the first network.

  Only temporary until users can be assigned to networks.
  Once this is possible, remove this function.
  """
  def get_any_network do
    from(n in Network, limit: 1) |> Repo.one!()
  end

  @doc """
  Creates a network.

  ## Examples

      iex> create_network(%{field: value})
      {:ok, %Network{}}

      iex> create_network(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_network(attrs \\ %{}) do
    %Network{}
    |> Network.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a network.

  ## Examples

      iex> update_network(network, %{field: new_value})
      {:ok, %Network{}}

      iex> update_network(network, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_network(%Network{} = network, attrs) do
    network
    |> Network.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a Network.

  ## Examples

      iex> delete_network(network)
      {:ok, %Network{}}

      iex> delete_network(network)
      {:error, %Ecto.Changeset{}}

  """
  def delete_network(%Network{} = network) do
    Repo.delete(network)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking network changes.

  ## Examples

      iex> change_network(network)
      %Ecto.Changeset{source: %Network{}}

  """
  def change_network(%Network{} = network) do
    Network.changeset(network, %{})
  end
end
