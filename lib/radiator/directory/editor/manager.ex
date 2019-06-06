defmodule Radiator.Directory.Editor.Manager do
  @moduledoc """
  Manipulation of data with the assumption that the user has
  the :manage permission to the entity.
  """
  import Ecto.Query, warn: false

  alias Ecto.Multi

  alias Radiator.Support
  alias Radiator.Repo

  alias Radiator.Directory.{Network, Podcast, Episode, Audio}

  @doc """
  Creates a podcast.

  Makes the creator the sole owner.

  ## Examples

      iex> create_podcast(current_user, %Network{} = network, %{field: value})
      {:ok, %Podcast{}}

      iex> create_podcast(current_user, %Network{} = network, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """

  require Logger

  def create_podcast(%Network{} = network, attrs) do
    Logger.debug("creating podcast --- #{inspect(attrs)}")

    # we need the podcast to have an id before we can save the image
    {update_attrs, insert_attrs} = Map.split(attrs, [:image])

    insert =
      %Podcast{}
      |> Podcast.changeset(insert_attrs)
      |> Ecto.Changeset.put_assoc(:network, network)

    Multi.new()
    |> Multi.insert(:podcast, insert)
    |> Multi.update(:podcast_updated, fn %{podcast: podcast} ->
      Podcast.changeset(podcast, update_attrs)
    end)
    |> Repo.transaction()
    # translate the multi result in a regular result
    |> case do
      {:ok, %{podcast_updated: podcast}} -> {:ok, podcast}
      {:error, :podcast, changeset, _map} -> {:error, changeset}
      {:error, :podcast_updates, changeset, _map} -> {:error, changeset}
      something -> something
    end
  end

  def create_audio(attrs \\ %{}) do
    %Audio{}
    |> Audio.changeset(attrs)
    |> Repo.insert()
  end

  def update_audio(%Audio{} = audio, attrs) do
    audio
    |> Audio.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Creates an episode.

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
  Deletes an Episode.

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
  Updates an Episode.

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
  Returns an `%Ecto.Changeset{}` for tracking episode changes.

  ## Examples

      iex> change_episode(episode)
      %Ecto.Changeset{source: %Episode{}}

  """
  def change_episode(%Episode{} = episode) do
    Episode.changeset(episode, %{})
  end

  @doc """
  Publishes a single episode by giving it a `published_at` date.

  ## Examples

      iex> publish_episode(episode)
      {:ok, %Episode{}}

      iex> publish_episode(bad_value)
      {:error, %Ecto.Changeset{}}
  """
  def publish_episode(%Episode{} = episode) do
    update_episode(episode, %{published_at: DateTime.utc_now()})
  end

  @doc """
  Depublishes a single episode by removing its `published_at` date.

  ## Examples

      iex> depublish_episode(episode)
      {:ok, %Episode{}}

      iex> depublish_episode(bad_value)
      {:error, %Ecto.Changeset{}}
  """
  def depublish_episode(%Episode{} = episode) do
    update_episode(episode, %{published_at: nil})
  end

  @doc """
  Shedules episode for publication by giving it a future `published_at` date.

  ## Examples

      iex> schedule_episode(episode, datetime)
      {:ok, %Episode{}}

      iex> schedule_episode(bad_value, datetime)
      {:error, %Ecto.Changeset{}}

      iex> schedule_episode(episode, past_datetime)
      {:error, :datetime_not_future}
  """
  def schedule_episode(episode = %Episode{}, datetime = %DateTime{}) do
    if Support.DateTime.after_utc_now?(datetime) do
      update_episode(episode, %{published_at: datetime})
    else
      {:error, :datetime_not_future}
    end
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

      iex> publish_podcast(podcast)
      {:ok, %Podcast{}}

      iex> publish_podcast(bad_value)
      {:error, %Ecto.Changeset{}}
  """
  def publish_podcast(%Podcast{} = podcast) do
    update_podcast(podcast, %{published_at: DateTime.utc_now()})
  end

  @doc """
  Depublishes a single podcast by removing its `published_at` date.

  ## Examples

      iex> depublish_podcast(podcast)
      {:ok, %Podcast{}}

      iex> depublish_podcast(bad_value)
      {:error, %Ecto.Changeset{}}
  """
  def depublish_podcast(%Podcast{} = podcast) do
    update_podcast(podcast, %{published_at: nil})
  end
end
