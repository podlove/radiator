defmodule Radiator.Directory do
  @moduledoc """
  The Directory context supplying published information.
  """

  import Ecto.Query, warn: false

  alias __MODULE__
  alias Radiator.Repo
  alias Directory.{Network, Episode, Podcast}

  def data() do
    Dataloader.Ecto.new(Repo, query: &query/2)
  end

  def query(Episode, args) do
    episodes_query(args)
  end

  def query(queryable, _) do
    queryable
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
end
