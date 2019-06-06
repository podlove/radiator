defmodule RadiatorWeb.Admin.EpisodeView do
  use RadiatorWeb, :view

  alias Radiator.Directory.Episode

  def format_bytes(number, precision \\ 2)

  def format_bytes(nil, _) do
    "? Bytes"
  end

  def format_bytes(number, _precision) when number < 1_024 do
    "#{number} Bytes"
  end

  def format_bytes(number, precision) when number < 1_048_576 do
    "#{Float.round(number / 1024, precision)} kB"
  end

  def format_bytes(number, precision) do
    "#{Float.round(number / 1024 / 1024, precision)} MB"
  end

  def format_chapter_time(time) do
    time = round(time / 1_000) * 1_000

    time
    |> Chapters.Formatters.Normalplaytime.Formatter.format()
    |> case do
      "00:" <> rest -> rest
      sth -> sth
    end
    |> String.slice(0..-5)
  end

  def episode_image_url(episode) do
    Episode.image_url(episode)
  end

  def chapter_image_url(chapter) do
    Radiator.AudioMeta.Chapter.image_url(chapter)
  end
end
