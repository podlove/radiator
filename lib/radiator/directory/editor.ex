defmodule Radiator.Directory.Editor do
  @moduledoc """
  The Editor context for modifying data.
  """

  import Ecto.Query, warn: false

  alias Radiator.Auth

  alias Radiator.Repo
  alias Radiator.Directory
  alias Directory.{Network, NetworkPermission}
  alias Directory.{Podcast, PodcastPermission}
  alias Directory.{Episode, EpisodePermission}

  def get_permission(user, entity)

  def get_permission(user = %Auth.User{}, episode = %Episode{}) do
    case Repo.get_by(EpisodePermission, user_id: user.id, episode_id: episode.id) do
      nil -> nil
      perm -> perm.permission
    end
  end

  def get_permission(user = %Auth.User{}, subject = %Podcast{}) do
    case Repo.get_by(PodcastPermission, user_id: user.id, podcast_id: subject.id) do
      nil -> nil
      perm -> perm.permission
    end
  end

  def get_permission(user = %Auth.User{}, subject = %Network{}) do
    case Repo.get_by(NetworkPermission, user_id: user.id, network_id: subject.id) do
      nil -> nil
      perm -> perm.permission
    end
  end
end
