defmodule RadiatorWeb.Admin.PodcastView do
  use RadiatorWeb, :view

  import Radiator.Directory.Editor.Permission, only: [has_permission: 3]

  alias Radiator.Directory.{Episode, Podcast}

  def has_manage_permission_for_network(user, subject) do
    has_permission(user, subject, :manage)
  end

  def podcast_image_url(podcast) do
    Podcast.image_url(podcast)
  end

  def episode_image_url(episode) do
    Episode.image_url(episode)
  end
end
