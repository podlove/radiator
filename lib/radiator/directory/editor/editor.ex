defmodule Radiator.Directory.Editor do
  @moduledoc """
  The Editor context for modifying data.
  """

  import Ecto.Query, warn: false

  alias Radiator.Repo
  alias Radiator.Directory.{Podcast, PodcastPermission}
  alias Radiator.Directory.{Episode, EpisodePermission}
  alias Radiator.Auth

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
end
