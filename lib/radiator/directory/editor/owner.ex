defmodule Radiator.Directory.Editor.Owner do
  @moduledoc """
  Manipulation of data with the assumption that the actor has the :own right to the entity
  """
  import Ecto.Query, warn: false

  alias Ecto.Multi

  alias Radiator.Repo

  alias Radiator.Directory
  alias Radiator.Directory.{Network, Podcast, Episode}

  alias Radiator.Auth
  alias Radiator.Perm.Permission

  alias Directory.Editor.EditorHelpers

  use Radiator.Constants

  @doc """
  Temporary user for api stuff (just the most recent one) - until authentication on api level is done
  """
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
      |> Network.creation_changeset(attrs)

    Multi.new()
    |> Multi.insert(:network, network)
    |> Multi.insert(:permission, fn %{network: network} ->
      Ecto.build_assoc(network, :permissions)
      |> Permission.changeset(%{permission: :own})
      |> Ecto.Changeset.put_assoc(:user, actor)
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

  def remove_permission(user = %Auth.User{}, subject) do
    case EditorHelpers.get_permission(user, subject) do
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

  def set_permission(user = %Auth.User{}, subject = %st{}, permission)
      when st in [Podcast, Network, Episode] and is_permission(permission),
      do: do_set_permission(user, subject, permission)

  defp do_set_permission(user = %Auth.User{}, subject, permission)
       when is_permission(permission) do
    query =
      from perm in Ecto.assoc(subject, :permissions),
        where: perm.user_id == ^user.id

    Repo.one(query)
    |> case do
      nil ->
        Ecto.build_assoc(subject, :permissions, %{user_id: user.id})

      permission ->
        permission
    end
    |> Permission.changeset(%{permission: permission})
    |> Repo.insert_or_update()
    |> case do
      # hide the implementation detail for now
      {:ok, _perm} -> :ok
      {:error, changeset} -> {:error, changeset}
    end
  end
end
