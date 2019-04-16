defmodule Radiator.Directory.Editor.Owner do
  @moduledoc """
  Manipulation of data with the assumption that the actor has the :own right to the entity
  """
  import Ecto.Query, warn: false

  alias Ecto.Multi

  alias Radiator.Repo

  alias Radiator.Directory
  alias Directory.{Network, NetworkPermission}
  alias Directory.{Podcast, PodcastPermission}
  alias Directory.{Episode, EpisodePermission}

  alias Radiator.Auth

  @doc """
  Temporary user for api stuff (just the most recent one) - until authentication on api level is done
  """
  @spec api_user_shim() :: Radiator.Auth.User.t()
  def api_user_shim() do
    Repo.all(Auth.User)
    |> List.last()
  end

  @doc """
  Creates a network.

  ## Examples

      iex> create_network(%{field: value})
      {:ok, %Network{}}

      iex> create_network(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """

  def create_network(actor = %Auth.User{}, attrs) when is_map(attrs) do
    network =
      %Network{}
      |> Network.changeset(attrs)

    Multi.new()
    |> Multi.insert(:network, network)
    |> Multi.insert(:network_perm, fn %{network: network} ->
      %NetworkPermission{}
      |> NetworkPermission.changeset(%{permission: :own})
      |> Ecto.Changeset.put_assoc(:user, actor)
      |> Ecto.Changeset.put_assoc(:network, network)
    end)
    |> Repo.transaction()
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

  ## Permission manipulation

  def remove_permission(user = %Auth.User{}, episode = %Episode{}) do
    case Repo.get_by(EpisodePermission, user_id: user.id, episode_id: episode.id) do
      nil ->
        nil

      perm ->
        Repo.delete(perm)
        # hide the implementation detail for now
        |> case do
          {:ok, _perm} -> :ok
          _ -> nil
        end
    end
  end

  def set_permission(user, entity, permission)

  # Todo: terribly redundant, either make a macro or have a better idea

  def set_permission(user = %Auth.User{}, subject = %Network{}, permission)
      when is_atom(permission) do
    case Repo.get_by(NetworkPermission, user_id: user.id, network_id: subject.id) do
      nil -> %NetworkPermission{user_id: user.id, network_id: subject.id}
      permission -> permission
    end
    |> NetworkPermission.changeset(%{permission: permission})
    |> set_permission_shared()
  end

  def set_permission(user = %Auth.User{}, subject = %Podcast{}, permission)
      when is_atom(permission) do
    case Repo.get_by(PodcastPermission, user_id: user.id, podcast_id: subject.id) do
      nil -> %PodcastPermission{user_id: user.id, podcast_id: subject.id}
      permission -> permission
    end
    |> PodcastPermission.changeset(%{permission: permission})
    |> set_permission_shared()
  end

  def set_permission(user = %Auth.User{}, subject = %Episode{}, permission)
      when is_atom(permission) do
    case Repo.get_by(EpisodePermission, user_id: user.id, episode_id: subject.id) do
      nil -> %EpisodePermission{user_id: user.id, episode_id: subject.id}
      permission -> permission
    end
    |> EpisodePermission.changeset(%{permission: permission})
    |> set_permission_shared()
  end

  defp set_permission_shared(changeset) do
    changeset
    |> Repo.insert_or_update()
    |> case do
      # hide the implementation detail for now
      {:ok, _perm} -> :ok
      {:error, changeset} -> {:error, changeset}
    end
  end
end
