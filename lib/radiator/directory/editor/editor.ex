defmodule Radiator.Directory.Editor.Editor do
  @moduledoc """
  Manipulation of data with the assumption that the user has
  the :edit permission to the entity.
  """
  import Ecto.Query, warn: false
  alias Ecto.Multi

  alias Radiator.Repo
  alias Radiator.Directory
  alias Radiator.Media.AudioFile

  alias Radiator.Directory.{
    PodcastQuery,
    Network,
    Podcast,
    Audio
  }

  alias Radiator.Contribution.{
    Person,
    AudioContribution,
    PodcastContribution
  }

  require Logger

  @doc """
  Gets a single podcast by its slug.

  ## Examples

      iex> get_podcast_by_slug(slug)
      %Podcast{}
  """
  def get_podcast_by_slug(slug) do
    Podcast
    |> PodcastQuery.find_by_slug(slug)
    |> Repo.one()
    |> Directory.Editor.preloaded_podcast()
  end

  @doc """
  Gets a single episode by its slug.

  ## Examples

      iex> get_episode_by_slug(podcast, slug)
      %Episode{}
  """
  def get_episode_by_slug(podcast_id, slug) when is_integer(podcast_id) do
    Directory.episodes_query(%{podcast: podcast_id, slug: slug})
    |> Repo.one()
    |> Directory.Editor.preloaded_episode()
  end

  def get_episode_by_slug(%Podcast{} = podcast, slug) do
    get_episode_by_slug(podcast.id, slug)
  end

  def create_person(%Network{id: network_id}, attrs) do
    Logger.debug("creating person --- #{inspect(attrs)}")

    # we need the podcast to have an id before we can save the image
    {update_attrs, insert_attrs} = Map.split(attrs, [:image, "image"])

    insert =
      %Person{network_id: network_id}
      |> Person.changeset(insert_attrs)

    Multi.new()
    |> Multi.insert(:person, insert)
    |> Multi.update(:person_updated, fn %{person: person} ->
      Person.changeset(person, update_attrs)
    end)
    |> Repo.transaction()
    # translate the multi result in a regular result
    |> case do
      {:ok, %{person_updated: podcast}} -> {:ok, podcast}
      {:error, :person, changeset, _map} -> {:error, changeset}
      {:error, :person_updated, changeset, _map} -> {:error, changeset}
      something -> something
    end
  end

  def update_person(%Person{} = subject, attrs) do
    subject
    |> Person.changeset(attrs)
    |> Repo.update()
  end

  def create_contribution(%Podcast{} = parent, attrs) do
    %PodcastContribution{podcast_id: parent.id}
    |> PodcastContribution.changeset(attrs)
    |> Repo.insert()
  end

  def create_contribution(%Audio{} = parent, attrs) do
    %AudioContribution{audio_id: parent.id}
    |> AudioContribution.changeset(attrs)
    |> Repo.insert()
  end

  def update_contribution(%PodcastContribution{} = subject, attrs) do
    subject
    |> PodcastContribution.changeset(attrs)
    |> Repo.update()
  end

  def update_contribution(%AudioContribution{} = subject, attrs) do
    subject
    |> AudioContribution.changeset(attrs)
    |> Repo.update()
  end

  def update_audio_file(audio_file = %AudioFile{}, attrs) do
    audio_file
    |> AudioFile.changeset(attrs)
    |> Repo.update()
  end
end
