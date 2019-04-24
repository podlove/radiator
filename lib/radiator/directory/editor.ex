defmodule Radiator.Directory.Editor do
  @moduledoc """
  The Editor context for querying and modifying data as an authorized user.
  """

  import Ecto.Query, warn: false

  alias Radiator.Auth

  alias Radiator.Repo
  alias Radiator.Directory.{Network, Podcast, Episode}

  alias Radiator.Directory.Editor
  alias Radiator.Directory.Editor.EditorHelpers

  alias Radiator.Perm.Ecto.PermissionType

  alias Radiator.Media

  @not_authorized {:error, :not_authorized}
  @not_found {:error, :not_found}

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
      %Network{}

      iex> get_network(unauthorized_me, 123)
      {:error, :not_authorized}

      iex> get_network(oblivious_me, 999_998)
      {:error, :not_found}

  """
  def get_network(actor = %Auth.User{}, id) do
    case Repo.get(Network, id) do
      nil ->
        @not_found

      network = %Network{} ->
        if has_permission(actor, network, :readonly) do
          network
        else
          @not_authorized
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
    case Editor.Owner.create_network(actor, attrs) do
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
  def update_network(actor = %Auth.User{}, network = %Network{}, attrs) do
    if has_permission(actor, network, :own) do
      Editor.Owner.update_network(network, attrs)
    else
      @not_authorized
    end
  end

  def create_podcast(actor = %Auth.User{}, network = %Network{}, attrs) do
    if has_permission(actor, network, :manage) do
      Editor.Manager.create_podcast(network, attrs)
    else
      @not_authorized
    end
  end

  # Permission

  def get_permission(user = %Auth.User{}, subject = %Network{}),
    do: do_get_permission(user, subject)

  def get_permission(user = %Auth.User{}, subject = %Podcast{}),
    do: do_get_permission(user, subject)

  def get_permission(user = %Auth.User{}, subject = %Episode{}),
    do: do_get_permission(user, subject)

  defp do_get_permission(user, subject) do
    case EditorHelpers.get_permission(user, subject) do
      nil -> nil
      perm -> perm.permission
    end
  end

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
    |> Ecto.assoc(:podcast)
    |> Repo.one!()
  end

  defp parent(_) do
    nil
  end

  @spec attach_audio_to_network(Network.t(), Media.Audio.t()) ::
          {:ok, Media.Attachment.t()} | {:error, Ecto.Changeset.t()}
  def attach_audio_to_network(network = %Network{}, audio = %Media.Audio{}) do
    network
    |> Ecto.build_assoc(:attachments, %{audio_id: audio.id})
    |> Media.Attachment.changeset(%{})
    |> Repo.insert_or_update()
  end

  @spec attach_audio_to_episode(Episode.t(), Media.Audio.t()) ::
          {:ok, Media.Attachment.t()} | {:error, Ecto.Changeset.t()}
  def attach_audio_to_episode(episode = %Episode{}, audio = %Media.Audio{}) do
    episode
    |> Ecto.build_assoc(:attachments, %{audio_id: audio.id})
    |> Media.Attachment.changeset(%{})
    |> Repo.insert_or_update()
  end

  @spec detach_all_audios_from_episode(Episode.t()) :: Episode.t()
  def detach_all_audios_from_episode(episode = %Episode{}) do
    Ecto.assoc(episode, :attachments) |> Repo.delete_all()
    episode
  end
end
