defmodule Radiator.Directory.Editor.Permission do
  import Ecto.Query, warn: false

  use Radiator.Constants

  alias Radiator.Repo
  alias Radiator.Auth
  alias Radiator.Perm.Permission
  alias Radiator.Directory.{Network, Podcast, Episode}

  alias Radiator.Perm.Ecto.PermissionType

  @type permission() :: :readonly | :edit | :manage | :own
  @type subject() :: Podcast.t() | Network.t() | Episode.t()

  @spec get_permission(Auth.User.t(), subject()) :: nil | any()
  def get_permission(user, subject)

  def get_permission(user = %Auth.User{}, subject = %Network{}),
    do: do_get_permission(user, subject)

  def get_permission(user = %Auth.User{}, subject = %Podcast{}),
    do: do_get_permission(user, subject)

  def get_permission(user = %Auth.User{}, subject = %Episode{}),
    do: do_get_permission(user, subject)

  defp do_get_permission(user, subject) do
    case fetch_permission(user, subject) do
      nil -> nil
      perm -> perm.permission
    end
  end

  defp fetch_permission(user, subject) do
    query =
      from perm in Ecto.assoc(subject, :permissions),
        where: perm.user_id == ^user.id

    Repo.one(query)
  end

  @spec has_permission(Auth.User.t(), subject(), permission()) :: boolean()
  def has_permission(user, subject, permission)

  def has_permission(_user, nil, _permission), do: false

  def has_permission(user, subject, permission) do
    case PermissionType.compare(get_permission(user, subject), permission) do
      :lt ->
        case parent(subject) do
          nil ->
            false

          parent ->
            has_permission(user, parent, permission)
        end

      # greater or equal is fine
      _ ->
        true
    end
  end

  defp parent(subject = %Episode{}) do
    subject
    |> Ecto.assoc(:podcast)
    |> Repo.one!()
  end

  defp parent(subject = %Podcast{}) do
    subject
    |> Ecto.assoc(:network)
    |> Repo.one!()
  end

  defp parent(_) do
    nil
  end

  @spec remove_permission(Auth.User.t(), subject()) :: :ok | nil
  def remove_permission(user = %Auth.User{}, subject) do
    case fetch_permission(user, subject) do
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

  @spec set_permission(Auth.User.t(), subject(), permission()) :: :ok | {:error, any()}
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
