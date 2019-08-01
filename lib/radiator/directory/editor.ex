defmodule Radiator.Directory.Editor do
  @moduledoc """
  The Editor context for querying and modifying data as an authorized actor.

  It is the single point of access for all actions requiring an authenticated actor.
  """
  use Radiator.Constants

  import Ecto.Query, warn: false
  import Radiator.Directory.Editor.Permission, only: :functions

  alias Radiator.Auth

  alias Radiator.Support
  alias Radiator.Repo
  alias Radiator.AudioMeta
  alias Radiator.AudioMeta.Chapter
  alias Radiator.Directory
  alias Radiator.Media.AudioFile

  alias Radiator.Directory.{
    Network,
    Podcast,
    Episode,
    Editor,
    Audio,
    AudioPublication,
    Collaborator
  }

  alias Radiator.Contribution.{
    Person,
    AudioContribution,
    PodcastContribution
  }

  @doc """
  Returns a list of networks the actor has at least `:readonly` permissions on.

  ## Examples

      iex> list_networks(me)
      [%Network{}, ...]

  """
  def list_networks(actor = %Auth.User{}) do
    query =
      from n in Network,
        join: p in "networks_perm",
        where: n.id == p.subject_id,
        where: p.user_id == ^actor.id,
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
  def get_network(actor, id)

  def get_network(_, nil) do
    {:error, :unprocessable}
  end

  def get_network(actor = %Auth.User{}, id) do
    case Repo.get(Network, id) do
      nil ->
        @not_found_match

      network = %Network{} ->
        if has_permission(actor, network, :readonly) do
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

  def create_network(actor = %Auth.User{}, attrs) do
    Editor.Owner.create_network(actor, attrs)
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
  def update_network(actor = %Auth.User{}, network = %Network{}, attrs) do
    if has_permission(actor, network, :own) do
      Editor.Owner.update_network(network, attrs)
    else
      @not_authorized_match
    end
  end

  def delete_network(actor = %Auth.User{}, network = %Network{}) do
    if has_permission(actor, network, :own) do
      Editor.Owner.delete_network(network)
    else
      @not_authorized_match
    end
  end

  @doc """
  List podcasts for actor.

  FIXME does not work as intended.

    test cases:
    - actor has permission in podcast but not in parent network, sees podcast
    - actor has permission in network but not specifically in child podcast, still can see podcast

    implementation idea:
    1) fetch all podcasts a actor has specific permissions for
    2) fetch all podcasts for all networks a actor has specific permissions for
    3) merge results from 1) and 2)

  """
  def list_podcasts(actor = %Auth.User{}) do
    Podcast
    |> Repo.all()
    |> Enum.filter(fn podcast -> has_permission(actor, podcast, :readonly) end)
  end

  defp list_podcast_query(actor = %Auth.User{}, network = %Network{}) do
    if has_permission(actor, network, :readonly) do
      from pod in Podcast,
        where: pod.network_id == ^network.id,
        order_by: pod.title
    else
      from pod in Podcast,
        join: perm in "podcasts_perm",
        where: pod.id == perm.subject_id,
        where: perm.user_id == ^actor.id,
        where: pod.network_id == ^network.id,
        order_by: pod.title
    end
  end

  # FIXME see list_podcasts/1 above
  # - actor should be able to list podcasts that he has permissions to even if he does not have permissions in the given network
  def list_podcasts(actor = %Auth.User{}, network = %Network{}) do
    list_podcast_query(actor, network)
    |> Repo.all()
  end

  def list_podcasts_with_episode_counts(actor = %Auth.User{}, network = %Network{}) do
    list_podcast_query(actor, network)
    |> Podcast.preload_episode_counts()
    |> Repo.all()
  end

  def create_podcast(actor = %Auth.User{}, network = %Network{}, attrs) do
    if has_permission(actor, network, :manage) do
      Editor.Manager.create_podcast(network, attrs)
    else
      @not_authorized_match
    end
  end

  def update_podcast(actor = %Auth.User{}, podcast = %Podcast{}, attrs) do
    if has_permission(actor, podcast, :edit) do
      Editor.Manager.update_podcast(podcast, attrs)
    else
      @not_authorized_match
    end
  end

  def publish_podcast(actor = %Auth.User{}, podcast = %Podcast{}) do
    if has_permission(actor, podcast, :manage) do
      Editor.Manager.publish_podcast(podcast)
    else
      @not_authorized_match
    end
  end

  def depublish_podcast(actor = %Auth.User{}, podcast = %Podcast{}) do
    if has_permission(actor, podcast, :manage) do
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
  def get_podcast(actor, id)

  def get_podcast(_, nil) do
    {:error, :unprocessable}
  end

  def get_podcast(actor = %Auth.User{}, id) do
    case Repo.get(Podcast, id) do
      nil ->
        @not_found_match

      podcast = %Podcast{} ->
        if has_permission(actor, podcast, :readonly) do
          {:ok, podcast}
        else
          @not_authorized_match
        end
    end
  end

  def get_episodes_count_for_podcast!(actor = %Auth.User{}, id) do
    get_podcast(actor, id)
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
  def list_episodes(actor = %Auth.User{}, podcast = %Podcast{}) do
    query =
      if has_permission(actor, podcast, :readonly) do
        from ep in Episode,
          where: ep.podcast_id == ^podcast.id,
          order_by: ep.title,
          order_by: [desc: ep.id]
      else
        from ep in Episode,
          join: perm in "episode_perm",
          where: ep.id == perm.subject_id,
          where: perm.user_id == ^actor.id,
          where: ep.podcast_id == ^podcast.id,
          order_by: [desc: ep.id]
      end

    query
    |> Repo.all()
  end

  @doc """
  List episodes for audio that given user can see.
  """
  def list_episodes(actor = %Auth.User{}, audio = %Audio{}) do
    if can_access_audio(actor, audio, :readonly) do
      audio
      |> Ecto.assoc(:episodes)
      |> Repo.all()
      |> Enum.filter(fn episode -> has_permission(actor, episode, :readonly) end)
    else
      @not_authorized_match
    end
  end

  def get_audio_publication(actor = %Auth.User{}, id) do
    case Repo.get(AudioPublication, id) do
      nil ->
        @not_found_match

      audio_publication = %AudioPublication{} ->
        if can_access_audio_publication(actor, audio_publication, :readonly) do
          {:ok, audio_publication}
        else
          @not_authorized_match
        end
    end
  end

  def list_audio_publications(actor = %Auth.User{}, network = %Network{}) do
    if has_permission(actor, network, :readonly) do
      Editor.Manager.list_audio_publications(network)
    else
      @not_authorized_match
    end
  end

  def update_audio_publication(
        actor = %Auth.User{},
        audio_publication = %AudioPublication{},
        params
      ) do
    if can_access_audio_publication(actor, audio_publication, :manage) do
      Editor.Manager.update_audio_publication(audio_publication, params)
    else
      @not_authorized_match
    end
  end

  def delete_audio_publication(actor = %Auth.User{}, audio_publication = %AudioPublication{}) do
    if can_access_audio_publication(actor, audio_publication, :own) do
      Editor.Owner.delete_audio_publication(audio_publication)
    else
      @not_authorized_match
    end
  end

  def create_audio_publication(actor = %Auth.User{}, network = %Network{}, attrs) do
    if has_permission(actor, network, :manage) do
      Editor.Manager.create_audio_publication(network, attrs)
    else
      @not_authorized_match
    end
  end

  def create_episode(actor = %Auth.User{}, podcast = %Podcast{}, attrs) do
    if has_permission(actor, podcast, :manage) do
      Editor.Manager.create_episode(podcast, attrs)
    else
      @not_authorized_match
    end
  end

  def update_episode(actor = %Auth.User{}, episode = %Episode{}, attrs) do
    if has_permission(actor, episode, :edit) do
      Editor.Manager.update_episode(episode, attrs)
    else
      @not_authorized_match
    end
  end

  def publish_episode(actor = %Auth.User{}, episode = %Episode{}) do
    if has_permission(actor, episode, :manage) do
      Editor.Manager.publish_episode(episode)
    else
      @not_authorized_match
    end
  end

  def depublish_episode(actor = %Auth.User{}, episode = %Episode{}) do
    if has_permission(actor, episode, :manage) do
      Editor.Manager.depublish_episode(episode)
    else
      @not_authorized_match
    end
  end

  def schedule_episode(actor = %Auth.User{}, episode = %Episode{}, datetime = %DateTime{}) do
    if has_permission(actor, episode, :manage) do
      Editor.Manager.schedule_episode(episode, datetime)
    else
      @not_authorized_match
    end
  end

  def delete_episode(actor = %Auth.User{}, episode = %Episode{}) do
    if has_permission(actor, episode, :own) do
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
  def get_episode(actor = %Auth.User{}, id) do
    case Repo.get(Episode, id) do
      nil ->
        @not_found_match

      episode = %Episode{} ->
        if has_permission(actor, episode, :readonly) do
          {:ok, episode |> Directory.preload_for_episode()}
        else
          @not_authorized_match
        end
    end
  end

  def get_episode_by_podcast_id_and_guid(actor = %Auth.User{}, podcast_id, guid)
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
        if has_permission(actor, episode, :readonly) do
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

  def get_chapter(actor = %Auth.User{}, audio = %Audio{}, start) do
    case Repo.get_by(Chapter, audio_id: audio.id, start: start) do
      nil ->
        @not_found_match

      chapter = %Chapter{} ->
        if can_access_audio(actor, audio, :readonly) do
          {:ok, chapter}
        else
          @not_authorized_match
        end
    end
  end

  def create_chapter(actor = %Auth.User{}, audio, attrs) do
    if can_access_audio(actor, audio, :edit) do
      AudioMeta.create_chapter(audio, attrs)
    else
      @not_authorized_match
    end
  end

  def update_chapter(actor = %Auth.User{}, chapter = %Chapter{}, attrs) do
    if can_access_audio(actor, %Audio{id: chapter.audio_id}, :edit) do
      AudioMeta.update_chapter(chapter, attrs)
    else
      @not_authorized_match
    end
  end

  def delete_chapter(actor = %Auth.User{}, chapter = %Chapter{}) do
    if can_access_audio(actor, %Audio{id: chapter.audio_id}, :own) do
      AudioMeta.delete_chapter(chapter)
    else
      @not_authorized_match
    end
  end

  @spec get_audio(Auth.User.t(), pos_integer()) ::
          {:ok, Audio.t()} | {:error, :not_authorized | :not_found}
  def get_audio(actor = %Auth.User{}, id) do
    case Repo.get(Audio, id) do
      nil ->
        @not_found_match

      audio = %Audio{} ->
        if can_access_audio(actor, audio, :readonly) do
          {:ok, audio}
        else
          @not_authorized_match
        end
    end
  end

  def create_audio(actor = %Auth.User{}, episode = %Episode{}, attrs) do
    if has_permission(actor, episode, :edit) do
      Editor.Manager.create_audio(episode, attrs)
    else
      @not_authorized_match
    end
  end

  def create_audio(actor = %Auth.User{}, network = %Network{}, attrs) do
    if has_permission(actor, network, :edit) do
      Editor.Manager.create_audio(network, attrs)
    else
      @not_authorized_match
    end
  end

  def update_audio(actor = %Auth.User{}, audio = %Audio{}, attrs) do
    if can_access_audio(actor, audio, :edit) do
      Editor.Manager.update_audio(audio, attrs)
    else
      @not_authorized_match
    end
  end

  def delete_audio(actor = %Auth.User{}, audio = %Audio{}) do
    if can_access_audio(actor, audio, :own) do
      Editor.Manager.delete_audio(audio)
    else
      @not_authorized_match
    end
  end

  defp can_access_audio_publication(actor, audio_publication, permission) do
    with network = %Network{} <- Repo.get(Network, audio_publication.network_id) do
      has_permission(actor, network, permission)
    else
      _ -> false
    end
  end

  defp can_access_audio(actor, audio, permission) do
    Enum.any?(get_audio_publication_parents(audio), fn parent ->
      has_permission(actor, parent, permission)
    end)
  end

  defp get_audio_publication_parents(audio) do
    network =
      audio
      |> Ecto.assoc(:audio_publication)
      |> Repo.one()

    episodes = audio |> Ecto.assoc(:episodes) |> Repo.all()

    if network, do: [network | episodes], else: episodes
  end

  ## Audio File

  def list_audio_files(actor = %Auth.User{}, audio = %Audio{}) do
    if can_access_audio(actor, audio, :readonly) do
      Editor.Manager.list_audio_files(audio)
    else
      @not_authorized_match
    end
  end

  def get_audio_file(actor = %Auth.User{}, id) do
    case Repo.get(AudioFile, id) do
      nil ->
        @not_found_match

      audio_file = %AudioFile{} ->
        if can_access_audio_file(actor, audio_file, :readonly) do
          {:ok, audio_file}
        else
          @not_authorized_match
        end
    end
  end

  def create_audio_file(actor = %Auth.User{}, audio = %Audio{}, attrs \\ %{}) do
    if can_access_audio(actor, audio, :manage) do
      Editor.Manager.create_audio_file(audio, attrs)
    else
      @not_authorized_match
    end
  end

  def update_audio_file(actor = %Auth.User{}, audio_file = %AudioFile{}, attrs) do
    if can_access_audio_file(actor, audio_file, :edit) do
      Editor.Editor.update_audio_file(audio_file, attrs)
    else
      @not_authorized_match
    end
  end

  def delete_audio_file(actor = %Auth.User{}, audio_file = %AudioFile{}) do
    if can_access_audio_file(actor, audio_file, :own) do
      Editor.Owner.delete_audio_file(audio_file)
    else
      @not_authorized_match
    end
  end

  defp can_access_audio_file(actor, audio_file, permission) do
    with audio = %Audio{} <- audio_file |> Ecto.assoc(:audio) |> Repo.one() do
      can_access_audio(actor, audio, permission)
    else
      _ -> false
    end
  end

  ## User Permission Management

  # TODO: list all collaborators of underlying entities as well.

  @spec list_collaborators(Auth.User.t(), Network.t() | Podcast.t()) ::
          {:ok, [Collaborator.t()]} | {:error, any}
  def list_collaborators(actor = %Auth.User{}, subject = %Network{}) do
    if has_permission(actor, subject, :manage) do
      network_perm_query =
        from p in Ecto.assoc(subject, :permissions),
          join: u in Auth.User,
          on: p.user_id == u.id,
          join: s in Network,
          on: s.id == p.subject_id,
          preload: [user: {u, [:person]}]

      network_perm_query
      |> Repo.all()
      |> Enum.map(fn
        perm = %Radiator.Perm.Permission{} ->
          %Collaborator{user: perm.user, permission: perm.permission, subject: subject}
      end)
      |> Enum.sort(&collaborator_sort/2)
      |> (&{:ok, &1}).()
    else
      @not_authorized_match
    end
  end

  def list_collaborators(actor = %Auth.User{}, subject = %Podcast{}) do
    if has_permission(actor, subject, :manage) do
      podcast_perm_query =
        from p in Ecto.assoc(subject, :permissions),
          join: u in Auth.User,
          on: p.user_id == u.id,
          join: s in Podcast,
          on: s.id == p.subject_id,
          preload: [user: {u, [:person]}]

      podcast_perm_query
      |> Repo.all()
      |> Enum.map(fn
        perm = %Radiator.Perm.Permission{} ->
          %Collaborator{user: perm.user, permission: perm.permission, subject: subject}
      end)
      |> Enum.sort(&collaborator_sort/2)
      |> (&{:ok, &1}).()
    else
      @not_authorized_match
    end
  end

  defp collaborator_sort(a = %Collaborator{}, b = %Collaborator{}) do
    case Radiator.Perm.Ecto.PermissionType.compare(a.permission, b.permission) do
      :gt -> true
      :eq -> a.user.name < b.user.name
      :lt -> false
    end
  end

  def get_collaborator(actor = %Auth.User{}, subject = %Network{}, username) do
    if has_permission(actor, subject, :manage) do
      network_perm_query =
        from p in Ecto.assoc(subject, :permissions),
          join: u in Auth.User,
          on: p.user_id == u.id,
          join: s in Network,
          on: s.id == p.subject_id,
          where: u.name == ^username,
          preload: [user: u]

      with [perm] <- Repo.all(network_perm_query) do
        %Collaborator{user: perm.user, permission: perm.permission, subject: subject}
        |> (&{:ok, &1}).()
      else
        _ ->
          @not_found_match
      end
    else
      @not_authorized_match
    end
  end

  def get_collaborator(actor = %Auth.User{}, subject = %Podcast{}, username) do
    if has_permission(actor, subject, :manage) do
      podcast_perm_query =
        from p in Ecto.assoc(subject, :permissions),
          join: u in Auth.User,
          on: p.user_id == u.id,
          join: s in Podcast,
          on: s.id == p.subject_id,
          where: u.name == ^username,
          preload: [user: u]

      with [perm] <- Repo.all(podcast_perm_query) do
        %Collaborator{user: perm.user, permission: perm.permission, subject: subject}
        |> (&{:ok, &1}).()
      else
        _ ->
          @not_found_match
      end
    else
      @not_authorized_match
    end
  end

  # TODO: Handle the accidental update case
  @spec add_collaborator(Auth.User.t(), Collaborator.t()) ::
          {:error, any} | {:ok, Collaborator.t()}
  def add_collaborator(
        actor = %Auth.User{},
        collaborator = %Collaborator{user: user, subject: subject, permission: permission}
      )
      when is_permission(permission) do
    if has_permission(actor, subject, :manage) do
      case Editor.Permission.set_permission(user, subject, permission) do
        :ok -> {:ok, collaborator}
        other -> other
      end
    else
      @not_authorized_match
    end
  end

  def update_collaborator(
        actor = %Auth.User{},
        collaborator = %Collaborator{user: user, subject: subject, permission: permission}
      ) do
    if has_permission(actor, subject, :manage) do
      case Editor.Permission.set_permission(user, subject, permission) do
        :ok -> {:ok, collaborator}
        other -> other
      end
    else
      @not_authorized_match
    end
  end

  def remove_collaborator(
        actor = %Auth.User{},
        collaborator = %Collaborator{user: user, subject: subject, permission: _permission}
      ) do
    if has_permission(actor, subject, :manage) do
      case Editor.Permission.remove_permission(user, subject) do
        :ok -> {:ok, collaborator}
        other -> other
      end
    else
      @not_authorized_match
    end
  end

  def list_people(actor = %Auth.User{}, subject = %Network{}) do
    if has_permission(actor, subject, :readonly) do
      people =
        Ecto.assoc(subject, :people)
        |> Repo.all()

      {:ok, people}
    else
      @not_authorized_match
    end
  end

  @spec create_person(Radiator.Auth.User.t(), Radiator.Directory.Network.t(), any) :: any
  def create_person(actor = %Auth.User{}, network = %Network{}, attrs) do
    if has_permission(actor, network, :edit) do
      Editor.Editor.create_person(network, attrs)
    else
      @not_authorized_match
    end
  end

  def get_person(actor = %Auth.User{}, id) do
    case Repo.get(Person, id) do
      nil ->
        @not_found_match

      person = %Person{} ->
        if has_permission(actor, %Network{id: person.network_id}, :readonly) do
          {:ok, person}
        else
          @not_authorized_match
        end
    end
  end

  def update_person(actor = %Auth.User{}, person = %Person{}, attrs) do
    if has_permission(actor, %Network{id: person.network_id}, :edit) do
      Editor.Editor.update_person(person, attrs)
    else
      @not_authorized_match
    end
  end

  def delete_person(actor = %Auth.User{}, person = %Person{}) do
    if has_permission(actor, %Network{id: person.network_id}, :manage) do
      Editor.Manager.delete_person(person)
    else
      @not_authorized_match
    end
  end

  def list_contribution_roles() do
    {:ok, Repo.all(Radiator.Contribution.Role)}
  end

  def list_contributions(actor, _subject = %Podcast{id: id}) do
    with {:ok, subject} <- get_podcast(actor, id) do
      {:ok, preloaded_contributions(Ecto.assoc(subject, :contributions))}
    end
  end

  def list_contributions(actor, _subject = %Audio{id: id}) do
    with {:ok, subject} <- get_audio(actor, id) do
      {:ok, preloaded_contributions(Ecto.assoc(subject, :contributions))}
    end
  end

  defp preloaded_contributions(query) do
    from(c in query,
      preload: [:person, :role]
    )
    |> Repo.all()
    |> Enum.sort(fn a, b ->
      cond do
        a.role_id == b.role_id ->
          a.position < b.position

        true ->
          a.role_id < b.role_id
      end
    end)
  end

  def create_contribution(actor, subject, attrs) do
    with :ok <- with_permission(actor, subject, :edit) do
      Editor.Editor.create_contribution(subject, attrs)
    end
  end

  def get_contribution(actor, id) do
    with {:ok, contribution, subject} <- get_contribution_and_subject(actor, id),
         :ok <- with_permission(actor, subject, :readonly) do
      {:ok, contribution}
    end
  end

  def delete_contribution(actor, id) do
    with {:ok, contribution, subject} <- get_contribution_and_subject(actor, id),
         :ok <- with_permission(actor, subject, :edit) do
      Repo.delete(contribution)
    end
  end

  defp get_contribution_and_subject(actor, id) do
    case Repo.get(AudioContribution, id) || Repo.get(PodcastContribution, id) do
      nil ->
        @not_found_match

      contribution ->
        with {:ok, subject} <- get_contribution_subject(actor, contribution) do
          {:ok, contribution, subject}
        end
    end
  end

  defp get_contribution_subject(actor, %AudioContribution{audio_id: id}), do: get_audio(actor, id)

  defp get_contribution_subject(actor, %PodcastContribution{podcast_id: id}),
    do: get_podcast(actor, id)

  def update_contribution(actor, id, attrs) do
    with {:ok, contribution, subject} <- get_contribution_and_subject(actor, id),
         :ok <- with_permission(actor, subject, :edit) do
      Editor.Editor.update_contribution(contribution, attrs)
    end
  end

  defp with_permission(actor, subject, permission) when is_permission(permission) do
    if has_permission(actor, subject, permission) do
      :ok
    else
      @not_authorized_match
    end
  end
end
