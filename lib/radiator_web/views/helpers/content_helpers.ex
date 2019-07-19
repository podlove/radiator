defmodule RadiatorWeb.ContentHelpers do
  alias Radiator.Directory.{Network, Podcast, Episode}

  ## public image urls

  def network_image_url(podcast) do
    Network.image_url(podcast)
  end

  def podcast_image_url(podcast) do
    Podcast.image_url(podcast)
  end

  def episode_image_url(episode) do
    Episode.image_url(episode)
  end

  def episode_image_url(episode, podcast) do
    Episode.image_url(episode, podcast: podcast)
  end

  def chapter_image_url(chapter) do
    Radiator.AudioMeta.Chapter.image_url(chapter)
  end

  ## Public urls
  def podcast_public_url(podcast) do
    Podcast.public_url(podcast)
  end

  def episode_public_url(episode, podcast) do
    Episode.public_url(episode, podcast)
  end
end
