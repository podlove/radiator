defmodule RadiatorWeb.Public.EpisodeView do
  use RadiatorWeb, :view

  alias Radiator.Directory.{Podcast, Episode}

  def page_title(_template, %{current_podcast: podcast, current_episode: episode}) do
    [podcast.title, episode.title]
    |> Enum.join(" – ")
  end

  def page_title(_template, %{current_podcast: podcast}) do
    podcast.title
  end

  def podcast_public_url(podcast) do
    Podcast.public_url(podcast)
  end

  def episode_public_url(episode, podcast) do
    Episode.public_url(episode, podcast)
  end

  def podcast_image_url(podcast) do
    Podcast.image_url(podcast)
  end

  @spec episode_image_url(Radiator.Directory.Episode.t()) :: any
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
