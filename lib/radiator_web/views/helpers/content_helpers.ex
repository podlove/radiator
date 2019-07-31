defmodule RadiatorWeb.ContentHelpers do
  alias Radiator.Contribution.Person

  alias Radiator.Directory.{
    Network,
    Podcast,
    Episode,
    Audio
  }

  ## public image urls

  def person_image_url(person = %Person{}) do
    Person.image_url(person)
  end

  def network_image_url(subject = %Network{}) do
    Network.image_url(subject)
  end

  def podcast_image_url(podcast = %Podcast{}) do
    Podcast.image_url(podcast)
  end

  def episode_image_url(episode = %Episode{}) do
    Episode.image_url(episode)
  end

  def episode_image_url(episode, podcast) do
    Episode.image_url(episode, podcast: podcast)
  end

  def audio_image_url(audio = %Audio{}) do
    Audio.image_url(audio)
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
