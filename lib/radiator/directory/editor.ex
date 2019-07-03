defmodule Radiator.Directory.Editor do
  @moduledoc """
  The Editor context for querying and modifying data as an authorized user.

  It is the single point of access for all actions requiring an authenticated user.
  """
  use Radiator.Constants

  import Ecto.Query, warn: false
  import Radiator.Directory.Editor.Permission

  alias Radiator.Auth

  alias Radiator.Support
  alias Radiator.Repo
  alias Radiator.Directory
  alias Radiator.Directory.{Network, Podcast, Episode, Editor, Audio}

  @doc """
  Returns a list of networks the user has at least `:readonly` permissions on.

  ## Examples

      iex> list_networks(me)
      [%Network{}, ...]

  """
  def list_networks(user = %Auth.User{}) do
    query =
      from n in Network,
        join: p in "networks_perm",
        where: n.id == p.subject_id,
        where: p.user_id == ^user.id,
        order_by: n.title

    query
    |> Repo.all()
  end

  @doc """
  Gets a single network.

  ## Examples

      iex> get_network(me, 123)
      {:ok, %Network{}}

      iex> get_network(unauthorized_me, 123)
      {:error, :not_authorized}

      iex> get_network(oblivious_me, 999_998)
      {:error, :not_found}

  """
  @spec get_network(Auth.User.t(), pos_integer() | nil) ::
          {:ok, Network.t()} | {:error, :not_authorized | :not_found | :unprocessable}
  def get_network(user, id)

  def get_network(_, nil) do
    {:error, :unprocessable}
  end

  def get_network(user = %Auth.User{}, id) do
    case Repo.get(Network, id) do
      nil ->
        @not_found_match

      network = %Network{} ->
        if has_permission(user, network, :readonly) do
          {:ok, network}
        else
          @not_authorized_match
        end
    end
  end

  @doc """
  Creates a network.

  ## Examples

      iex> create_network(me, %{title: "My First Network"})
      {:ok, %Network{}}

      iex> create_network(me, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """

  def create_network(user = %Auth.User{}, attrs) do
    case Editor.Owner.create_network(user, attrs) do
      {:ok, %{network: network}} -> {:ok, network}
      {:error, :network, changeset, _} -> {:error, changeset}
    end
  end

  @doc """
  Creates a network.

  ## Examples

      iex> update_network(me, network, %{title: "Professionals United"})
      {:ok, %Network{}}

      iex> update_network(me, network, %{title: nil})
      {:error, %Ecto.Changeset{}}

      iex> update_network(me, readonly_network, %{title: "Hostile Takeover 1"})
      {:error, :not_authorized}
  """
  def update_network(user = %Auth.User{}, network = %Network{}, attrs) do
    if has_permission(user, network, :own) do
      Editor.Owner.update_network(network, attrs)
    else
      @not_authorized_match
    end
  end

  def delete_network(user = %Auth.User{}, network = %Network{}) do
    if has_permission(user, network, :own) do
      Editor.Owner.delete_network(network)
    else
      @not_authorized_match
    end
  end

  @doc """
  List podcasts for user.

  FIXME does not work as intended.

    test cases:
    - user has permission in podcast but not in parent network, sees podcast
    - user has permission in network but not specifically in child podcast, still can see podcast

    implementation idea:
    1) fetch all podcasts a user has specific permissions for
    2) fetch all podcasts for all networks a user has specific permissions for
    3) merge results from 1) and 2)

  """
  def list_podcasts(user = %Auth.User{}) do
    query =
      from n in Podcast,
        join: p in "podcasts_perm",
        where: n.id == p.subject_id,
        where: p.user_id == ^user.id,
        order_by: n.title

    query
    |> Repo.all()
  end

  defp list_podcast_query(user = %Auth.User{}, network = %Network{}) do
    if has_permission(user, network, :readonly) do
      from pod in Podcast,
        where: pod.network_id == ^network.id,
        order_by: pod.title
    else
      from pod in Podcast,
        join: perm in "podcasts_perm",
        where: pod.id == perm.subject_id,
        where: perm.user_id == ^user.id,
        where: pod.network_id == ^network.id,
        order_by: pod.title
    end
  end

  # FIXME see list_podcasts/1 above
  # - user should be able to list podcasts that he has permissions to even if he does not have permissions in the given network
  def list_podcasts(user = %Auth.User{}, network = %Network{}) do
    list_podcast_query(user, network)
    |> Repo.all()
  end

  def list_podcasts_with_episode_counts(user = %Auth.User{}, network = %Network{}) do
    list_podcast_query(user, network)
    |> Podcast.preload_episode_counts()
    |> Repo.all()
  end

  def create_podcast(user = %Auth.User{}, network = %Network{}, attrs) do
    if has_permission(user, network, :manage) do
      Editor.Manager.create_podcast(network, attrs)
    else
      @not_authorized_match
    end
  end

  def update_podcast(user = %Auth.User{}, podcast = %Podcast{}, attrs) do
    if has_permission(user, podcast, :edit) do
      Editor.Manager.update_podcast(podcast, attrs)
    else
      @not_authorized_match
    end
  end

  def publish_podcast(user = %Auth.User{}, podcast = %Podcast{}) do
    if has_permission(user, podcast, :manage) do
      Editor.Manager.publish_podcast(podcast)
    else
      @not_authorized_match
    end
  end

  def depublish_podcast(user = %Auth.User{}, podcast = %Podcast{}) do
    if has_permission(user, podcast, :manage) do
      Editor.Manager.depublish_podcast(podcast)
    else
      @not_authorized_match
    end
  end

  def delete_podcast(actor = %Auth.User{}, podcast = %Podcast{}) do
    podcast =
      podcast
      |> Repo.preload(:network)

    if has_permission(actor, podcast, :own) ||
         has_permission(actor, podcast.network, :manage) do
      Editor.Manager.delete_podcast(podcast)
    else
      @not_authorized_match
    end
  end

  @doc """
  Gets a single podcast.

  ## Examples

      iex> get_podcast(me, 123)
      {:ok, %Podcast{}}

      iex> get_podcast(unauthorized_me, 123)
      {:error, :not_authorized}

      iex> get_podcast(oblivious_me, 999_998)
      {:error, :not_found}

  """
  @spec get_podcast(Auth.User.t(), pos_integer() | nil) ::
          {:ok, Podcast.t()} | {:error, :not_authorized | :not_found | :unprocessable}
  def get_podcast(user, id)

  def get_podcast(_, nil) do
    {:error, :unprocessable}
  end

  def get_podcast(user = %Auth.User{}, id) do
    case Repo.get(Podcast, id) do
      nil ->
        @not_found_match

      podcast = %Podcast{} ->
        if has_permission(user, podcast, :readonly) do
          {:ok, podcast}
        else
          @not_authorized_match
        end
    end
  end

  def get_episodes_count_for_podcast!(user = %Auth.User{}, id) do
    get_podcast(user, id)
    |> case do
      {:ok, podcast} ->
        count =
          from(e in Episode, where: e.podcast_id == ^podcast.id)
          |> Repo.aggregate(:count, :id)

        {:ok, count}

      _ ->
        @not_authorized_match
    end
  end

  @doc """
  List episodes.

  TODO: use `Radiator.Directory.EpisodeQuery`
  """
  def list_episodes(user = %Auth.User{}, podcast = %Podcast{}) do
    query =
      if has_permission(user, podcast, :readonly) do
        from ep in Episode,
          where: ep.podcast_id == ^podcast.id,
          order_by: ep.title,
          order_by: [desc: ep.id]
      else
        from ep in Episode,
          join: perm in "episode_perm",
          where: ep.id == perm.subject_id,
          where: perm.user_id == ^user.id,
          where: ep.podcast_id == ^podcast.id,
          order_by: [desc: ep.id]
      end

    query
    |> Repo.all()
  end

  def create_episode(user = %Auth.User{}, podcast = %Podcast{}, attrs) do
    if has_permission(user, podcast, :manage) do
      Editor.Manager.create_episode(podcast, attrs)
    else
      @not_authorized_match
    end
  end

  def update_episode(user = %Auth.User{}, episode = %Episode{}, attrs) do
    if has_permission(user, episode, :edit) do
      Editor.Manager.update_episode(episode, attrs)
    else
      @not_authorized_match
    end
  end

  def publish_episode(user = %Auth.User{}, episode = %Episode{}) do
    if has_permission(user, episode, :manage) do
      Editor.Manager.publish_episode(episode)
    else
      @not_authorized_match
    end
  end

  def depublish_episode(user = %Auth.User{}, episode = %Episode{}) do
    if has_permission(user, episode, :manage) do
      Editor.Manager.depublish_episode(episode)
    else
      @not_authorized_match
    end
  end

  def schedule_episode(user = %Auth.User{}, episode = %Episode{}, datetime = %DateTime{}) do
    if has_permission(user, episode, :manage) do
      Editor.Manager.schedule_episode(episode, datetime)
    else
      @not_authorized_match
    end
  end

  def delete_episode(user = %Auth.User{}, episode = %Episode{}) do
    if has_permission(user, episode, :own) do
      Editor.Manager.delete_episode(episode)
    else
      @not_authorized_match
    end
  end

  @doc """
  Gets a single episode.

  ## Examples

      iex> get_episode(me, 123)
      {:ok, %Episode{}}

      iex> get_episode(unauthorized_me, 123)
      {:error, :not_authorized}

      iex> get_episode(oblivious_me, 999_998)
      {:error, :not_found}

  """
  @spec get_episode(Auth.User.t(), pos_integer()) ::
          {:ok, Episode.t()} | {:error, :not_authorized | :not_found}
  def get_episode(user = %Auth.User{}, id) do
    case Repo.get(Episode, id) do
      nil ->
        @not_found_match

      episode = %Episode{} ->
        if has_permission(user, episode, :readonly) do
          {:ok, episode |> Directory.preload_for_episode()}
        else
          @not_authorized_match
        end
    end
  end

  def get_episode_by_podcast_id_and_guid(user = %Auth.User{}, podcast_id, guid)
      when not is_nil(podcast_id) and not is_nil(guid) do
    query =
      from ep in Episode,
        where: ep.podcast_id == ^podcast_id,
        where: ep.guid == ^guid

    query
    |> Repo.one()
    |> case do
      nil ->
        @not_found_match

      episode = %Episode{} ->
        if has_permission(user, episode, :readonly) do
          {:ok, episode |> preloaded_episode()}
        else
          @not_authorized_match
        end
    end
  end

  defp preloaded_episode(episode) do
    Repo.preload(episode, [:podcast, audio: [:chapters, :audio_files]])
  end

  def is_published(%Podcast{published_at: nil}), do: false
  def is_published(%Episode{published_at: nil}), do: false

  def is_published(%Podcast{published_at: date}),
    do: Support.DateTime.before_utc_now?(date)

  def is_published(%Episode{published_at: date}),
    do: Support.DateTime.before_utc_now?(date)

  @spec detach_all_audios_from_episode(Episode.t()) :: Episode.t()
  def detach_all_audios_from_episode(episode = %Episode{}) do
    Ecto.assoc(episode, :attachments) |> Repo.delete_all()
    episode
  end

  @spec get_audio(Auth.User.t(), pos_integer()) ::
          {:ok, Audio.t()} | {:error, :not_authorized | :not_found}
  def get_audio(user = %Auth.User{}, id) do
    case Repo.get(Audio, id) do
      nil ->
        @not_found_match

      audio = %Audio{} ->
        if has_permission(user, audio, :readonly) do
          {:ok, audio}
        else
          @not_authorized_match
        end
    end
  end

  def create_audio(user = %Auth.User{}, episode = %Episode{}, attrs) do
    if has_permission(user, episode, :edit) do
      Editor.Manager.create_audio(episode, attrs)
    else
      @not_authorized_match
    end
  end

  def create_audio(user = %Auth.User{}, network = %Network{}, attrs) do
    if has_permission(user, network, :edit) do
      Editor.Manager.create_audio(network, attrs)
    else
      @not_authorized_match
    end
  end

  def update_audio(user = %Auth.User{}, audio = %Audio{}, attrs) do
    if has_permission(user, audio, :edit) do
      Editor.Manager.update_audio(audio, attrs)
    else
      @not_authorized_match
    end
  end

  def delete_audio(user = %Auth.User{}, audio = %Audio{}) do
    if has_permission(user, audio, :own) do
      Editor.Manager.delete_audio(audio)
    else
      @not_authorized_match
    end
  end
end
