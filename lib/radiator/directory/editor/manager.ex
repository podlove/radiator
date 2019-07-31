defmodule Radiator.Directory.Editor.Manager do
  @moduledoc """
  Manipulation of data with the assumption that the user has
  the :manage permission to the entity.
  """
  import Ecto.Query, warn: false

  alias Ecto.Multi
  alias Radiator.Repo
  alias Radiator.Support

  alias Radiator.Directory.{
    Network,
    Podcast,
    Episode,
    Audio,
    AudioPublication
  }

  alias Radiator.Contribution.{
    AudioContribution,
    PodcastContribution,
    Person
  }

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
    {update_attrs, insert_attrs} = Map.split(attrs, [:image, "image"])

    insert =
      %Podcast{network_id: network.id}
      |> Podcast.changeset(insert_attrs)

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

  def list_audio_publications(network = %Network{}) do
    network
    |> Ecto.assoc(:audio_publications)
    |> order_by(desc_nulls_first: :published_at)
    |> Repo.all()
    |> (&{:ok, &1}).()
  end

  def update_audio_publication(%AudioPublication{} = audio_publication, attrs) do
    audio_publication
    |> AudioPublication.changeset(attrs)
    |> Repo.update()
  end

  def list_audios(network = %Network{}) do
    network
    |> Ecto.assoc(:audios)
    |> Repo.all()
    |> (&{:ok, &1}).()
  end

  # todo: this raises if used on an episode that already has an associated audio.
  #       we need to define a way, maybe even a separate API,
  #       to remove or replace an episode audio.
  def create_audio(episode = %Episode{}, attrs) do
    Multi.new()
    |> Multi.insert(:audio, fn _ ->
      %Audio{} |> Audio.changeset(attrs)
    end)
    |> Multi.update(:episode, fn %{audio: audio} ->
      episode
      |> Repo.preload(:audio)
      |> Ecto.Changeset.change()
      |> Ecto.Changeset.put_assoc(:audio, audio)
    end)
    |> Repo.transaction()
    |> case do
      {:ok, %{audio: audio}} -> {:ok, audio}
      something -> something
    end
  end

  def create_audio(network = %Network{}, attrs) do
    Multi.new()
    |> Multi.insert(:audio_publication, fn _ ->
      Ecto.build_assoc(network, :audio_publications)
    end)
    |> Multi.insert(:audio, fn %{audio_publication: audio_publication} ->
      Ecto.build_assoc(audio_publication, :audio)
      |> Audio.changeset(attrs)
    end)
    |> Multi.update(:audio_publication_with_audio, fn %{
                                                        audio_publication: audio_publication,
                                                        audio: audio
                                                      } ->
      AudioPublication.changeset(audio_publication, %{audio_id: audio.id})
    end)
    |> Repo.transaction()
    |> case do
      {:ok, %{audio: audio}} -> {:ok, audio |> Repo.preload(:audio_publication)}
      something -> something
    end
  end

  def update_audio(%Audio{} = audio, attrs) do
    audio
    |> Audio.changeset(attrs)
    |> Repo.update()
  end

  def delete_audio(%Audio{} = audio) do
    Repo.delete(audio)
  end

  def create_audio_publication(network = %Network{}, attrs) do
    Ecto.build_assoc(network, :audio_publications)
    |> AudioPublication.changeset(attrs)
    |> Repo.insert()
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
    # todo: keys are sometimes atoms, sometimes binaries? why? can/should we enforce atoms?
    {update_attrs, insert_attrs} = Map.split(attrs, [:image, "image", :enclosure, "enclosure"])

    insert =
      Ecto.build_assoc(podcast, :episodes)
      |> Episode.changeset(insert_attrs)

    Multi.new()
    |> Multi.insert(:episode, insert)
    |> Multi.update(:episode_updated, fn %{episode: episode} ->
      Episode.changeset(episode, update_attrs)
    end)
    |> Repo.transaction()
    |> case do
      {:ok, %{episode_updated: episode}} -> {:ok, episode}
      {:error, :episode, changeset, _map} -> {:error, changeset}
      {:error, :episode_updates, changeset, _map} -> {:error, changeset}
      something -> something
    end
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
    publish(episode)
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
    depublish(episode)
  end

  @doc """
  Shedules episode for publication by giving it a future `published_at` date.

  ## Examples

      iex> schedule_episode(episode, datetime)
      {:ok, %Episode{}}

      iex> schedule_episode(bad_value, datetime)
      {:error, %Ecto.Changeset{}}
  """
  def schedule_episode(episode = %Episode{}, datetime = %DateTime{}) do
    schedule(episode, datetime)
  end

  def publish(subject = %AudioPublication{}) do
    subject
    |> AudioPublication.changeset(%{publish_state: :published})
    |> Repo.update()
  end

  def publish(subject = %Episode{}) do
    subject
    |> Episode.changeset(%{publish_state: :published})
    |> Repo.update()
  end

  def schedule(subject = %AudioPublication{}, datetime = %DateTime{}) do
    if Support.DateTime.after_utc_now?(datetime) do
      subject
      |> AudioPublication.changeset(%{publish_state: :scheduled, published_at: datetime})
      |> Repo.update()
    else
      {:error, :datetime_not_future}
    end
  end

  def schedule(subject = %Episode{}, datetime = %DateTime{}) do
    if Support.DateTime.after_utc_now?(datetime) do
      subject
      |> Episode.changeset(%{publish_state: :scheduled, published_at: datetime})
      |> Repo.update()
    else
      {:error, :datetime_not_future}
    end
  end

  def depublish(subject = %AudioPublication{}) do
    subject
    |> AudioPublication.changeset(%{publish_state: :depublished})
    |> Repo.update()
  end

  def depublish(subject = %Episode{}) do
    subject
    |> Episode.changeset(%{publish_state: :depublished})
    |> Repo.update()
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

  @doc """
  Make person contributor for podcast.
  """
  def add_podcast_contribution(%Podcast{} = podcast, %Person{} = person, role \\ nil) do
    position = determine_new_podcast_contribution_position(podcast)

    %PodcastContribution{}
    |> Ecto.Changeset.change(%{position: position})
    |> Ecto.Changeset.put_assoc(:podcast, podcast)
    |> Ecto.Changeset.put_assoc(:person, person)
    |> Ecto.Changeset.put_assoc(:role, role)
    |> Repo.insert!()
  end

  @doc """
  Make person contributor for audio.
  """
  def add_audio_contribution(%Audio{} = audio, %Person{} = person, role \\ nil) do
    position = determine_new_audio_contribution_position(audio)

    %AudioContribution{}
    |> Ecto.Changeset.change(%{position: position})
    |> Ecto.Changeset.put_assoc(:audio, audio)
    |> Ecto.Changeset.put_assoc(:person, person)
    |> Ecto.Changeset.put_assoc(:role, role)
    |> Repo.insert!()
  end

  defp determine_new_podcast_contribution_position(podcast) do
    get_max_contribution_position(podcast, PodcastContribution, :podcast_id) + 1
  end

  defp determine_new_audio_contribution_position(audio) do
    get_max_contribution_position(audio, AudioContribution, :audio_id) + 1
  end

  @spec get_max_contribution_position(Podcast.t() | Audio.t(), atom(), :audio_id | :podcast_id) ::
          integer()
  defp get_max_contribution_position(entity, schema, id_field) do
    entity_id = entity.id
    filters = [{id_field, entity_id}]

    from(c in schema, where: ^filters, select: max(c.position))
    |> Repo.one()
    |> case do
      nil -> 0
      value -> value
    end
  end

  def delete_person(%Person{} = subject) do
    subject
    |> Repo.delete()
  end

  # TODO
  # def add_podcast_contribution(%Podcast{} = podcast, %Person{} = person, role \\ nil)
  # def move_podcast_contribution(contribution, position)
  # def delete_podcast_contribution(contribution)
  #
  # def move_audio_contribution(contribution, position)
  # def delete_audio_contribution(contribution)

  def propagate_short_id(%Podcast{} = podcast) do
    Repo.transaction(fn ->
      Repo.all(Ecto.assoc(podcast, :episodes))
      |> Enum.each(fn episode ->
        short_id = Episode.construct_short_id(episode, podcast)
        Repo.update(Episode.changeset(episode, %{short_id: short_id}))
      end)
    end)
  end
end
