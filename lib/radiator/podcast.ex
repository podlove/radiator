defmodule Radiator.Podcast do
  @moduledoc """
  The Podcasts context.
  Handles repo operations for networks, shows and episodes.
  """

  import Ecto.Query, warn: false
  alias Radiator.Repo

  alias Radiator.Outline.NodeRepository
  alias Radiator.Podcast.{Episode, Network, Show, ShowHosts}

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
  Returns the list of networks with preloaded associations.

  ## Examples

      iex> list_networks(preload: :shows)
      [%Network{}, ...]

  """

  def list_networks(preload: preload) do
    Network
    |> Repo.all()
    |> Repo.preload(preload)
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
  Deletes a network.

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
      %Ecto.Changeset{data: %Network{}}

  """
  def change_network(%Network{} = network, attrs \\ %{}) do
    Network.changeset(network, attrs)
  end

  @doc """
  Returns the list of shows.

  ## Examples

      iex> list_shows()
      [%Show{}, ...]

  """
  def list_shows do
    Repo.all(Show)
  end

  @doc """
  Gets a single show.

  Raises `Ecto.NoResultsError` if the Show does not exist.

  ## Examples

      iex> get_show!(123)
      %Show{}

      iex> get_show!(456)
      ** (Ecto.NoResultsError)

  """
  def get_show!(id), do: Repo.get!(Show, id)

  @doc """
  Gets a single show with preloaded associations.

  Raises `Ecto.NoResultsError` if the Show does not exist.

  ## Examples

      iex> get_show!(123, preload: :episodes)
      %Show{}

      iex> get_show!(456, preload: :episodes)
      ** (Ecto.NoResultsError)

  """

  def get_show!(id, preload: preload) do
    Show
    |> Repo.get!(id)
    |> Repo.preload(preload)
  end

  @doc """
  Creates a show.

  ## Examples

      iex> create_show(%{field: value})
      {:ok, %Show{}}

      iex> create_show(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_show(attrs \\ %{}) do
    # also need to create the nodes for the show
    # start a transaction =
    Repo.transaction(fn ->
      {:ok, show} =
        %Show{}
        |> Show.changeset(attrs)
        |> Repo.insert()

      {_show_root, _global_inbox} = NodeRepository.create_virtual_nodes_for_show(show.id)
      show
    end)
  end

  @doc """
  Creates a show with hosts.

  ## Examples

      iex> create_show(%{field: value}, [%User{}])
      {:ok, %Show{}}

      iex> create_show(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_show(attrs, hosts) do
    Repo.transaction(fn ->
      case create_show(attrs) do
        {:ok, show} ->
          associate_hosts(show, hosts)
          show

        {:error, changeset} ->
          Repo.rollback(changeset)
      end
    end)
  end

  # Fills the list of associate hosts of a show by adding users to hosts list.
  # Suggested to run inside a transaction.
  defp associate_hosts(show, hosts) do
    Enum.each(hosts, fn host ->
      create_showhosts!(%{show_id: show.id, user_id: host.id})
    end)
  end

  @doc """
  Updates a show with hosts.

  ## Examples

      iex> update_show(show, %{field: new_value}, [%User{}])
      {:ok, %Show{}}

      iex> update_show(show, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_show(%Show{} = show, attrs, hosts) do
    Repo.transaction(fn ->
      case update_show(show, attrs) do
        {:ok, show} ->
          update_associate_hosts(show, hosts)
          show

        {:error, changeset} ->
          Repo.rollback(changeset)
      end
    end)
  end

  # Updates the list of associate hosts of a show by adding or removing users to hosts list.
  # Suggested to run inside a transaction.
  defp update_associate_hosts(show, hosts) do
    show = Repo.preload(show, :hosts)

    # intersection contains unchanged hosts -> ignore them
    remove_hosts = show.hosts -- hosts
    add_hosts = hosts -- show.hosts

    # Add users to hosts
    Enum.each(add_hosts, fn host ->
      create_showhosts!(%{show_id: show.id, user_id: host.id})
    end)

    # Remove users from hosts
    remove_host_ids = Enum.map(remove_hosts, fn host -> host.id end)

    if !Enum.empty?(remove_host_ids) do
      count_removable_hosts = length(remove_host_ids)

      from(s in ShowHosts,
        where:
          s.show_id == ^show.id and
            s.user_id in ^remove_host_ids
      )
      |> Repo.delete_all()
      |> case do
        {^count_removable_hosts, nil} ->
          :ok

        {count_removed, _} ->
          Repo.rollback(
            "Couldn't remove all hosts (expect: #{count_removable_hosts} vs. #{count_removed})."
          )
      end
    end
  end

  @doc """
  Updates a show.

  ## Examples

      iex> update_show(show, %{field: new_value})
      {:ok, %Show{}}

      iex> update_show(show, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_show(%Show{} = show, attrs) do
    show
    |> Show.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a show.

  ## Examples

      iex> delete_show(show)
      {:ok, %Show{}}

      iex> delete_show(show)
      {:error, %Ecto.Changeset{}}

  """
  def delete_show(%Show{} = show) do
    Repo.delete(show)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking show changes.

  ## Examples

      iex> change_show(show)
      %Ecto.Changeset{data: %Show{}}

  """
  def change_show(%Show{} = show, attrs \\ %{}) do
    Show.changeset(show, attrs)
  end

  @doc """
  A forced reload of preloaded associations.
  Usefull when only the associations have changed and Show does need to be reloaded.

  ## Examples

      iex> reload_assoc(%Show{}, :episodes)
      %Show{}

      iex> reload_assoc(%Show{}, (from e in Episode, where: e.show_id == ^show_id, order_by: [desc: e.number]))
      %Show{}

  """
  def reload_assoc(%Show{} = show, fields_or_query) do
    Repo.preload(show, fields_or_query, force: true)
  end

  @doc """
  Creates ShowHosts, the association be show and user

  ## Examples

      iex> create_showhosts(%{field: value})
       %ShowHosts{}

      iex> create_showhosts(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_showhosts!(attrs \\ %{}) do
    %ShowHosts{}
    |> ShowHosts.changeset(attrs)
    |> Repo.insert!()
  end

  @doc """
  Returns the query for list of episodes exluding the once that are marked as deleted.

  ## Examples

      iex> list_available_episodes_query()
      %Ecto.Query{}

  """
  def list_available_episodes_query do
    from e in Episode,
      where: [is_deleted: false],
      order_by: [desc: e.number]
  end

  @doc """
  Lists all episodes for a given show.
  """
  def list_episodes_for_show(show_id) do
    list_available_episodes_query()
    |> where([e], e.show_id == ^show_id)
    |> Repo.all()
  end

  @doc """
  Returns the query for list of episodes including the (soft) deleted once.

  ## Examples

      iex> list_all_episodes_query()
      %Ecto.Query{}

  """
  def list_all_episodes_query do
    from e in Episode,
      order_by: [desc: e.number]
  end

  @doc """
  Returns the list of episodes exluding the once that are marked as deleted.

  ## Examples

      iex> list_available_episodes()
      [%Episode{}, ...]

  """
  def list_available_episodes do
    list_available_episodes_query()
    |> Repo.all()
  end

  @doc """
  Returns the list of episodes including the (soft) deleted once.

  ## Examples

      iex> list_all_episodes()
      [%Episode{}, ...]

  """
  def list_all_episodes do
    list_all_episodes_query()
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
  def get_episode!(id), do: Repo.get!(Episode, id)

  @doc """
    Finds the newest (TODO: not published ) episode for a show.
    Returns %Episode{} or `nil` and expects an id of the show.

    ## Examples

        iex> get_current_episode_for_show(123)
        %Episode{}

        iex> get_current_episode_for_show(456)
        nil

  """
  def get_current_episode_for_show(nil), do: nil

  def get_current_episode_for_show(show_id) do
    Repo.one(
      from e in Episode,
        where: [show_id: ^show_id, is_deleted: false],
        order_by: [desc: e.number],
        limit: 1
    )
  end

  @doc """
  Creates a episode.

  ## Examples

      iex> create_episode(%{field: value})
      {:ok, %Episode{}}

      iex> create_episode(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_episode(attrs \\ %{}) do
    %Episode{}
    |> Episode.changeset(attrs)
    |> Repo.insert()
  end

  def get_next_episode_number(show_id) do
    query =
      from e in Episode,
        select: max(e.number),
        where: [show_id: ^show_id, is_deleted: false]

    max_number = Repo.one(query) || 0
    max_number + 1
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

  @doc """
  Deletes a episode.

  ## Examples

      iex> delete_episode(episode)
      {:ok, %Episode{}}

      iex> delete_episode(episode)
      {:error, %Ecto.Changeset{}}

  """
  def delete_episode(%Episode{} = episode) do
    episode
    |> Episode.changeset(%{is_deleted: true})
    |> Repo.update()
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking episode changes.

  ## Examples

      iex> change_episode(episode)
      %Ecto.Changeset{data: %Episode{}}

  """
  def change_episode(%Episode{} = episode, attrs \\ %{}) do
    Episode.changeset(episode, attrs)
  end
end
