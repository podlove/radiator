defmodule Radiator.Directory.Editor.Owner do
  @moduledoc """
  Manipulation of data with the assumption that the actor has the :own right to the entity
  """
  import Ecto.Query, warn: false

  alias Ecto.Multi

  alias Radiator.Repo
  alias Radiator.Directory.{Podcast, PodcastPermission}
  alias Radiator.Directory.{Episode, EpisodePermission}
  alias Radiator.Auth

  @doc """
  Creates a podcast.

  Makes the creator the sole owner.

  ## Examples

      iex> create_podcast(current_user, %{field: value})
      {:ok, %Podcast{}}

      iex> create_podcast(current_user,%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_podcast(actor = %Auth.User{}, attrs) do
    podcast_changeset =
      %Podcast{}
      |> Podcast.changeset(attrs)

    Multi.new()
    |> Multi.insert(:podcast, podcast_changeset)
    |> Multi.insert_or_update(:podcast_perm, fn %{podcast: podcast} ->
      %PodcastPermission{user_id: actor.id, podcast_id: podcast.id}
      |> PodcastPermission.changeset(%{permission: :own})
    end)
    |> Repo.transaction()
  end

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

  def set_permission(user = %Auth.User{}, episode = %Episode{}, permission)
      when is_atom(permission) do
    (Repo.get_by(EpisodePermission, user_id: user.id, episode_id: episode.id) ||
       %EpisodePermission{user_id: user.id, episode_id: episode.id})
    |> EpisodePermission.changeset(%{permission: permission})
    |> Repo.insert_or_update()
    |> case do
      # hide the implementation detail for now
      {:ok, _perm} -> :ok
      {:error, changeset} -> {:error, changeset}
    end
  end
end
