defmodule Radiator.Directory.Editor do
  @moduledoc """
  The Editor context for modifying data.
  """

  import Ecto.Query, warn: false

  alias Radiator.Auth

  alias Radiator.Repo
  alias Radiator.Directory
  alias Radiator.Directory.{Network, Podcast, Episode}

  alias Radiator.Directory.Editor.EditorHelpers

  alias Radiator.Perm.Permission
  alias Radiator.Perm.Ecto.PermissionType

  def list_networks(actor = %Auth.User{}) do
    query =
      from n in Network,
        join: p in "networks_perm",
        where: n.id == p.subject_id,
        where: p.user_id == ^actor.id

    query
    |> Repo.all()
  end

  # Permission

  def get_permission(user = %Auth.User{}, subject = %Network{}),
    do: get_permission_p(user, subject)

  def get_permission(user = %Auth.User{}, subject = %Podcast{}),
    do: get_permission_p(user, subject)

  def get_permission(user = %Auth.User{}, subject = %Episode{}),
    do: get_permission_p(user, subject)

  defp get_permission_p(user, subject) do
    case EditorHelpers.get_permission_p(user, subject) do
      nil -> nil
      perm -> perm.permission
    end
  end

  def has_permission(user, nil, _), do: false

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
    |> Ecto.assoc(:podcast)
    |> Repo.one!()
  end

  defp parent(_) do
    nil
  end
end
