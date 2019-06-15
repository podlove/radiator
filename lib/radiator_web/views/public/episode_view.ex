defmodule RadiatorWeb.Public.EpisodeView do
  use RadiatorWeb, :view

  alias Radiator.Directory.{Podcast, Episode}

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

  def format_date(datetime) do
    Timex.Format.DateTime.Formatters.Relative.format(datetime, "{relative}")
    |> case do
      {:ok, result} -> result
    end
  end
end
